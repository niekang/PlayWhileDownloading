//
//  VideoDownloader.swift.swift
//  PlayWhileDownloading
//
//  Created by niekang on 2022/3/17.
//  Copyright © 2022 com.nk. All rights reserved.
//

import Foundation

private let directoryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, .userDomainMask, true).last! + "/PlayWhileDownloading"
private let videoDirectoryPath = directoryPath + "/Video"
private let tmpDirectoryPath = directoryPath + "/tmp"

protocol VideoDownloaderDelegate: NSObjectProtocol {
    func downloader(downloader: VideoDownloader, didUpdateProress progress: Float)
    func downloader(downloader: VideoDownloader, didCompleteWithError error: Error?)
}

class VideoDownloader: NSObject {
    
    weak var delegate: VideoDownloaderDelegate?
    
    private(set) var url: URL
        
    private(set) var cacheLength: UInt64 = 0

    private(set) var totalLength: UInt64 = 0
    
    private(set) var readFileHander: FileHandle?

    private(set) var writeFileHander: FileHandle?
    
    private lazy var filePath = videoDirectoryPath + "/" + url.lastPathComponent
    
    private lazy var tempFilePath = tmpDirectoryPath + "/" + url.lastPathComponent
    
    private lazy var session: URLSession = {
        let sessionConfig = URLSessionConfiguration.default
        return URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    private var task: URLSessionTask?

    init(url: URL) {
        self.url = url
        super.init()
        if !FileManager.default.fileExists(atPath: videoDirectoryPath) {
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: videoDirectoryPath), withIntermediateDirectories: true, attributes: nil)
        }
        if !FileManager.default.fileExists(atPath: tmpDirectoryPath) {
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: tmpDirectoryPath), withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func startDownload() {
        if FileManager.default.fileExists(atPath: filePath) {
            if let attr = try? FileManager.default.attributesOfItem(atPath: filePath) {
                cacheLength = attr[FileAttributeKey.size] as? UInt64 ?? 0
                totalLength = cacheLength
                readFileHander = FileHandle(forReadingAtPath: filePath)
                delegate?.downloader(downloader: self, didUpdateProress: 1)
                delegate?.downloader(downloader: self, didCompleteWithError: nil)
            }
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        if writeFileHander == nil {
            if !FileManager.default.fileExists(atPath: tempFilePath) {
                let isCreate = FileManager.default.createFile(atPath: tempFilePath, contents: Data(), attributes: nil)
                if !isCreate {
                    assertionFailure("【PlayWhileDownloading】temp video file create failure")
                    return
                }
            }
            writeFileHander = FileHandle(forWritingAtPath: tempFilePath)
            if #available(iOS 13.4, *) {
                if let offset = try? writeFileHander?.seekToEnd() {
                    cacheLength = offset
                }else {
                    assertionFailure("【PlayWhileDownloading】seek to end fail")
                }
            }else {
                cacheLength = writeFileHander?.seekToEndOfFile() ?? 0
            }
            
            request.addValue("bytes=\(cacheLength)-", forHTTPHeaderField: "Range")
        }
        
        if readFileHander == nil {
            readFileHander = FileHandle(forWritingAtPath: tempFilePath)
        }
        
        task = session.dataTask(with: request)
        task?.resume()
    }
    
    private func closeFileHander(_ fileHander: inout FileHandle?) {
        if fileHander != nil {
            if #available(iOS 13, *) {
                try? fileHander?.close()
            }else {
                fileHander?.closeFile()
            }
            fileHander = nil
        }
    }
}

extension VideoDownloader: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let mimeType = response.mimeType
        if mimeType == "video/mp4" {
            completionHandler(.allow)
        }else {
            completionHandler(.cancel)
        }
        
        if let response = dataTask.response {
            totalLength = UInt64(response.expectedContentLength) + cacheLength
        }
        
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print(dataTask)
        var fileSize: UInt64 = 0
        if #available(iOS 13.4, *) {
            if let offSet = try? writeFileHander?.seekToEnd() {
                fileSize = offSet
                try? writeFileHander?.write(contentsOf: data)
            }
        }else {
            fileSize = writeFileHander?.seekToEndOfFile() ?? 0
            writeFileHander?.write(data)
        }
        cacheLength = fileSize + UInt64(data.count)
        delegate?.downloader(downloader: self, didUpdateProress: Float(cacheLength)/Float(totalLength))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        closeFileHander(&writeFileHander)
        if error == nil {
            try? FileManager.default.moveItem(atPath: tempFilePath, toPath: filePath)
            closeFileHander(&readFileHander)
            readFileHander = FileHandle(forReadingAtPath: filePath)
        }
    }
}

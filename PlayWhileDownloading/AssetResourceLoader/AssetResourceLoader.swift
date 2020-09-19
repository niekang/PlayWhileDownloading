//
//  AssetResourceDownloader.swift
//  PlayWhileDownloading
//
//  Created by 聂康 on 2020/9/14.
//  Copyright © 2020 com.nk. All rights reserved.
//

import Foundation
import AVFoundation



class AssetResourceLoader: NSObject  {
    
    private var requests = [AVAssetResourceLoadingRequest]()
    
    private var videoPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, .userDomainMask, true).last! + "/tmp.mp4"
    private var task: URLSessionDownloadTask?
    
    private lazy var session: URLSession = {
       let config = URLSessionConfiguration.default
       config.isDiscretionary = true
       return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    
    private var resumeData: Data?
}

extension AssetResourceLoader: AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        requests.append(loadingRequest)
        if task == nil {
            guard let url = loadingRequest.request.url,
                       var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                       return false
                   }
            components.scheme = "http"
            task = session.downloadTask(with: components.url!)
            task?.resume()
            return true
        }else if let resumeData = resumeData{
            task = session.downloadTask(withResumeData: resumeData)
            task?.resume()
            return true
        }
        return false
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {
        print(authenticationChallenge)

    }
    
}

extension AssetResourceLoader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print(bytesWritten)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(error)

    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    }
    
    
}

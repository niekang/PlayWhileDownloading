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
        
    private(set) var url: URL
    
    private(set) var asset: AVURLAsset?
    
    private var loadingRequests = [AVAssetResourceLoadingRequest]()

    private var downloader: VideoDownloader?
    
    init(url: URL) {
        self.url = url
        super.init()
        self.resetLoader()
    }
    
    private func resetLoader() {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "customscheme"
        guard let fakeURL = components?.url else {
            return
        }
        self.asset = AVURLAsset(url: fakeURL)
        self.asset?.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
    }
    
    func checkLoadingRequestsState() {
        loadingRequests.removeAll {configLoadingRequest(loadingRequest: $0)}
    }
    
    func configLoadingRequest(loadingRequest: AVAssetResourceLoadingRequest) -> Bool{
        guard let downloader = downloader,
              let dataRequest = loadingRequest.dataRequest else {
            return false
        }
        if let contentRequest = loadingRequest.contentInformationRequest {
            contentRequest.contentType = "video/mp4"
            contentRequest.isByteRangeAccessSupported = true
            contentRequest.contentLength = Int64(downloader.totalLength)
        }
    
//        print(dataRequest)
        var requestOffset = dataRequest.requestedOffset
        if dataRequest.currentOffset > 0 {
            requestOffset = dataRequest.currentOffset
        }
        if #available(iOS 13, *) {
            try? downloader.readFileHander?.seek(toOffset: UInt64(requestOffset))
        }else {
            downloader.readFileHander?.seek(toFileOffset: UInt64(requestOffset))
        }
        if downloader.cacheLength > dataRequest.currentOffset {
            let length = Int(dataRequest.requestedLength) - Int(dataRequest.requestedOffset)
            var data: Data?
            if #available(iOS 13.4, *) {
                data = try? downloader.readFileHander?.read(upToCount: length)
            }else {
                data = downloader.readFileHander?.readData(ofLength: length)
            }
            if let data = data {
                dataRequest.respond(with: data)
                loadingRequest.finishLoading()
            }
        }
        return loadingRequest.isFinished
    }
}

extension AssetResourceLoader: AVAssetResourceLoaderDelegate {
    /*
     1、可边下边播的前提是，视频文件的moov(container for all the metadata)需要在最前面，后面跟随mdat(media data container)
     2、如果moov在最后，则需要整个文件下载完成才可以播放，此时超时时间大约18s
     */
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        print("shouldWaitForLoadingOfRequestedResource")
        loadingRequests.append(loadingRequest)
        if self.downloader == nil {
            downloader = VideoDownloader(url: url)
            downloader?.delegate = self
            downloader?.startDownload()
        }else {
            checkLoadingRequestsState()
        }
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequests.removeAll {$0 == loadingRequest}
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel authenticationChallenge: URLAuthenticationChallenge) {

    }
}

extension AssetResourceLoader: VideoDownloaderDelegate {
    
    func downloader(downloader: VideoDownloader, didUpdateProress progress: Float) {
        checkLoadingRequestsState()
    }
    
    func downloader(downloader: VideoDownloader, didCompleteWithError error: Error?) {
        
    }
}

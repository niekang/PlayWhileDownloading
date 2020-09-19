//
//  ViewController.swift
//  PlayWhileDownloading
//
//  Created by 聂康 on 2020/9/14.
//  Copyright © 2020 com.nk. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var asset: AVURLAsset?
    var player: AVPlayer?
    var delegate = AssetResourceLoader()

    override func viewDidLoad() {
        super.viewDidLoad()
        

        guard let url = URL(string: "http://v4ttyey-10001453.video.myqcloud.com/Microblog/288-4-1452304375video1466172731.mp4"),
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else {
            return
        }
        components.scheme = "streaming"
        asset = AVURLAsset(url: components.url!)
        asset?.resourceLoader.setDelegate(delegate, queue: DispatchQueue.global())
        
        let item = AVPlayerItem(asset: asset!)
        player = AVPlayer(playerItem: item)
    }


}


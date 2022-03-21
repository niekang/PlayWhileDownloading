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
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    var delegate: AssetResourceLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        

//        guard let url = URL(string: "http://v4ttyey-10001453.video.myqcloud.com/Microblog/288-4-1452304375video1466172731.mp4"),
        if let url = URL(string: "http://biz-site.zone1.meitudata.com/1031b8c00585fb410961e27e9c7a445b-4836.mp4") {
            self.delegate = AssetResourceLoader(url: url)
        }
        if let asset =  delegate?.asset {
            let item = AVPlayerItem(asset: asset)
            player = AVPlayer(playerItem: item)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.backgroundColor = UIColor.black.cgColor
            playerLayer?.frame = view.bounds
            playerLayer?.videoGravity = .resizeAspect
            view.layer.insertSublayer(playerLayer!, at: 0)
            player?.play()
        }
    }
}


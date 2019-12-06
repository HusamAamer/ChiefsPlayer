//
//  ACVideoPlayer.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 3/24/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

protocol CVideoProgressViewDelegate:class {
    func progressChanged(to percent:CGFloat)
    func progressChangingIsAllowed () -> Bool
}
class CVideoProgressView: UIView {
    var progressBar : CVideoProgressBarView!
    
    var duration    : CMTime?
    weak var delegate    : CVideoProgressViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        progressBar = CVideoProgressBarView()
        addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        progressBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        progressBar.lastBaselineAnchor.constraint(equalTo: lastBaselineAnchor, constant: 0).isActive = true
        progressBar.heightAnchor.constraint(equalToConstant: 3).isActive = true
        
        addGesture()
    }
    func updateSlider(elapsedTime: CMTime) {
        if isChangingCurrentTime == true {
            return
        }
        guard let item = ChiefsPlayer.shared.player.currentItem else {return}
        
        var playerDuration : TimeInterval!
        if let duration = AVCGlobalFuncs.playerItemDuration() {
            playerDuration = duration
            
        } else {
            //If duration is unknown then set current time as duration
            playerDuration = CMTimeGetSeconds(ChiefsPlayer.shared.player.currentTime())
            
        }
        let duration = CGFloat(playerDuration)
        if duration.isFinite && duration > 0 {
            let time = CGFloat(CMTimeGetSeconds(elapsedTime))
            progressBar.progress = time / duration
            
            let bufferTime = CGFloat(item.currentBuffer())
            progressBar.buffer = (bufferTime / duration) *  frame.width
        }
    }
    
    //Change progress
    func addGesture () {
        let drag = UIPanGestureRecognizer(
            target: self,
            action: #selector(dragVideo(pan:)))
        addGestureRecognizer(drag)
    }
    var isChangingCurrentTime = false
    @objc func dragVideo (pan:UIPanGestureRecognizer) {
        guard let delegate = delegate else {return}
        
        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft
        let xFinger = abs(pan.location(in: self).x - (isRTL ? frame.width : 0))
        let percent = xFinger / frame.width
        
        if pan.state == UIGestureRecognizer.State.began {
            if !delegate.progressChangingIsAllowed() {
                //Cancel gesture if playing error
                pan.isEnabled = false
                pan.isEnabled = true
                return
            }
            isChangingCurrentTime = true
        }
        
        if pan.state == UIGestureRecognizer.State.ended {
            delegate.progressChanged(to: percent)
            isChangingCurrentTime = false
        }
        
        if pan.state == UIGestureRecognizer.State.changed {
            
            progressBar.progress = percent
            progressBar.buffer = 0
        } else {
            // or something when its not moving
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        print("ProgressView deinit")
    }
}

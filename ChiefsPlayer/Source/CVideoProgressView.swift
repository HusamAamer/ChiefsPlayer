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
    var panLabel : UILabel?
    
    init() {
        super.init(frame: .zero)
        
        self.progressBar = CVideoProgressBarView()
        self.addSubview(self.progressBar)
        self.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.progressBar.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.progressBar.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.progressBar.lastBaselineAnchor.constraint(equalTo: self.lastBaselineAnchor, constant: 0).isActive = true
        
        addGesture()
    }
    func updateSlider(elapsedTime: CMTime) {
        if isChangingCurrentTime == true {
            return
        }
        
        guard let item = ChiefsPlayer.shared.player?.currentItem else {return}
        
        if let duration = playerDuration {
            let time = CGFloat(CMTimeGetSeconds(elapsedTime))
            let newPercent = time / duration
            
            if userJustPannedView {
                /**
                  Don't update UI, This is an old value and I'm waiting for player to seek for the new value
                    Neglect first value after pan
                 */
                userJustPannedView = false
                return
            }
            
            //Update UI
            progressBar?.progress = newPercent
            
            let bufferTime = CGFloat(item.currentBuffer())
            progressBar?.buffer = (bufferTime / duration) *  frame.width
            
            //print("Progress Update => \(time / duration)%             \(elapsedTime.value)")
        }
    }
    
    
    /// Current item duration
    var playerDuration : CGFloat? {
        var playerDuration : TimeInterval!
        if let duration = AVCGlobalFuncs.playerItemDuration() {
            playerDuration = duration
            
        } else {
            //If duration is unknown then set current time as duration
            playerDuration = CMTimeGetSeconds(ChiefsPlayer.shared.player.currentTime())
            
        }
        let duration = CGFloat(playerDuration)
        if duration.isFinite && duration > 0 {
            return duration
        }
        return nil
    }
    
    //Change progress
    func addGesture () {
        let drag = UIPanGestureRecognizer(
            target: self,
            action: #selector(dragVideo(pan:)))
        addGestureRecognizer(drag)
    }
    var isChangingCurrentTime = false {
        didSet {
            if isChangingCurrentTime, panLabel == nil {
                addPanLabel()
            } else {
                removePanLabel()
            }
        }
    }
    var userJustPannedView = false
    
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
            progressBar.userIsPanning = true
        }
        
        if pan.state == UIGestureRecognizer.State.ended {
            delegate.progressChanged(to: percent)
            
            userJustPannedView = true
            isChangingCurrentTime = false
            progressBar.userIsPanning = false
        }
        
        if pan.state == UIGestureRecognizer.State.changed {
            progressBar.progress = percent
            updatePanLabel(with: percent)
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

extension CVideoProgressView {
    func addPanLabel () {
        if ChiefsPlayer.shared.configs.progressBarStyle.showsLivePanDuration {
            panLabel = UILabel(frame: CGRect(x: 0, y: -40, width: bounds.width, height: 50))
            panLabel?.layer.shadowColor = UIColor.black.cgColor
            panLabel?.layer.shadowOffset = CGSize(width: 0, height: 1)
            panLabel?.layer.shadowOpacity = 0.8
            panLabel?.layer.shadowRadius = 0
            panLabel?.textAlignment = .center
            panLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            panLabel?.textColor = .white
            addSubview(panLabel!)
        }
    }
    func removePanLabel() {
        panLabel?.removeFromSuperview()
        panLabel = nil
    }
    func updatePanLabel (with percentage:CGFloat) {
        guard let panLabel = panLabel else {
            return
        }
        if let duration = playerDuration {
            panLabel.text = AVCGlobalFuncs.timeFrom(seconds: TimeInterval(percentage * duration))
        }
        panLabel.sizeToFit()
        
        /*
         Set label always inside screen above progress orb
         with 10 left and right padding
         */
        let halfWidth = panLabel.frame.width/2
        let orbX = progressBar.orb.frame.midX
        var newLabelCenterX = orbX
        let screenWidth = bounds.width
        if newLabelCenterX - halfWidth < 10 {
            newLabelCenterX = 10 + halfWidth
        } else if newLabelCenterX + halfWidth > (screenWidth - 10) {
            newLabelCenterX = screenWidth - 10 - halfWidth
        }
        
        panLabel.center = CGPoint(x:  newLabelCenterX , y: panLabel.center.y)
    }
}

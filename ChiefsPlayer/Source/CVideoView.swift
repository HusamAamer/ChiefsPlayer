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

public class CVideoView: UIView {
    var videoURL : URL!
    
    //UI
    var progressView : CVideoProgressView!
    var loadingView  : CLoadingView!

    var vLayer : AVPlayerLayer!
    @objc var player : AVQueuePlayer {return ChiefsPlayer.shared.player}
    private var timeObserver: Any?
    
    
    init() {
        super.init(frame: .zero)
        
        vLayer = AVPlayerLayer(player: player)
        layer.addSublayer(vLayer)
        vLayer.backgroundColor = UIColor.black.cgColor
        
        
        loadingView = CLoadingView(frame: .zero)
        addSubview(loadingView)
        loadingView.sizeAchor(equalsTo: self)
        
        progressView = CVideoProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressView)
        progressView.delegate = self
        
        
        bar_bottom = progressView.lastBaselineAnchor.constraint(equalTo: lastBaselineAnchor, constant: 0)
        //bar_bottom.priority = .defaultLow //To give the high priority for on video controls (in landscape)
        bar_bottom.isActive = true
        
        bar_leading = progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        bar_leading.isActive = true
        
        bar_trailing = progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        bar_trailing.isActive = true
        
        progressView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        startObservation()
    }
    var bar_trailing : NSLayoutConstraint!
    var bar_leading : NSLayoutConstraint!
    var bar_bottom : NSLayoutConstraint!
    
    func setupProgressViewLayout () {
//        progressView.constraints.forEach({progressView.removeConstraint($0)})
        if isFullscreen {
            let safe = screenSafeInsets
            print(safe)
            bar_trailing.constant = -20 - safe.right
            bar_leading.constant = 20 + safe.left
            
            if ChiefsPlayer.shared.configs.controlsStyle == .youtube {
                bar_bottom.constant = -30 - safe.bottom
            } else {
                bar_bottom.constant = -116 - safe.bottom
            }
        } else {
            bar_trailing.constant = 0
            bar_leading.constant = 0
            bar_bottom.constant = 0
        }
        layoutIfNeeded()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didMoveToSuperview() {
        if let _ = superview {
            player.play()
        }
    }
    override public func layoutSubviews() {
        super.layoutSubviews()
        switch ChiefsPlayer.shared.acvStyle {
        case .moving(_):
            CATransaction.begin()
            CATransaction.setAnimationDuration(0)
            vLayer.frame = bounds
            CATransaction.commit()
        default:
            //Make animation with same view duration and timing
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.15)
            CATransaction
                .setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
            vLayer.frame = bounds
            CATransaction.commit()
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    var paths: [String] {
        return [
                "playbackLikelyToKeepUp",
                "playbackBufferEmpty",
                "playbackBufferFull",
        #keyPath(player.status),
        #keyPath(player.currentItem.status),
        #keyPath(player.currentItem.error)
        ]
    }
    func startObservation() {
        ChiefsPlayer.Log(event: "\(#file) -> \(#function)")
        //Observe values
        if let item = player.items().first {
            paths.forEach({
                item.addObserver(self,
                                 forKeyPath: $0,
                                 options: [.initial,.new],
                                 context: nil)
            })
        }
        // observe AVPlayerItemDidPlayToEndTime
        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(playerItemDidPlayToEndTime(_:)),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: player.currentItem)

        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(playerError),
                name: NSNotification.Name.AVPlayerItemNewErrorLogEntry,
                object: nil)

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] elapsedTime in
            guard let `self` = self else {return}
            self.progressView.updateSlider(elapsedTime: elapsedTime)
            
            if let item = self.player.currentItem,
                !ChiefsPlayer.shared.isPlayerError,
                self.chiefsplayerWillStartTriggered
            {
                guard
                    let second = item.currentTime().asFloat,
                    let duration = item.duration.asFloat else {
                        return
                }
                ChiefsPlayer.shared.delegate?
                    .chiefsplayer(isPlaying: item,
                                  at: second, of: duration)
            }
        })
    }
    func endPlayerObserving () {
        ChiefsPlayer.Log(event: "\(#file) -> \(#function)")
        if let timeObserver = timeObserver {
            NotificationCenter.default.removeObserver(self)
            
            //print(player.items().first?.observationInfo as? [NSKeyValueObservation])
            if let item = player.items().first {
                for path in paths {
                    item.removeObserver(self, forKeyPath: path)
                }
                
            }
            //print(player.items().first?.observationInfo as? [NSKeyValueObservation])
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
            chiefsplayerWillStartTriggered = false
        }
    }
    func updateLoadingUI (with error:String)
    {
        
        loadingView.state = .Error(msg: error)
        
        //Show error alert for debug
        //let a = alert(title: "Error", body: errorMsg, cancel: "OK")
        //ChiefsPlayer.shared.parentVC.present(a, animated: true, completion: nil)
    }
    
    /// Called if error happened or player ended
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        ChiefsPlayer.Log(event: "\(#file) -> \(#function)")
        
        //Player has error
        if let userInfo = notification.userInfo,
            let error = userInfo["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? NSError
        {
            updateLoadingUI(with: error.localizedDescription)
        } else {
            updateLoadingUI(with: "")
        }
    }
    @objc func playerError (error:NSError) {
        ChiefsPlayer.Log(event: "\(#file) -> \(#function)")
        if let error = player.currentItem!.error {
            updateLoadingUI(with: error.localizedDescription + "\nSource: 3")
        }
    }
    
    /// Delegate should declare `chiefsplayerWillStart` before `chiefsplayer(isPlaying item:, at second:, of totalSeconds:)`
    var chiefsplayerWillStartTriggered: Bool = false
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?) {
        
        guard let item = player.currentItem else {return}
        
        if keyPath == #keyPath(player.currentItem.error) {
            ChiefsPlayer.Log(event: "\(#file) -> \(#function) -> Line \(#line) (PlayerError)")
            if let error = item.error {
                updateLoadingUI(with: error.localizedDescription + "\nSource: 3")
                endPlayerObserving()
            }
        } else
        if keyPath == #keyPath(player.currentItem.status) {
            ChiefsPlayer.Log(event: "\(#file) -> \(#function) PlayerStatus = \(item.status)")
            
            // FAILED
            if item.status == .failed {
                if let error = item.error {
                    updateLoadingUI(with: error.localizedDescription + "\nSource: 3")
                }
            }
            
            // READY TO PLAY
            else if item.status == .readyToPlay {
                ChiefsPlayer.shared.updateViewsAccordingTo(videoRect: vLayer.videoRect)
                if !chiefsplayerWillStartTriggered {
                    ChiefsPlayer.shared.delegate?.chiefsplayerWillStart(playing: ChiefsPlayer.shared.player.currentItem!)
                    chiefsplayerWillStartTriggered = true
                }
            }
        } else
        if keyPath == #keyPath(player.status) {
            
            if player.status == .failed {
                if let error = player.error {
                    ChiefsPlayer.Log(event: "\(#file) -> \(#function) -> Line \(#line) (failed)")
                    updateLoadingUI(with:error.localizedDescription + "\nSource: 3")
                }
            }
        }
        
        if keyPath == "playbackBufferEmpty" {
            
            if item.isPlaybackBufferEmpty {
                // Show loading progress
                loadingView.state = .isLoading
                ChiefsPlayer.Log(event: "\(#file) -> \(#function) -> Line \(#line) (playbackBufferEmpty)")
                //print("isPlaybackBufferEmpty")
            }
        }
        else if keyPath == "playbackBufferFull" {
            
            if item.isPlaybackBufferFull {
                // Hide loading progress
                loadingView.state = .isPlaying
                ChiefsPlayer.Log(event: "\(#file) -> \(#function) -> Line \(#line) (playbackBufferFull)")
                //print("player item playback buffer is full")
            }
        }
        else if keyPath == "playbackLikelyToKeepUp" {
            
            if item.isPlaybackLikelyToKeepUp {
                //print("isPlaybackLikelyToKeepUp")
                ChiefsPlayer.Log(event: "\(#file) -> \(#function) -> Line \(#line) (playbackLikelyToKeepUp)")
                loadingView.state = .isPlaying
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    deinit {
        print("CVideoView deinit")
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //xxxxxxxxxxxxxxxxxxxxxxxxxx FULLSCREEN Controls  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    var onVideoControls:CBaseControlsView!
    var isFullscreen : Bool = false {
        didSet {
            setupProgressViewLayout()
            progressView.alpha = self.controlsAreHidden && isFullscreen ? 0 : 1
        }
    }
    private var controlsHeight : CGFloat {
        var value = CGFloat(60)
        if #available(iOS 11.0, *) {
            value += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        return value
    }
    func addOnVideoControls () {
        if onVideoControls != nil {return}
        
        if ChiefsPlayer.shared.configs.controlsStyle == .youtube {
            onVideoControls = ChiefsPlayer.shared.controls
        } else {
            onVideoControls = ChiefsPlayer.shared.controlsForCurrentStyle()
        }
        
        guard let onVideoControls = onVideoControls else {
            return
        }
        insertSubview(onVideoControls, belowSubview: progressView)
        
        onVideoControls.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let tap = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        addGestureRecognizer(tap)
        
        
        if controlsAreHidden {
            onVideoControls.alpha = 0
            if isFullscreen {
                progressView.alpha = 0
            }
        }
        
        // Trigger delegates to tell onVideoControls that we have subtitles or not
        CControlsManager.shared.reloadVidoInfo()
    }
    func removeOnVideoControls () {
        if let onVideoControls = onVideoControls {
            onVideoControls.removeFromSuperview()
            self.onVideoControls = nil
        }
    }
    @objc func screenTapped () {
        if onVideoControls != nil {
            if frame.width == screenWidth { //if not minimized
                controlsAreHidden = !controlsAreHidden
            }
        }
    }
    private var controlsAreHidden:Bool = true {
        didSet {
            
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut,.allowAnimatedContent,.allowUserInteraction,.beginFromCurrentState], animations: { [weak self] in
                
                guard let `self` = self else {return}
                
                self.onVideoControls?.alpha = self.controlsAreHidden ? 0 : 1
                if self.isFullscreen {
                    self.progressView.alpha = self.controlsAreHidden ? 0 : 1
                }
                
            }) { (_) in
                
            }
        }
    }
    /// Hide error view when player is getting minimized
    ///
    /// - Parameter percent: y translation percent to the last state
    func setMinimize (with percent:CGFloat)
    {
        let newAlpha = 1 - (percent * 5)// Set alpha 0 at 5th of reached move
        if !controlsAreHidden {
            onVideoControls?.alpha = newAlpha
        }
        progressView.alpha = newAlpha
    }
}

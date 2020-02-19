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
    var streamingView:CStreamingView?
    
    var vLayer : AVPlayerLayer?
    @objc var player : CAVQueuePlayer {return ChiefsPlayer.shared.player}
    private var timeObserver: Any?
    
    
    init() {
        super.init(frame: .zero)
        
        self.vLayer = AVPlayerLayer(player: self.player)
        self.vLayer?.videoGravity = .resizeAspect
        self.vLayer?.backgroundColor = UIColor.black.cgColor
        self.layer.insertSublayer(self.vLayer!, at: 0)
        
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
        
        bar_left = progressView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0)
        bar_left.isActive = true
        
        bar_width = progressView.widthAnchor.constraint(equalToConstant: screenWidth)
        bar_width.isActive = true
        
        progressView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        startObservation()
    }
    var bar_width : NSLayoutConstraint!
    var bar_left : NSLayoutConstraint!
    var bar_bottom : NSLayoutConstraint!
    
    func setupProgressViewLayout () {
//        progressView.constraints.forEach({progressView.removeConstraint($0)})
        if isFullscreen {
            let safe = screenSafeInsets
            print(safe)
            bar_width.constant = [screenWidth,screenHeight].max()! - 40 - safe.right
            bar_left.constant = 20 + safe.left
            
            if ChiefsPlayer.shared.configs.controlsStyle == .youtube {
                bar_bottom.constant = -30 - safe.bottom
            } else {
                bar_bottom.constant = -114 - safe.bottom
            }
        } else {
            bar_width.constant = screenWidth
            bar_left.constant = 0
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
            vLayer?.frame = bounds
            CATransaction.commit()
        default:
            //Make animation with same view duration and timing
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.15)
            CATransaction
                .setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
            vLayer?.frame = bounds
            CATransaction.commit()
        }
    }
    
    
    
    
    
    
    //MARK: Streaming View  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    public func addStreamingView(with text:String) {
        if streamingView != nil {return}
        streamingView = CStreamingView(with: bounds, and: text)
        insertSubview(streamingView!, at: 1)
        
        streamingView?.translatesAutoresizingMaskIntoConstraints = false
        streamingView?.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        streamingView?.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        streamingView?.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        streamingView?.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
    }
    public func removeStreamingViewIfExist (){
        if streamingView != nil {
            streamingView?.removeFromSuperview()
            streamingView = nil
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /// Delegate should declare `chiefsplayerWillStart` before `chiefsplayer(isPlaying item:, at second:, of totalSeconds:)`
    var chiefsplayerWillStartTriggered: Bool = false
    
    /**
     #THIS WOULD BE CALLED EVEN IF PLAYER ITEM HAS NOT BEEN LOADED YET
     */
    func startObservation() {
        ChiefsPlayer.Log(event: "\(NSStringFromClass(type(of: self))) -> \(#function)")
        
        player.delegate = self
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] elapsedTime in
            guard let `self` = self else {return}
            self.progressView.updateSlider(elapsedTime: elapsedTime)
            
            if let item = self.player.currentItem as? CPlayerItem,
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
        ChiefsPlayer.Log(event: "CVideoView \(#function)")
        if let timeObserver = timeObserver {
            player.delegate = nil
            progressView.progressBar.progress = 0
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
    
    deinit {
        print("CVideoView deinit")
        if timeObserver != nil {
            endPlayerObserving()
        }
    }
    
    
    
    
    
    
    
    
    
    //MARK: FULLSCREEN Controls  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
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

//MARK: Player Delegate xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
extension CVideoView: CAVQueuePlayerDelegate {
    public func cavqueueplayerItemReplaced(with item: AVPlayerItem?) {
        if let item = player.currentItem as? CPlayerItem {
            item.delegate = self
        }
    }
    
    public func cavqueueplayerReadyToPlay() {
        //If player is not ready to play yet but casting started, we should pause it here
        if let chromecastManager = ChiefsPlayer.shared.chromecastManager, chromecastManager.sessionIsActive {
            if ChiefsPlayer.shared.isCastingTo != .chromecast {
                print("HERE IS THE ISSUE")
            }
            ChiefsPlayer.shared.player.pause()
        }
        
        if let vlayer = vLayer {
            ChiefsPlayer.shared.updateViewsAccordingTo(videoRect: vlayer.videoRect)
        }
        if !chiefsplayerWillStartTriggered {
            ChiefsPlayer.shared.delegate?.chiefsplayerWillStart(playing: ChiefsPlayer.shared.player.currentItem  as! CPlayerItem)
            chiefsplayerWillStartTriggered = true
        }
        loadingView.state = .isPlaying
    }
    
    public func cavqueueplayerFailed() {
        if let error = player.currentItem?.error {
            updateLoadingUI(with: error.localizedDescription)
        }
    }
}

//MARK: Item Delegate xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
extension CVideoView: CPlayerItemDelegate {
    
    public func cplayerItemPlaybackLikelyToKeepUp() {
        loadingView.state = .isPlaying
    }
    
    public func cplayerItemPlaybackBufferFull() {
        // Hide loading progress
        loadingView.state = .isPlaying
    }
    
    public func cplayerItemPlayebackBufferEmpty() {
        // Show loading progress
        loadingView.state = .isLoading
    }
    
    public func cplayerItemError(_ error:Error) {
        /// Handling error of player is fair enough
        updateLoadingUI(with: error.localizedDescription)
        endPlayerObserving()
    }
    
    public func cplayerItemDidPlayToEndTime() {
        updateLoadingUI(with: "")
    }
    
    public func cplayerItemWillStopObserving() {
    }
}

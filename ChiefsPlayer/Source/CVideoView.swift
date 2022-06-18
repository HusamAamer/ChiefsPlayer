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
    lazy var skipButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Skip", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setTitleColor(.darkGray, for: .normal)
        button.backgroundColor = .lightGray.withAlphaComponent(0.8)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(handleSkipTap), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    var vLayer : AVPlayerLayer?
    @objc var player : CAVQueuePlayer {return ChiefsPlayer.shared.player}
    private var timeObserver: Any?
    
    private var skipButtonAction: () -> Void = {}
    
    init() {
        super.init(frame: .zero)
        
        self.vLayer = AVPlayerLayer(player: self.player)
        self.vLayer?.videoGravity = .resizeAspect
        self.vLayer?.backgroundColor = ChiefsPlayer.shared.configs.maximizedBackgroundColor.cgColor
        //self.backgroundColor = ChiefsPlayer.shared.configs.maximizedBackgroundColor
        self.layer.insertSublayer(self.vLayer!, at: 0)
        
        loadingView = CLoadingView(frame: .zero)
        addSubview(loadingView)
        loadingView.sizeAchor(equalsTo: self)
        
        progressView = CVideoProgressView()
        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressView)
        progressView.delegate = self
        
        
        
        
        
        if #available(iOS 11.0, *) {
            bar_bottom = progressView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 0)
            
            bar_left = progressView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 0)
            
            bar_right = progressView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor)
        } else {
            bar_bottom = progressView.bottomAnchor.constraint(equalTo: lastBaselineAnchor, constant: 0)
            
            bar_left = progressView.rightAnchor.constraint(equalTo: leftAnchor)
            
            bar_right = progressView.rightAnchor.constraint(equalTo: rightAnchor)
        }
        
        bar_bottom.isActive = true
        bar_left.isActive = true
        bar_right.isActive = true
        
        progressView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        startObservation()
        
        addResizeGesture()
        
        // MARK: Add skip view
        addSubview(skipButton)
        NSLayoutConstraint.activate([
            skipButton.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -4),
            skipButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            skipButton.heightAnchor.constraint(equalToConstant: 40),
            skipButton.widthAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    var bar_left : NSLayoutConstraint!
    var bar_right : NSLayoutConstraint!
    var bar_bottom : NSLayoutConstraint!
    
    func setupProgressViewLayout () {
        if isFullscreen {
            let safe = screenSafeInsets
            print(safe)

            if ChiefsPlayer.shared.configs.controlsStyle == .youtube {
                bar_bottom.constant = Device.IS_IPAD ? -54 : -30
                bar_left.constant = 24
                bar_right.constant = -24
            } else {
                bar_bottom.constant = -114
            }
        } else {
            bar_bottom.constant = 0
            bar_left.constant = 0
            bar_right.constant = 0
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
    var isFirstLayout = true
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if isFirstLayout {
            updateVideoLayerFrame()
            isFirstLayout = false
            return
        }
        
        switch ChiefsPlayer.shared.acvStyle {
        case .moving(_):
            updateVideoLayerFrame()
        default:
            break
        }
    }
    
    @objc private func handleSkipTap(sender: UIButton) {
        skipButtonAction()
		
		// Force show loading view
		loadingView.state = .isLoading
		
		// Force hide button
		skipButton.isHidden = true
    }
    
    public func animateVideoLayer (with duration:TimeInterval) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction
            .setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut))
        vLayer?.frame = bounds
        CATransaction.commit()
    }
    
    public func updateVideoLayerFrame () {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        vLayer?.frame = bounds
        CATransaction.commit()
    }
    
    //MARK: Resize Video Gesture xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    /// Pinch Video in or out to change video gravity between aspect fit and fill
    private func addResizeGesture () {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(resizeGestureAction(_:)))
        addGestureRecognizer(pinch)
    }
    @objc
    private func resizeGestureAction (_ gesture:UIPinchGestureRecognizer) {
        if gesture.scale > 1.2 , vLayer?.videoGravity != .resizeAspectFill {
            vLayer?.videoGravity = .resizeAspectFill
        } else if gesture.scale < 0.8, vLayer?.videoGravity != .resizeAspect {
            vLayer?.videoGravity = .resizeAspect
        }
        
        // Code for toggling fullscreen on pinch
        // Deprecated by pan-up gesture
        /*
        if gesture.scale > 1.2 {
            ChiefsPlayer.shared.setFullscreen(on: true)
            gesture.isEnabled = false
            gesture.isEnabled = true
        } else if gesture.scale < 0.8 {
            ChiefsPlayer.shared.setFullscreen(on: false)
            gesture.isEnabled = false
            gesture.isEnabled = true
        }*/
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
    var chiefsplayerReadyToPlayTriggerred: Bool = false
    
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
                self.chiefsplayerReadyToPlayTriggerred
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
            chiefsplayerReadyToPlayTriggerred = false
            progressView.isHidden = true
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
        if hideTimer != nil {
            hideTimer?.invalidate()
            hideTimer = nil
        }
    }
    
    
    
    
    
    
    
    
    
    //MARK: FULLSCREEN Controls  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    var onVideoControls:CBaseControlsView!
    var hideTimer:Timer?
    private var isFullscreen : Bool {
        get {
            return ChiefsPlayer.shared.acvFullscreen.isActive
        }
    }
    
    /// Call after fullscreen update
    func fullscreenStateUpdated () {
        setupProgressViewLayout()
        progressView.alpha = self.controlsAreHidden && isFullscreen ? 0 : 1
        
        
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
        
        if controlsAreHidden {
            onVideoControls.alpha = 0
            if isFullscreen {
                progressView.alpha = 0
            }
        }
        
        onVideoControls.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        insertSubview(onVideoControls, belowSubview: progressView)
        onVideoControls.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            onVideoControls.leadingAnchor.constraint(equalTo: leadingAnchor),
            onVideoControls.trailingAnchor.constraint(equalTo: trailingAnchor),
            //onVideoControls.topAnchor.constraint(equalTo: topAnchor),
            onVideoControls.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Disable animation
        UIView.animate(withDuration: 0) { [self] in
            setNeedsLayout()
            layoutIfNeeded()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        addGestureRecognizer(tap)
        
        // Trigger delegates to tell onVideoControls that we have subtitles or not
        CControlsManager.shared.reloadVideoInfo()
    }
    func removeOnVideoControls () {
        if let onVideoControls = onVideoControls {
            onVideoControls.removeFromSuperview()
            self.onVideoControls = nil
        }
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        // Disable controls hiding while interacting with any subview
        scheduleControlsHiding()
        
        return super.hitTest(point, with: event)
    }
    
    @objc func screenTapped () {
        if onVideoControls == nil {
            return
        }
        
        if frame.width == screenWidth { //if not minimized
            controlsAreHidden = !controlsAreHidden
            if controlsAreHidden == false {
                scheduleControlsHiding()
            }
        }
    }
    
    private func scheduleControlsHiding () {
        hideTimer?.invalidate()
        
        hideTimer = Timer.gck_scheduledTimer(withTimeInterval: 3, weakTarget: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }
    @objc private func hideControls () {
        // For landscape mode the progress bar only appears with controls
        if progressView.isChangingCurrentTime == false {
            if controlsAreHidden == false {
                controlsAreHidden = true
            }
        } else {
            //Try again after delay, until user stops changing current time
            DispatchQueue.main.async { [weak self] in
                self?.scheduleControlsHiding()
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
        if let vLayer = vLayer {
            let toColor = percent > 0.6
                ? ChiefsPlayer.shared.configs.minimizeBackgroundColor.cgColor
                : ChiefsPlayer.shared.configs.maximizedBackgroundColor.cgColor
            
            if vLayer.backgroundColor != toColor {
                vLayer.backgroundColor  = toColor
            }
        }
        
        
        let newAlpha = 1 - (percent * 5)// Set alpha 0 at 5th of reached move
        if !controlsAreHidden {
            onVideoControls?.alpha = newAlpha
        }
        if (isFullscreen && !controlsAreHidden) || !isFullscreen {
            progressView.alpha = newAlpha
			skipButton.alpha = newAlpha
        }
    }
}

//MARK: Player Delegate xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
extension CVideoView: CAVQueuePlayerDelegate {
    public func cavqueueplayerItemReplaced(with item: AVPlayerItem?) {
        if let item = player.currentItem as? CPlayerItem {
            item.delegate = self
            
            if let chromecastManager = ChiefsPlayer.shared.chromecastManager, chromecastManager.sessionIsActive
            {
                ChiefsPlayer.shared.isCastingTo = .chromecast
                chromecastManager.startCastingCurrentItem()
            }
        }
        
        // Trigger delegates to tell onVideoControls that we have subtitles or not
        CControlsManager.shared.reloadVideoInfo()
    }
    
    public func cavqueueplayerReadyToPlay() {
        
    }
    
    public func cavqueueplayerFailed() {
        if let error = player.currentItem?.error {
            updateLoadingUI(with: error.localizedDescription)
        }
    }
    public func cavqueueplayerPlayingStatus(is playing: Bool) {
        CControlsManager.shared.updateControlsPlayButton(to: playing)
    }
}

//MARK: Item Delegate xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
extension CVideoView: CPlayerItemDelegate {
    public func cplayerItemReadyToPlay(_ item:CPlayerItem) {
        //If player is not ready to play yet but casting started, we should pause it here
        if let chromecastManager = ChiefsPlayer.shared.chromecastManager, chromecastManager.sessionIsActive {
            if ChiefsPlayer.shared.isCastingTo == .chromecast {
                ChiefsPlayer.shared.player.pause()
                endPlayerObserving()
                
            }
        }
        
        if let vlayer = vLayer {
            ChiefsPlayer.shared.updateViewsAccordingTo(videoRect: vlayer.videoRect)
        }
        if !chiefsplayerReadyToPlayTriggerred {
            let selectedResolutionIndex = ChiefsPlayer.shared._selectedResolutionIndex
            let selectedSource = ChiefsPlayer.shared.selectedSource
            if selectedResolutionIndex < selectedSource.resolutions.count {
                ChiefsPlayer.shared.delegate?.chiefsplayerReadyToPlay(item ,resolution: selectedSource.resolutions[selectedResolutionIndex], from: selectedSource)
            }
            progressView.isHidden = false
            chiefsplayerReadyToPlayTriggerred = true
        }
        loadingView.state = .isPlaying
        CControlsManager.shared.updateControlsPlayButton(to: true)
    }
    
    public func cplayerItemPlaybackLikelyToKeepUp() {
        loadingView.state = .isPlaying
        progressView.userJustSeeked = false
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
        CControlsManager.shared.updateControlsPlayButton(to: false)
    }
    
    public func cplayerItemDidPlayToEndTime() {
        //If next action was not set then show retry button
        if !CControlsManager.shared.nextBtnAction() {
            updateLoadingUI(with: "")
            CControlsManager.shared.updateAllControllers()
            CControlsManager.shared.updateControlsPlayButton(to: false)
        }
    }
    
    public func cplayerItemWillStopObserving() {
    }
}

extension CVideoView : CControlsManagerDelegate {
    public func controlsLeftAccessoryViewsDidChange(to newViews: [UIView]?) {}
    public func controlsRightAccessoryViewsDidChange(to newViews: [UIView]?) {}
    public func controlsForwardActionDidChange(to newAction: CControlsManager.Action?) {}
    public func controlsBackwardActionDidChange(to newAction: CControlsManager.Action?) {}
    public func controlsNextActionDidChange(to newAction: CControlsManager.Action?) {}
    public func controlsPrevActionDidChange(to newAction: CControlsManager.Action?) {}
    public func controlsSubtitles(are available: Bool) {}
    public func controlsTimeUpdated(to currentTime: String, remaining: String, andPlayer isPlaying: Bool) {}
    public func controlsPlayPauseChanged(to isPlaying: Bool) {}
    public func controlsPlayer(has resolutions: [CPlayerResolutionSource]) {}
    public func controlsPlayerDidChangeResolution(to resolution: CPlayerResolutionSource) {}
    public func controlsPictureInPictureState(is possible: Bool) {}
    public func controlsPlayerFullscreenState(changedTo fullscreenState: ACVFullscreen) {}
    
    public func controlsShouldAppearAboveVideo(in fullscreenMode: ACVFullscreen) -> Bool {
        return true
    }
    public func controlsProgressBarBottomPositionValueForLandscape() -> CGFloat {
        return 0
    }
    
    public func controls(_ controls: CControlsManager, shouldShowButtonWithTitle buttonTitle: String, handler: @escaping () -> Void) {
        //
        skipButton.isHidden = false
        skipButton.setTitle(buttonTitle, for: .normal)
        skipButtonAction = handler
    }
    
    public func controlsShouldHideButton(_ controls: CControlsManager) {
        //
        skipButton.isHidden = true
    }
}

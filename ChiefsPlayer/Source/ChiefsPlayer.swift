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

public class ChiefsPlayer {
    private struct Static
    {
        static var instance: ChiefsPlayer?
    }
    
    class public var shared: ChiefsPlayer
    {
        if Static.instance == nil
        {
            Static.instance = ChiefsPlayer()
        }
        
        return Static.instance!
    }
    
    deinit {
        print("ChiefsPlayer deinit")
    }
    
    lazy var mediaQueue      = [CMediaInfo]()
    public var delegate        :ChiefsPlayerDelegate?
    public lazy var acvStyle        :ACVStyle        = .maximized
    public lazy var acvFullscreen   :ACVFullscreen   = .none {
        didSet {
            CControlsManager.shared.delegates.forEach({$0?.controlsPlayerFullscreenState(changedTo: acvFullscreen)})
        }
    }
    public var configs         :CVConfiguration = CVConfiguration()
    public var player          :CAVQueuePlayer!
    public var sources         :[CPlayerSource] = []
    var _selectedSourceIndex:Int     = 0
    var _selectedResolutionIndex:Int = 0
    var _selectedSubtitleIndex:Int?  = nil
    
    public var selectedSource:CPlayerSource {
        return sources[_selectedSourceIndex]
    }
    
    public var selectedResolution:CPlayerResolutionSource {
        return selectedSource.resolutions[_selectedResolutionIndex]
    }
    
    public var videoView       :CVideoView!
    var parentVC        :UIViewController!
    public var userView        :UIView?
    
    public var controls        :CBaseControlsView!
    public lazy var videoContainer    :UIView! = UIView()
    public lazy var detailsContainer  :UIView! = UIView()
    lazy var detailsStack     = UIStackView()
    
    var notchBackground:UIView?
    
    var isPlayerError   :Bool {return videoView.loadingView.state.isError}
    var orientationToken:Any?
    var airplayToken    :Any?
    
    private lazy var dimensions = [screenWidth,screenHeight]
    private var frameHeight: CGFloat!
    private var frameWidth: CGFloat!
    
    var chromecastManager     :ChromecastManager?
    var _currentCasting :CastingService?
    
    var timeObserverToken: Any?
    var currentTimeline: Timeline?

    var isCastingTo     :CastingService? {
        get {return _currentCasting}
        set {
                        
            ChiefsPlayer.Log(event: "isCasting to \(String(describing: newValue != nil ? newValue! : nil))")
            //Prevent overriding
            if newValue == _currentCasting {return}
            
            //Controls are nil when player is dismissing or before player presenting
            let controls:CBaseControlsView? = self.controls
            
            switch newValue {
            case nil:
                videoView.removeStreamingViewIfExist()
                
                //App is not casting
                controls?.castButton?.isHidden = false
                controls?.airView?.isHidden    = false
                controls?.airView?.sizeToFit()
                //controls.subtitlesBtn.isHidden = false
                
                //Transition from chromecast to avplayer
                if _currentCasting == .chromecast {
                    let progress = videoView.progressView.progressBar.progress
                    if let duration = CChromecastRemoteControlFunctions.castedMediaDuration
                    {
                        let curretCastSeekTime = CMTime(seconds: TimeInterval(progress) * duration, preferredTimescale: 1)
                        player.seek(to: curretCastSeekTime)
                    }
                    player.play()
                    
                    ///Start updating UI
                    videoView.startObservation()
                }
                
                addCurrentSelectedSubtitles()
                
                break
            case .chromecast?:
                videoView.addStreamingView(with: localized("streaming_in_progress") + " Chromecast")
                
                controls?.castButton?.isHidden = false
                controls?.airView?.isHidden    = true
                //controls.subtitlesBtn.isHidden = true
                
                //Transition from avplayer to chromecast
                if _currentCasting == nil {
                    player.pause()
                    ///Stop updating UI
                    videoView.endPlayerObserving()
                }
                
                
                break
            case .airplay?:
                videoView.addStreamingView(with: localized("streaming_in_progress") + " AirPlay")

                controls?.castButton?.isHidden = true
                controls?.airView?.isHidden    = false
                break
            }
            _currentCasting = newValue
            delegate?.chiefsplayer(isCastingTo: newValue)
        }
    }
    //---------------------- Init
    private init() {}
    /// Call for fresh play or play another url
    ///
    public func play(from sources:[CPlayerSource],
              with detailsView:UIView?,
              startWithSourceAt sourceIndex:Int = 0,
              startWithResoultionAt resolutionIndex:Int = 0,
              startWithSubtitleAt subtitleIndex:Int? = nil)
    {
        _selectedSourceIndex        = sourceIndex
        _selectedResolutionIndex    = resolutionIndex
        _selectedSubtitleIndex      = subtitleIndex
        
        if _selectedSourceIndex <= (sources.count - 1),
            _selectedResolutionIndex > (sources[sourceIndex].resolutions.count - 1) {
            ChiefsPlayer.Log(event: "\(#function) - Index out of range")
            if sources[sourceIndex].resolutions.first != nil {
                _selectedResolutionIndex = 0
                ChiefsPlayer.Log(event: "\(#function) - Will open resolution at index 0")
            } else {
                ChiefsPlayer.Log(event: "\(#function) - Player would not present because resolutions array is empty")
                return
            }
        }
        
        self.sources = sources
        let selectedResolution = selectedSource.resolutions[_selectedResolutionIndex]
        let sourceUrl = selectedResolution.source_m3u8 ?? selectedResolution.source_file!
        ChiefsPlayer.Log(event: "\(#function) - \(sourceUrl.path)")
        
        //Add to media queue array
        mediaQueue.removeAll()
        mediaQueue.append(CMediaInfo(url: sourceUrl))
        
        //let item = CPlayerItem(url: sourceUrl)
        if player == nil {
            
            //Init chromecast
            chromecastManager = ChromecastManager()

            initPlayer(with: [])
            self.loadAsset(for: sourceUrl)
            
            //Init video player
            videoView = CVideoView()
            userView  = detailsView
            
            setupOrientationStaff()
            
            //Check if device already connected and streaming to AirPlay service
            airplayChanged(calledProgrammatically: true)
            //Start observing airplay state change
            airplayToken = NotificationCenter.default.addObserver(self, selector: #selector(airplayChanged(calledProgrammatically:)),
                                                                  name: AVAudioSession.routeChangeNotification,
                                                                  object: AVAudioSession.sharedInstance())
            
        } else {
            if let newDetailsView = detailsView {
                replaceUserView(with: newDetailsView)
            }
            reinitPlayer(with: sourceUrl)
            
            if acvStyle == .minimized {
                maximize()
            }
            
            CControlsManager.shared.updateAllControllers()
        }
        
        // Reset current timeline
        if let currentTimeline = currentTimeline {
            self.currentTimeline = nil
            if let action = delegate?.chiefsPlayer(self, didExitTimeline: currentTimeline) {
                CControlsManager.shared.performAction(action: action)
            }
        }
        
        // start observing for active timelines
        timeObserverToken = self.player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main) { [weak self] time in
			
			guard let `self` = self else { return }
			
			if let currentTimeline = self.currentTimeline {
                if time.seconds > currentTimeline.endTime {
                    self.currentTimeline = nil
					if let action = self.delegate?.chiefsPlayer(self, didExitTimeline: currentTimeline) {
                        CControlsManager.shared.performAction(action: action)
                    }
                }
            } else if let currentTimeline = self.selectedSource.timelines?.first(where: { time.seconds >= $0.startTime && time.seconds < $0.endTime }) {
                self.currentTimeline = currentTimeline
				if let action = self.delegate?.chiefsPlayer(self, didEnterTimeline: currentTimeline) {
                    CControlsManager.shared.performAction(action: action)
                }
            }
        }
        
        // Add subtitles if playing locally only
        if isCastingTo == nil {
            addCurrentSelectedSubtitles()
        }
    }
    //**//**//**//**//**//**//**//**//**//**//**//**//**//**
    
    private func setupOrientationStaff () {
        orientationToken = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,queue: .main,using: { [weak self] notification in
                guard let `self` = self else {return}
                
                let newOrientation = UIDevice.current.orientation
                guard let interfaceOrientaion = self.interfaceOrientationMask(for: newOrientation) else {
                    return
                }
                
                let canRotate = self.allowedOrientations.contains(interfaceOrientaion)
                
                //!(Device.IS_IPHONE && self.acvFullscreen.isLocked && newOrientation.isPortrait)
                
                if !canRotate {
                    self.lastRejectedOrientation = interfaceOrientaion
                    return
                }
                
                if let interfaceOrientaion = self.interfaceOrientation(for: newOrientation) {
                    
                    self.delegate?.chiefsplayerOrientationChanged(
                        to: interfaceOrientaion,
                        shouldLock: self.acvFullscreen.isLocked,
                        isMaximized: self.acvStyle == .maximized)
                }
                //                }
                //
                //                if Device.IS_IPHONE, isMinimized {
                //                    return
                //                }
                //
                //                if canRotate {
                switch newOrientation {
                case .landscapeLeft, .landscapeRight:
                    self.frameWidth = self.dimensions.max()!
                    self.frameHeight = self.dimensions.min()!
                    break
                case .portrait,.portraitUpsideDown:
                    self.frameWidth = self.dimensions.min()!
                    self.frameHeight = self.dimensions.max()!
                    break
                default:
                    break
                }
                self.updateOnMaxFrame()
                
                // if minimized and iPad rotated then recalculate UI
                if self.acvStyle == .minimized {
                    self.minimize()
                    return
                }
                
                switch newOrientation {
                case .landscapeLeft, .landscapeRight:
                    print("landscape")
                    
                    // iPad full screen activated only by gestures or btn
                    if Device.IS_IPAD {
                        self.setViewsScale(animated: true)
                    } else {
                        self.startFullscreen()
                    }
                    
                    break
                case .portrait, .portraitUpsideDown:
                    
                    // iPhone: Don't change UI in upside down
                    //                        if newOrientation == .portraitUpsideDown && Device.IS_IPHONE {
                    //                            return
                    //                        }
                    //else
                    if !canRotate {
                        return
                    }
                    
                    print("Portrait")
                    
                    if self.acvFullscreen.isNotLocked {
                        self.endFullscreen()
                    } else {
                        self.startFullscreen()
                    }
                    break
                default:
                    print("other")
                    break
                }
                
        })
    }
    
    // Last Natural Device Orientation, Not Manual
    public lazy var lastRejectedOrientation: UIInterfaceOrientationMask = .portrait
    
    /// The currently allowed orientations by the player
    public var allowedOrientations: UIInterfaceOrientationMask {
        get {
            if Device.IS_IPAD {
                return .all
            }
            
            if acvFullscreen.isLocked {
                return [.landscapeLeft,.landscapeRight]
            }
            
            if acvStyle == .maximized {
                return .all
            }
            
            if acvStyle == .minimized {
                return [.portrait, .portraitUpsideDown]
            }
            
            return .all
        }
    }
    
    //**//**//**//**//**//**//**//**//**//**//**//**//**//**
    
    @discardableResult
    public func toggleFullscreen () -> ACVFullscreen {
        setFullscreen(on: acvFullscreen.isNotActive)
        return acvFullscreen
    }
    
    public func setFullscreen (on:Bool) {
        if Device.IS_IPAD {
            /// Used for iPad to force full screen even in portrait mode
            /// setFullscreenWithLock
            fullscreenStateShouldChange(to: on, locked: true)
        } else {
            forceToggleFullscreenByOrientingDevice(on: on)
        }
    }
    
    /// For iPhone only
    private func forceToggleFullscreenByOrientingDevice (on:Bool) {
        
        acvFullscreen = on ? .activatedLock : .none
        
        // Toggle to portrait value
        var deviceOrientation:UIDeviceOrientation = .portrait
        
        // Toggle full screen value and decide direction according to the current device orientation
        if on {
            
            let isLandscapeNow = lastRejectedOrientation == .landscape
            
            deviceOrientation = isLandscapeNow
                ? lastRejectedOrientation == .landscapeRight ? .landscapeLeft : .landscapeRight
                : .landscapeLeft
        } else {
            
            let isPortraitNow = lastRejectedOrientation == .portrait
            
            deviceOrientation = isPortraitNow
                ? lastRejectedOrientation == .portrait ? .portrait : .portraitUpsideDown
                : .portrait
            
        }
        
        // Tell parent app to change lock settings before changing orientation manually
        // Only because We're changing it manually we have to tell the parent app first
        if let interfaceOrientaion = interfaceOrientation(for: deviceOrientation) {
            fireOrientationChangedDelegate(for: interfaceOrientaion)
        }
        
        // Forece orientation change
        UIDevice.current.setValue(deviceOrientation.rawValue, forKey: "orientation")
        
        // Fire notification to update UI
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    /// Fires delegate methid to tell the parent app about the preferred orientation settings
    /// - Parameter interfaceOrientaion: New orientation
    func fireOrientationChangedDelegate (for interfaceOrientaion:UIInterfaceOrientation) {
        self.delegate?.chiefsplayerOrientationChanged(
            to: interfaceOrientaion,
            shouldLock: self.acvFullscreen.isLocked,
            isMaximized: self.acvStyle == .maximized)
    }
    
    //*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*
    //* Change UI for fullscreen change
    //*//*//*//*//*//*//*//*//*//*//*//*//*//*//*//*
    private func startFullscreen () {
        fullscreenStateShouldChange(to: true, locked: acvFullscreen.isLocked)
    }
    
    private func endFullscreen () {
        fullscreenStateShouldChange(to: false)
    }
    private func fullscreenStateShouldChange (to isFullscreen:Bool, locked:Bool = false) {
        
        let toMode:ACVFullscreen = isFullscreen
            ? (locked ? .activatedLock : .activated)
            : .none
        
        acvFullscreen = toMode
        
        let shouldShowControls = CControlsManager.shared.shouldShowControlsAboveVideo(in: acvFullscreen)
        
        if shouldShowControls {
            videoView.addOnVideoControls()
        } else {
            videoView.removeOnVideoControls()
        }
        
        setViewsScale(animated: true)
        
        let duration = configs.fullscreenAnimationDuration
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.curveEaseOut, .allowAnimatedContent, .allowUserInteraction],
                       animations: {
                        self.videoView.fullscreenStateUpdated()
                       }, completion: nil)
        
        
    }
    
    
    //**//**//**//**//**//**//**//**//**//**//**//**//**//**
    let assetKeysRequiredToPlay = [
        "playable"
    ]
    var newAsset:AVURLAsset?
    func loadAsset (for url:URL) {

        newAsset = AVURLAsset(url: url)
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset?.loadValuesAsynchronously(forKeys: assetKeysRequiredToPlay) { [weak self] in
            guard let `self` = self else {return}
            guard let player = self.player else {return}
            guard let newAsset = self.newAsset else {return}
            
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            ChiefsPlayer.Log(event: "Asset loaded")
            
            /*
             Test whether the values of each of the keys we need have been
             successfully loaded.
             */
            for key in self.assetKeysRequiredToPlay {
                var error: NSError?
                if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                    ChiefsPlayer.Log(event: "Asset error #1")
                    /**
                     "Can't use this AVAsset because one of it's keys failed to load"
                     */
                    let message = localized("error.asset_key_%@_failed.description".replacingOccurrences(of: "%@", with: key))
                    DispatchQueue.main.async {
                        self.videoView.loadingView.state = .Error(msg: message)
                    }
                    return
                }
            }
            // We can't play this asset.
            if !newAsset.isPlayable || newAsset.hasProtectedContent {
                ChiefsPlayer.Log(event: "Asset error #2")
                /**
                 "Can't use this AVAsset because it isn't playable or has protected content"
                */
                let message = localized("error.asset_not_playable.description")
                DispatchQueue.main.async {
                    self.videoView?.loadingView?.state = .Error(msg: message)
                }
                return
            }
            
            DispatchQueue.main.async {
                ChiefsPlayer.Log(event: "Asset loaded #2")
                let playerItem = CPlayerItem(asset: newAsset)
                player.replaceCurrentItem(with: playerItem)
            }
        }
    }
    func controlsForCurrentStyle() -> CBaseControlsView {
        switch configs.controlsStyle {
        case .barStyle:
            return CVideoControlsView.instanceFromNib()
        default:
            return COverPlayerControlsView.instanceFromNib()
        }
    }
    @objc func airplayChanged (calledProgrammatically:Bool = false) {
        var airplayConnected = false
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            if output.portType == AVAudioSession.Port.airPlay {
                print("Airplay Device connected with name: \(output.portName)")
                /**
                 If iOS ScreenMirror is enabled `UIScreen.screens.count` equals 2
                 else
                 Then we are streaming only this AVPlayer
                 */
                if UIScreen.screens.count == 1 {
                    airplayConnected = true
                }
            }
        }
        print( "airplay ::> ",airplayConnected)
        
        in_main {
            //Change value only if there is a change to prevent calling didSet
            if calledProgrammatically, airplayConnected == false {
                
            } else {
                self.isCastingTo = airplayConnected ? .airplay : nil
            }
        }
    }
    func initPlayer (with items:[CPlayerItem]) {
        ChiefsPlayer.Log(event: "\(#function)")

        player = CAVQueuePlayer()
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            //self.player.replaceCurrentItem(with: items.first!)
        //}
        
        //Enable sound when device in silent mode
        do {

            if #available(iOS 10.0, *) {
                try AVAudioSession
                    .sharedInstance()
                    .setCategory(AVAudioSession.Category.playback,
                                 mode: AVAudioSession.Mode.moviePlayback,
                                 options: [AVAudioSession.CategoryOptions.duckOthers,.allowAirPlay])
            }
        } catch {
            // report for an error
        }
    }
    func reinitPlayer (with url:URL) {
        ChiefsPlayer.Log(event: "\(#function)")
        
        announcePlayerWillStop()
        
        removeCurrentSubtitles()
        videoView.endPlayerObserving()
        CControlsManager.shared.endPlayerObserving()
        
        player.replaceCurrentItem(with: nil)
        loadAsset(for: url)
        loadAsset(for: url)
            
        videoView.loadingView.state = .isLoading
        videoView.startObservation()
        CControlsManager.shared.startObserving()
    }
    /// Remove current item then insert it again
    func reloadPlayer ()
    {
        if let url = mediaQueue.first?.url {
            reinitPlayer(with: url)
        
            // Add subtitles if playing locally only
            if isCastingTo == nil {
                addCurrentSelectedSubtitles()
            }

            ChiefsPlayer.shared.player.play()
        }
        
    }
    
    private func announcePlayerWillStop () {
        if let currentItem = player.currentItem as? CPlayerItem,
            !isPlayerError
        {
            delegate?.chiefsplayerWillStop(playing: currentItem)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //----------------------
    var vY:NSLayoutConstraint!
    var vX:NSLayoutConstraint!
    var vW:NSLayoutConstraint!
    var dY:NSLayoutConstraint!
    var dH:NSLayoutConstraint!
    var vH:NSLayoutConstraint!
    
    public func present(on viewController:UIViewController) {
        if parentVC != nil {
            ChiefsPlayer.Log(event: "Player is already presented")
            return
        }
        if player == nil {
            ChiefsPlayer.Log(event: "Please ensure calling `play(from:with:startWithSourceAt:startWithResoultionAt:startWithSubtitleAt:)` with valid indexes before trying presenting player")
            return
        }
        
        parentVC = viewController
        
        frameHeight = parentVC.view.bounds.height
        frameWidth = parentVC.view.bounds.width
        updateOnMaxFrame()
        
        if #available(iOS 11.0, *) {
            if Device.HAS_NOTCH {
                notchBackground = UIView()
                notchBackground?.backgroundColor = .black
                parentVC.view.addSubview(notchBackground!)
                notchBackground?.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    notchBackground!.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
                    notchBackground!.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
                    notchBackground!.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
                    notchBackground!.bottomAnchor.constraint(equalTo: parentVC.view.safeAreaLayoutGuide.topAnchor)
                ])
            }
        }

        detailsContainer.backgroundColor = .white
        parentVC.view.addSubview(detailsContainer)
        parentVC.view.addSubview(videoContainer)
        
        
        videoContainer.backgroundColor = UIColor.black
        
        addGestures()
                
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // X
        vX = videoContainer.leftAnchor
            .constraint(equalTo: parentVC.view.leftAnchor) //Use left instead of leading to be on left side in arabic and english
        vX.isActive = true
        let dX = detailsContainer.leftAnchor
            .constraint(equalTo: parentVC.view.leftAnchor)
        dX.isActive = true
        
        // Width - where scale != 1
        vW = videoContainer.widthAnchor
            .constraint(equalToConstant: frameWidth)
        vW.priority = .required
        vW.isActive = true
        
        let dW = detailsContainer.widthAnchor
            .constraint(equalTo: parentVC.view.widthAnchor, multiplier: 1)
        dW.isActive = true
        
        
        // Y
        
        if #available(iOS 11.0, *), Device.HAS_NOTCH {
            //For notch devices
            vY = videoContainer.topAnchor
                .constraint(equalTo: parentVC.view.safeAreaLayoutGuide.topAnchor)
        } else {
            vY = videoContainer.topAnchor
            .constraint(equalTo: parentVC.view.topAnchor)
        }
        vY.isActive = true
        dY = detailsContainer.topAnchor
            .constraint(equalTo: videoContainer.bottomAnchor)
        dY.isActive = true
        
        //Height
        let spaceUnderVideo = frameHeight - onMaxFrame.height - topSafeArea
        dH = detailsContainer.heightAnchor
            .constraint(equalToConstant: spaceUnderVideo)
        dH.priority = .defaultHigh
        dH.isActive = true
        detailsContainer.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        // Ratios
        vH = videoContainer.heightAnchor
            .constraint(equalToConstant: onMaxFrame.height)
        vH.priority = .required
        vH.isActive = true
        
        //Add subviews to containers
        videoContainer.addSubview(videoView)
        videoView.sizeAchor(equalsTo: videoContainer)
        
        detailsStack.distribution = .fill
        detailsStack.alignment = .fill
        detailsStack.axis = .vertical
        detailsContainer.addSubview(detailsStack)
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        detailsStack.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor).isActive = true
        detailsStack.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor).isActive = true
        detailsStack.topAnchor.constraint(equalTo: detailsContainer.topAnchor).isActive = true
        detailsStack.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor).isActive = true
                
        //Add controls
        //Finally, We can init controls after user set the style
        controls  = controlsForCurrentStyle()
        
        if CControlsManager.shared.shouldShowControlsAboveVideo(in: acvFullscreen) {
            videoView.addOnVideoControls()
        } else {
            detailsStack.addArrangedSubview(controls)
        }
        
        addUserViewToContainer()
                
        if !Device.HAS_NOTCH {
            delegate?.chiefsplayerStatusBarShouldBe(hidden: true)
        }
        
        delegate?.chiefsplayerAppeared()
    }
    func replaceUserView (with view:UIView)
    {
        if userView?.superview != nil {
            userView?.removeFromSuperview()
        }
        userView = view
        addUserViewToContainer()
    }
    func addUserViewToContainer ()
    {
        if let userView = userView {
            detailsStack.addArrangedSubview(userView)
        }
    }
    /// Removes ChiefsPlayer from the view
    func dismiss() {
        //Check if is presented by checking one of the sub views if initiated
        //If is not presented then dealloc shared instance
        if videoView == nil {
            Static.instance = nil
            return
        }
        
        announcePlayerWillStop()
        
        //Stop casting
        if isCastingTo == .chromecast {
            chromecastManager?.end(andStopCasting: true)
        }
        
        //Stop chromecast manager
        chromecastManager = nil
        
        //Remove notification tokens before views removing
        //Because notif may get triggerred after view removing and booo "crashed"
        if orientationToken != nil {
            NotificationCenter.default.removeObserver(orientationToken!)
            NotificationCenter.default.removeObserver(airplayToken!)
        }

        //Stop Player
        videoView.endPlayerObserving()
        CControlsManager.shared.endPlayerObserving()
        
        /// # CRASH FIX:
        /// App crashes when dismiss happenes and AirPlay & Chromecast is Active
        (player.items() as! [CPlayerItem]).forEach({$0.stopObserving()})
        player.removeAllItems()
        
        //Remove observers
        // done in deinit function
        
        //Remove all views
        notchBackground?.removeFromSuperview()
        videoView.removeFromSuperview()
        videoView = nil
        controls.removeFromSuperview()
        controls = nil
        userView?.removeFromSuperview()
        userView = nil
        videoContainer.removeFromSuperview()
        videoContainer = nil
        detailsContainer.removeFromSuperview()
        detailsContainer = nil
        
        delegate?.chiefsplayerDismissed()

        //Remove player after removing all observers and views
        self.player.stopObserving()
        self.player = nil
        
        //Remove shared instance
        CControlsManager.shared._deinit()
        ChiefsPlayer.Static.instance = nil

    }
    
    /// Chenges videoView height according to video actual height
    ///
    /// - Parameter videoRect: Video layer frame inside videoView
    func updateViewsAccordingTo(videoRect:CGRect)
    {
        if videoRect.height == 0 {
            return
        }
        var videoRatio = videoRect.width / videoRect.height
        
        configs.videoRatio = .custom(videoRatio)
        
        //Set minimum video ratio
        if videoRatio > 2 {videoRatio = 2}
        
		updateOnMaxFrame()
		
        setViewsScale(animated: true)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func addGestures () {
        let drag = UIPanGestureRecognizer(target: self,
                                          action: #selector(dragVideo(pan:)))
        videoContainer.addGestureRecognizer(drag)
        
        let tapToMaximizeGes = UITapGestureRecognizer(target: self,
                                          action: #selector(tapToMaximize))
        videoContainer.addGestureRecognizer(tapToMaximizeGes)
    }
    @objc func tapToMaximize () {
        if acvStyle != .maximized {
            maximize()
        }
    }
    
    private var topSafeArea:CGFloat {
        if #available(iOS 11.0, *), Device.HAS_NOTCH {
            return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
        }
        return 0
    }
    
    private var bottomSafeArea:CGFloat {
        set {}
        get {
            var value:CGFloat = 0
            if #available(iOS 11.0, *) {
                value += UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            }
            if let additional = configs.onMinimizedAdditionalBottomSafeArea {
                value += additional
            }
            return value
        }
    }
    
    lazy var onMaxFrame:CGRect  = .zero
    lazy var onMinFrame:CGRect  = .zero
    lazy var onTouchBeganFrame:CGRect  = .zero
    lazy var max_vY : CGFloat = 0
    lazy var maxEnlargeTravel : CGFloat = 34
    
    private func updateOnMaxFrame () {
        let videoHeight = frameWidth / configs.videoRatio.value
        
        // Max Frame should not be higher than half of screen
        let maxVideoHeight = round(min(frameHeight / 2, videoHeight))
        
        onMaxFrame = CGRect(x: 0, y: 0, width: frameWidth, height: maxVideoHeight)
        
        let minWidth = round(frameWidth * configs.onMinimizedMinimumScale)
        onMinFrame = CGRect(x: 0, y: 0,
                             width: minWidth,
                             height: minWidth/(configs.videoRatio.value))
        
        max_vY = (frameHeight - bottomSafeArea) - topSafeArea - onMinFrame.height
    }
    
    
    @objc func dragVideo (pan:UIPanGestureRecognizer) {
        
        // Allow dragging always on iPad
        // Prevent dragging in iPhone on fullscreen
        let canDismissAndMinimize = !(!Device.IS_IPAD && acvFullscreen.isActive)
        
        if pan.state == UIGestureRecognizer.State.began {
            
            if acvStyle == .maximized {
                updateOnMaxFrame()
            }
            onTouchBeganFrame = pan.view!.frame.insetBy(dx: 0, dy: -topSafeArea)
        }
        
        if pan.state == UIGestureRecognizer.State.ended {
                        
            if case ACVStyle.enlarging(let yTravel) = acvStyle {
                if yTravel >= maxEnlargeTravel {
                    toggleFullscreen()
                }
                acvStyle = .maximized // Finish enlarging
                if let vLayer = videoView.vLayer {
                    vLayer.frame = CGRect(x: vLayer.frame.minX,
                                          y: 0,
                                          width: vLayer.frame.width,
                                          height: vLayer.frame.height)
                }
                return
            }
            
            if case ACVStyle.dismissing(let percent) = acvStyle {
                if percent > 0.3 {
                    dismiss()
                } else {
                    minimize()
                }
                return
            }
            
            if canDismissAndMinimize {
                let yFinger      = pan.location(in: parentVC.view).y
                let height       = frameHeight!
                
                let dir = pan.direction(in: parentVC.view)
                let isUp = dir.contains(.Up)
                let isDown = dir.contains(.Down)
                let velocity = abs(pan.velocity(in: parentVC.view).y)
                
                if velocity > 900 {
                    if isDown {
                        minimize()
                    } else if isUp {
                        maximize()
                    }
                } else {
                    if abs(yFinger) < height / 2 {
                        maximize()
                    } else {
                        minimize()
                    }
                }
            }
        }
        
        if pan.state == UIGestureRecognizer.State.changed {
            let dir = pan.direction(in: parentVC.view)
            let isRight = dir.contains(.Right)
            let isLeft = dir.contains(.Left)
            let yVelocity = abs(pan.velocity(in: parentVC.view).y)
            let xVelocity = abs(pan.velocity(in: parentVC.view).x)
            
            var dismissingWillStart = false
            if acvStyle == .minimized && xVelocity > yVelocity && (isRight || isLeft) {
                dismissingWillStart = true
            }
            
            var isDismissing = false
            if case ACVStyle.dismissing = acvStyle {
                isDismissing = true
            }
            
            var isChangingFullscreen = false
            
            if acvStyle == .maximized && dir.contains(.Up) {
                isChangingFullscreen = true
            }
            if case ACVStyle.enlarging = acvStyle {
                isChangingFullscreen = true
            }
            
            if isChangingFullscreen {
                
                let yTranslation = pan.translation(in: parentVC.view).y
                enlargeView(with: yTranslation)
                
            } else if canDismissAndMinimize{
                if isDismissing || dismissingWillStart {
                    
                    let xTranslation = pan.translation(in: parentVC.view).x
                    dismissView(with: xTranslation)
                } else {
                    
                    let yTranslation = pan.translation(in: parentVC.view).y
                    minimizeView(with: yTranslation)
                }
            }
        } else {
            // or something when its not moving
        }
    }
    func enlargeView (with yTranslation:CGFloat){
        var y = self.onTouchBeganFrame.minY + yTranslation
        
        //don't move videoView off of the screen
        if y > 0 {
            y = 0
        } else if -y > maxEnlargeTravel {
            y = -maxEnlargeTravel
        }
        
        if let vLayer = videoView.vLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            vLayer.frame = CGRect(x: vLayer.frame.minX,
                                  y: y,
                                  width: vLayer.frame.width,
                                  height: vLayer.frame.height)
            CATransaction.commit()
            acvStyle = .enlarging(-y)// -y = travel
        }
    }
    func minimizeView (with yTranslation:CGFloat){
        var y = onTouchBeganFrame.minY + yTranslation
        
        //don't move videoView off of the screen
        if y < 0 {
            y = 0
        }
        
        vY.constant = y
        
        let movePercent = abs(vY.constant / max_vY)
        acvStyle = .moving(movePercent)
        
        //Scale
        setViewsScale()
    }
    func dismissView (with xTranslation:CGFloat){
        let x = onTouchBeganFrame.minX + xTranslation
        vX.constant = x

        let movePercent = abs(vX.constant / frameWidth)
        videoContainer.alpha = 1 - movePercent
        acvStyle = .dismissing(movePercent)
    }
    func setViewsScale (animated:Bool = false) {
        if !Device.HAS_NOTCH {
            let statusBarOriginalHeight = CGFloat(20)
            let statusBarHeight         = UIApplication.shared.statusBarFrame.height
            let statusBarIsHidden       = statusBarHeight == 0
            if !statusBarIsHidden , vY.constant <= statusBarOriginalHeight {
                delegate?.chiefsplayerStatusBarShouldBe(hidden : true)
            } else if statusBarIsHidden, vY.constant > statusBarOriginalHeight {
                delegate?.chiefsplayerStatusBarShouldBe(hidden : false)
            }
        }
        
        
        let movePercent = abs(vY.constant / max_vY)
        vW.constant = onMinFrame.width + (1 - movePercent) * (onMaxFrame.width - onMinFrame.width)
        
        let maxHeight:CGFloat = acvFullscreen.isActive ? frameHeight : onMaxFrame.height
        let minHeight = onMinFrame.height //onMaxFrame.height * configs.onMinimizedMinimumScale
        vH.constant = minHeight + (maxHeight - minHeight) *  (1 - movePercent)
        
        dY.constant = bottomSafeArea * movePercent
        
        let spaceUnderVideo = frameHeight - onMaxFrame.height - topSafeArea
        dH.constant = spaceUnderVideo
        
        videoView.loadingView.setMinimize(with: movePercent)
        videoView.streamingView?.setMinimize(with: movePercent)
        videoView.setMinimize(with: movePercent)
        
        notchBackground?.alpha = 1 - movePercent * 6
        
        if animated {
            let duration = configs.fullscreenAnimationDuration
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: [.curveEaseOut, .allowAnimatedContent, .allowUserInteraction],
                           animations: {
                            self.parentVC.view.layoutIfNeeded()
                            self.videoView.animateVideoLayer(with: duration)
                           }, completion: nil)
        } else {
            parentVC.view.layoutIfNeeded()
			videoView.animateVideoLayer(with: 0)
        }
    }
    
    func maximize () {
        
        acvStyle = .maximized
        videoView.progressView.isUserInteractionEnabled = true
        let newdY:CGFloat = 0//isLandscape ? -ChiefsPlayer.shared.controls.frame.height : 0
        let duration = 0.15
        UIView.animate(
            withDuration: duration, delay: 0, options: [.curveEaseOut,.allowAnimatedContent,.allowUserInteraction],
            animations: {
                self.vY.constant = 0
                self.setViewsScale()
                self.parentVC.view.layoutIfNeeded()
                self.dY.constant = newdY
                self.videoView.animateVideoLayer(with: duration)
        }) { (done) in
            
        }
        
        delegate?.chiefsplayerMaximized()
    }
    public func minimize () {
        acvStyle = .minimized
        
        if onMaxFrame == .zero {
            onMaxFrame = videoView.bounds
        }
        
        videoView.progressView.isUserInteractionEnabled = false
        
        let duration = 0.15
        UIView.animate(
            withDuration: duration, delay: 0, options: [.curveEaseOut,.allowAnimatedContent,.allowUserInteraction],
            animations: {
                self.vX.constant = 0
                self.videoContainer.alpha = 1
                self.vY.constant = self.max_vY
                self.dY.constant = self.bottomSafeArea
                self.setViewsScale()
                self.parentVC.view.layoutIfNeeded()
                self.videoView.animateVideoLayer(with: duration)
        }) { (done) in
            
        }
        
        delegate?.chiefsplayerMinimized()
    }
    
    func toggleVideoAspect () {
        let vLayer = videoView.vLayer

        if vLayer?.videoGravity == .resizeAspectFill {
            vLayer?.videoGravity = .resizeAspect
        } else {
            vLayer?.videoGravity = .resizeAspectFill
        }
    }
}

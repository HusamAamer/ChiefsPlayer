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

public protocol ChiefsPlayerDelegate:class {
    //Called whene player get maximized or fullscreen
    func chiefsplayerStatusBarShouldBe (hidden:Bool)
    //Called only once, when player state is ReadyToPlay for the first time
    func chiefsplayerWillStart (playing item:CPlayerItem)
    //Called on dismiss() or playing another video
    func chiefsplayerWillStop (playing item:CPlayerItem)
    //Called periodically every when video is playing
    func chiefsplayer (isPlaying item:CPlayerItem, at second:Float, of totalSeconds:Float)
    
    func chiefsplayerAppeared ()
    func chiefsplayerDismissed()
    func chiefsplayerMaximized()
    func chiefsplayerMinimized()
    
    //Called when video needs to be oriented
    func chiefsplayerOrientationChanged (to newOrientation:UIInterfaceOrientation)
    
    //Called when player is streaming to airply or chromecast
    func chiefsplayer(isCastingTo castingService:CastingService?)
    
    //Here you can apply any modification to source before casting starts
    func chiefsplayerWillStartCasting(from source:CPlayerSource) -> CPlayerSource?
}

//Make functions optional
public extension ChiefsPlayerDelegate {
    func chiefsplayerStatusBarShouldBe (hidden:Bool) {}
    func chiefsplayerWillStart (playing item:CPlayerItem) {}
    func chiefsplayerWillStop (playing item:CPlayerItem) {}
    func chiefsplayer (isPlaying item:CPlayerItem, at second:Float, of totalSeconds:Float) {}
    func chiefsplayerAppeared () {}
    func chiefsplayerDismissed() {}
    func chiefsplayerMaximized() {}
    func chiefsplayerMinimized() {}
    func chiefsplayerOrientationChanged (to newOrientation:UIInterfaceOrientation) {}
    func chiefsplayer(isCastingTo castingService:CastingService?){}
    func chiefsplayerWillStartCasting(from source:CPlayerSource) -> CPlayerSource? { return nil}
}
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
    var mediaQueue      = [CMediaInfo]()
    public var delegate        :ChiefsPlayerDelegate?
    public var acvStyle        :ACVStyle        = .maximized
    public var configs         :CVConfiguration = CVConfiguration()
    public var player          :AVQueuePlayer!
    public var sources         :[CPlayerSource] = []
    var _selectedSourceIndex:Int     = 0
    var _selectedResolutionIndex:Int = 0
    var _selectedSubtitleIndex:Int?  = nil
    
    public var selectedSource:CPlayerSource {
        return sources[_selectedSourceIndex]
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
    
    var chromecastManager     :ChromecastManager?
    var _currentCasting :CastingService?
    var isCastingTo     :CastingService? {
        get {return _currentCasting}
        set {
            
            //Controls are nil when player is dismissing
            if controls == nil {
                return
            }
            
            switch newValue {
            case nil:
                //App is not casting
                controls.castButton?.isHidden = false
                controls.airView?.isHidden    = false
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
                    videoView.startObservation()
                }
                
                addCurrentSelectedSubtitles()
                
                break
            case .chromecast?:
                controls.castButton?.isHidden = false
                controls.airView?.isHidden    = true
                //controls.subtitlesBtn.isHidden = true
                
                //Transition from avplayer to chromecast
                if _currentCasting == nil {
                    player.pause()
                    videoView.endPlayerObserving()
                }
                break
            case .airplay?:
                controls.castButton?.isHidden = true
                controls.airView?.isHidden    = false
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
        
        self.sources = sources
        let selectedResolution = selectedSource.resolutions[_selectedResolutionIndex]
        let sourceUrl = selectedResolution.source_m3u8 ?? selectedResolution.source_file!
        ChiefsPlayer.Log(event: "\(#function) - \(sourceUrl.path)")
        
        //Add to media queue array
        mediaQueue.removeAll()
        mediaQueue.append(CMediaInfo(url: sourceUrl))
        
        let item = CPlayerItem(url: sourceUrl)
        if player == nil {
            initPlayer(with: [item])
            
            //Init chromecast
            chromecastManager = ChromecastManager()

            //Init video player
            videoView = CVideoView()
            userView  = detailsView
            
            orientationToken = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,queue: .main,using: { [weak self] notification in
                    guard let `self` = self else {return}
                    
                    if self.acvStyle == .minimized {return}
                    let newOrientation = UIDevice.current.orientation
                    if newOrientation == self.lastRotate {return}
                    
                    if let interfaceOrientaion = self.interfaceOrientation(for: newOrientation) {
                        self.delegate?.chiefsplayerOrientationChanged(to: interfaceOrientaion)
                    }
                    
                    let shouldShowControls = CControlsManager.shared.shouldShowControlsAboveVideo(for: newOrientation)
                    switch newOrientation {
                    case .landscapeLeft, .landscapeRight:
                        print("landscape")
                        self.vHLandscape.isActive = true
                        self.videoView.isFullscreen = true
                        self.maximize()
                        if shouldShowControls {
                            self.videoView.addOnVideoControls()
                        }
                        break
                    case .portrait:
                        print("Portrait")
                        self.vHLandscape.isActive = false
                        self.videoView.isFullscreen = false
                        self.maximize()
                        if !shouldShowControls {
                            self.videoView.removeOnVideoControls()
                        }
                        break
                    default:
                        print("other")
                        break
                    }
                    
                    self.lastRotate = newOrientation
            })
            
            //Check if device already connected and streaming to AirPlay service
            airplayChanged()
            //Start observing airplay state change
            airplayToken = NotificationCenter.default.addObserver(self, selector: #selector(airplayChanged),
                                                                  name: AVAudioSession.routeChangeNotification,
                                                                  object: AVAudioSession.sharedInstance())
            
            
        } else {
            //TODO: May needs improvement
            if let newDetailsView = detailsView {
                replaceUserView(with: newDetailsView)
            }
            reinitPlayer(with: [item])
            if isCastingTo == .chromecast, let chromecastManager = chromecastManager {
                chromecastManager.startCastingCurrentItem()
            } else {
                player.play()
            }
            maximize()
            CControlsManager.shared.updateAllControllers()
        }
        
        // Add subtitles if playing locally only
        if isCastingTo == nil {
            addCurrentSelectedSubtitles()
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
    @objc func airplayChanged () {
        var airplayConnected = false
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            if output.portType == AVAudioSession.Port.airPlay {
                print("Airplay Device connected with name: \(output.portName)")
                airplayConnected = true
            }
        }
        print( "airplay ::> ",airplayConnected)
        in_main {
            self.isCastingTo = airplayConnected ? .airplay : nil
        }
    }
    func initPlayer (with items:[CPlayerItem]) {
        ChiefsPlayer.Log(event: "\(#function)")
        
        player = AVQueuePlayer(items: items)
        
        //Enable sound when device in silent mode
        do {
            
            if #available(iOS 10.0, *) {
                try AVAudioSession
                    .sharedInstance()
                    .setCategory(AVAudioSession.Category.playback,
                                 mode: AVAudioSession.Mode.moviePlayback,
                                 options: [AVAudioSession.CategoryOptions.duckOthers,.allowAirPlay])
                
//                if #available(iOS 11.0, *) {
//                    print(AVAudioSession.sharedInstance().routeSharingPolicy)
//                } else {
//                    // Fallback on earlier versions
//                }
            }
        } catch {
            // report for an error
        }
    }
    func reinitPlayer (with items:[CPlayerItem]) {
        ChiefsPlayer.Log(event: "\(#function)")
        
        announcePlayerWillStop()
        
        removeCurrentSubtitles()
        videoView.endPlayerObserving()
        CControlsManager.shared.endPlayerObserving()
        
        player.pause()
        player.removeAllItems()
        player = nil
        
        initPlayer(with: items)
        
        videoView.vLayer.player = player
        videoView.loadingView.state = .isLoading
        videoView.startObservation()
        CControlsManager.shared.startObserving()
    }
    /// Remove current item then insert it again
    func reloadPlayer ()
    {
        let urls = mediaQueue.map({$0.url})
        var items = [CPlayerItem]()
        urls.forEach({items.append(CPlayerItem.init(url: $0))})
        reinitPlayer(with: items)
        
        // Add subtitles if playing locally only
        if isCastingTo == nil {
            addCurrentSelectedSubtitles()
        }

        ChiefsPlayer.shared.player.play()
        
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
    var vWFullScale:NSLayoutConstraint!
    var dY:NSLayoutConstraint!
    var dH:NSLayoutConstraint!
    var vHPortrait:NSLayoutConstraint!
    var vHLandscape:NSLayoutConstraint!
    public func present(on viewController:UIViewController) {
        if parentVC != nil {
            print("Player is already presented")
            return
        }
        parentVC = viewController
                
        if Device.HAS_NOTCH {
            let notchFrame = CGRect(x: 0, y: 0,
                                    width: parentVC.view.bounds.width,
                                    height: screenSafeInsets.top)
            notchBackground = UIView(frame: notchFrame)
            notchBackground?.backgroundColor = .black
            parentVC.view.addSubview(notchBackground!)
        }

        detailsContainer.backgroundColor = .white
        parentVC.view.addSubview(detailsContainer)
        parentVC.view.addSubview(videoContainer)
        
        
        videoContainer.backgroundColor = UIColor.black
        
        addGestures()
                
        //Constraints
        //Assuming that always height is larger than width
        let dimensions = [parentVC.view.frame.width,parentVC.view.frame.height]
        let screenWidth = dimensions.min()!
        let screenHeight = dimensions.max()!
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
            .constraint(equalToConstant: parentVC.view.frame.width)
        vW.priority = .required
        vW.isActive = false
        // Width - where scale == 1
        /// This only used when video scale = 1
        /// Sometimes parentVC.view.frame.width not get updated as fast as needed when device rotated
        /// So I'm installing this constraint
        vWFullScale = videoContainer.widthAnchor
            .constraint(equalTo: parentVC.view.widthAnchor, multiplier: 1)
        vWFullScale.priority = .required
        vWFullScale.isActive = true
        
        let dW = detailsContainer.widthAnchor
            .constraint(equalTo: parentVC.view.widthAnchor, multiplier: 1)
        dW.isActive = true
        
        
        // Y
        
        vY = videoContainer.topAnchor
            .constraint(equalTo: parentVC.view.topAnchor)
        vY.constant = topSafeArea
        vY.isActive = true
        dY = detailsContainer.topAnchor
            .constraint(equalTo: videoContainer.bottomAnchor)
        dY.isActive = true
        
        //Height
        let spaceUnderVideo = screenHeight - screenWidth / configs.videoRatio.value
        dH = detailsContainer.heightAnchor
            .constraint(equalToConstant: spaceUnderVideo)
        dH.priority = .defaultHigh
        dH.isActive = true
        detailsContainer.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        // Ratios
        vHPortrait = videoContainer.heightAnchor
            .constraint(equalTo: videoContainer.widthAnchor,
                        multiplier: 1/configs.videoRatio.value,
                        constant: 1)
        vHPortrait.priority = .defaultLow
        vHPortrait.isActive = true
        
        vHLandscape = videoContainer.heightAnchor
            .constraint(equalToConstant: screenWidth)
        vHLandscape.priority = .defaultHigh
        vHLandscape.isActive = false
        
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
        
        
        if CControlsManager.shared.shouldShowControlsAboveVideo(for: UIDevice.current.orientation) {
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
        
        //player.pause()
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
        
        //Remove shared instance
        CControlsManager.shared._deinit()
        ChiefsPlayer.Static.instance = nil
        
        //Remove player after removing all observers and views
        self.player = nil
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
        //Set minimum video ratio
        if videoRatio > 2 {videoRatio = 2}
        //Disable current height constraint
        vHPortrait.isActive = false
        videoContainer.removeConstraint(vHPortrait)
        
        //Create new height constraint with new multiplier value
        vHPortrait = videoContainer.heightAnchor
            .constraint(
                equalTo: videoContainer.widthAnchor,
                multiplier: 1/videoRatio,
                constant: 1)
        vHPortrait.priority = .defaultLow
        vHPortrait.isActive = true
        
        //Details container height
        //Details height should be calculated with real intrface dimentions
        let dimentions = [screenWidth,screenHeight]
        let spaceUnderVideo = dimentions.max()! - dimentions.min()! / videoRatio
        dH.constant = spaceUnderVideo
        parentVC.view.layoutIfNeeded()
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
        var value:CGFloat?
        if #available(iOS 11.0, *) {
            if Device.HAS_NOTCH {
                value = UIApplication.shared.keyWindow?.safeAreaInsets.top
            }
        }
        return value ?? 0
    }
    public var bottomSafeArea:CGFloat = 0 {
        didSet {
            var newValue = bottomSafeArea
            if #available(iOS 11.0, *) {
                newValue += UIApplication.shared.keyWindow?
                    .safeAreaInsets.bottom ?? 0
            }
            bottomSafeArea = newValue
        }
    }
    let minimumScale  :CGFloat = 0.4
    var onMaxFrame:CGRect  = .zero
    var onTouchBeganFrame:CGRect  = .zero
    @objc func dragVideo (pan:UIPanGestureRecognizer) {
        if videoView.isFullscreen {
            return
        }
        
        if pan.state == UIGestureRecognizer.State.began {
            if acvStyle == .maximized {
                onMaxFrame = pan.view!.frame
            }
            onTouchBeganFrame = pan.view!.frame
        }
        
        if pan.state == UIGestureRecognizer.State.ended {
            if case ACVStyle.dismissing(let percent) = acvStyle {
                if percent > 0.3 {
                    dismiss()
                } else {
                    minimize()
                }
                return
            }
            
            let yFinger      = pan.location(in: parentVC.view).y
            let height       = parentVC.view.bounds.height
            
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
            
            if isDismissing || dismissingWillStart
            {
                let xTranslation = pan.translation(in: parentVC.view).x
                dismissView(with: xTranslation)
            } else {
                let yTranslation = pan.translation(in: parentVC.view).y
                minimizeView(with: yTranslation)
            }
        } else {
            // or something when its not moving
        }
    }
    func minimizeView (with yTranslation:CGFloat){
        let y = onTouchBeganFrame.minY + yTranslation
        
        //don't move videoView off of the screen
        if y < 0 {return}
        
        vY.constant = y
        
        //Scale
        setViewsScale()
        
        let movePercent = abs(vY.constant / (parentVC.view.frame.height - bottomSafeArea))
        acvStyle = .moving(movePercent)
    }
    func dismissView (with xTranslation:CGFloat){
        let x = onTouchBeganFrame.minX + xTranslation
        vX.constant = x

        let movePercent = abs(vX.constant / parentVC.view.frame.width)
        videoContainer.alpha = 1 - movePercent
        acvStyle = .dismissing(movePercent)
    }
    func setViewsScale () {
        if !Device.HAS_NOTCH {
            if vY.constant <= topSafeArea {
                delegate?.chiefsplayerStatusBarShouldBe(hidden: true)
            } else {
                delegate?.chiefsplayerStatusBarShouldBe(hidden: false)
            }
        }
        let lastY = (parentVC.view.frame.height - bottomSafeArea - topSafeArea) - minimumScale * onMaxFrame.height
        let movePercent = abs((vY.constant - topSafeArea) / lastY)
        let newScale = 1 - (movePercent * (1 - minimumScale))
        vW.constant = parentVC.view.frame.width * newScale
        dY.constant = bottomSafeArea * movePercent
        if newScale == 1, !vWFullScale.isActive {
            vWFullScale.isActive = true
            vW.isActive = false
        } else if newScale != 1, vWFullScale.isActive {
            vWFullScale.isActive = false
            vW.isActive = true
        }
        
        videoView.loadingView.setMinimize(with: movePercent)
        
        notchBackground?.alpha = 1 - movePercent * 6
        
        //If user is rotating device
        if lastRotate == UIDevice.current.orientation {
            videoView.setMinimize(with: movePercent)
        }
        
        //parentVC.view.setNeedsLayout()
        parentVC.view.layoutIfNeeded()
    }
    
    func maximize () {
        acvStyle = .maximized
        videoView.progressView.isUserInteractionEnabled = true
        let newdY:CGFloat = 0//isLandscape ? -ChiefsPlayer.shared.controls.frame.height : 0
        UIView.animate(
            withDuration: 0.15, delay: 0, options: [.curveEaseOut,.allowAnimatedContent,.allowUserInteraction],
            animations: {
                self.vY.constant = self.topSafeArea
                self.setViewsScale()
                self.parentVC.view.layoutIfNeeded()
                self.dY.constant = newdY
        }) { (done) in
            
        }
        
        delegate?.chiefsplayerMaximized()
    }
    public func minimize () {
        acvStyle = .minimized
        videoView.progressView.isUserInteractionEnabled = false
        let y = parentVC.view.bounds.height - bottomSafeArea - onMaxFrame.height * minimumScale
        UIView.animate(
            withDuration: 0.15, delay: 0, options: [.curveEaseOut,.allowAnimatedContent,.allowUserInteraction],
            animations: {
                self.vX.constant = 0
                self.videoContainer.alpha = 1
                self.vY.constant = y
                self.dY.constant = self.bottomSafeArea
                self.setViewsScale()
                self.parentVC.view.layoutIfNeeded()
        }) { (done) in
            
        }
        
        delegate?.chiefsplayerMinimized()
    }
    
    
    
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxx-- Rotation --xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    // If you do not use the notification var in your callback,
    // you can safely replace it with _
    var lastRotate:UIDeviceOrientation = UIDevice.current.orientation
    
}

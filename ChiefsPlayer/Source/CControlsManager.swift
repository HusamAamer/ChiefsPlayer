//
//  CControlsProtocol.swift
//  SuperCell
//
//  Created by Husam Aamer on 7/7/19.
//  Copyright © 2019 AppChief. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import GoogleCast

public typealias SeekActionBlock = (_ player:CAVQueuePlayer)->(SeekAction)
public typealias AccessoryViewsBlock = ()->([UIView])

public typealias CustomSeekActionIcon = UIImage

/// Seek Action determinse icon and action of the button, use `customPlay` for custom icon and then you can trigger custom code on `willTriggerAction = true`
public enum SeekAction {
    case
    play([CPlayerSource]),
    seek(Int),
    custom(CustomSeekActionIcon?)
}
public enum CastingService {
    case chromecast, airplay
}




public class CControlsManager:NSObject {
    //static var shared = CControlsManager()
    
    private struct Static
    {
        static var instance: CControlsManager?
    }
    
    class public var shared: CControlsManager
    {
        if Static.instance == nil
        {
            Static.instance = CControlsManager()
        }
        
        return Static.instance!
    }
    
    
    private var player : CAVQueuePlayer? {return ChiefsPlayer.shared.player}
    var delegates : [CControlsManagerDelegate?] = []
    var pipController : AVPictureInPictureController?
    var pipPossibleObservation : NSObject?
    
    override init() {
        super.init()
        
        setupPictureInPicture()
        startObserving()
    }
    var timeObserverToken:Any?
    func startObserving () {
        // Add time observer
        timeObserverToken =
            player?.addPeriodicTimeObserver(
                forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1),
                queue: DispatchQueue.main,
                using: { [weak self] (time) in
                    guard let `self` = self else {return}
                    
                    if let player = self.player {
                        let duration = AVCGlobalFuncs.timeFrom(seconds: player.currentTime())
                        let remaining = AVCGlobalFuncs.playerItemTimeRemainingString()
                        self.delegates.forEach({$0?.controlsTimeUpdated(to: duration, remaining: remaining, andPlayer: player.isPlaying)})
                    }
            })
    }
    func endPlayerObserving () {
        if let observer = timeObserverToken {
            player?.removeTimeObserver(observer)
        }
    }
    func _deinit () {
        delegates.removeAll()
        Static.instance = nil
    }
    
    
    
    deinit {
        print("CControlsManager deinit")
    }
    
    
    
    ////////////////////////////////////////////////////////////////
    // MARK:- Should show above video
    ////////////////////////////////////////////////////////////////
    func shouldShowControlsAboveVideo(in fullscreenMode:ACVFullscreen) -> Bool {
        return delegates.first??.controlsShouldAppearAboveVideo(in: fullscreenMode) ?? true
    }

    ////////////////////////////////////////////////////////////////
    // MARK:- Right / Left accessory buttons
    ////////////////////////////////////////////////////////////////
    public var leftButtons : AccessoryViewsBlock? {
        didSet {
            delegates.forEach({$0?.controlsLeftAccessoryViewsDidChange(to: leftButtons?())})
        }
    }
    public var rightButtons : AccessoryViewsBlock? {
        didSet {
            delegates.forEach({$0?.controlsRightAccessoryViewsDidChange(to: rightButtons?())})
        }
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Play/Pause btn
////////////////////////////////////////////////////////////////

extension CControlsManager {
    public enum PlayerState {
        case isPlaying, isPaused, Unknown
    }
    public func play () -> PlayerState {
        var out :PlayerState = .Unknown
        
        if ChiefsPlayer.shared.isCastingTo == .chromecast {
            let result = CChromecastRemoteControlFunctions.playPause()
            if result.Toggled, let isPlaying = result.NewStateIsPlaying {
                out = isPlaying ? .isPlaying : .isPaused
            }
        } else {
            
            if ChiefsPlayer.shared.isPlayerError {return .Unknown}
            if player?.isPlaying == true {
                player?.pause()
                out = .isPaused
            } else {
                player?.play()
                out = .isPlaying
            }
        }
        
        ///Tell observers about this change
        ///Depricated in 1.2.4, player rate observation used instead
        ///updateControlsPlayButton(to: out == .isPlaying)
        
        return out
    }
    /// Called when player status is changed
    /// - Parameter isPlaying: is playing media
    public func updateControlsPlayButton(to isPlaying:Bool) {
        /// Disable/Enable device sleep
        UIApplication.shared.isIdleTimerDisabled = isPlaying
        
        /// Update UI
        delegates.forEach({$0?.controlsPlayPauseChanged(to: isPlaying)})
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Next and prev btns
////////////////////////////////////////////////////////////////

extension CControlsManager {
    @discardableResult
    func nextBtnAction () -> Bool {
        if let action = ChiefsPlayer.shared.delegate?.chiefsplayerNextAction(true) {
            performAction(action: action)
        }
        return false
    }
    func prevBtnAction () {
        if let action = ChiefsPlayer.shared.delegate?.chiefsplayerPrevAction(true) {
            performAction(action: action)
        }
    }
    func forwardBtnAction () {
        if let action = ChiefsPlayer.shared.delegate?.chiefsplayerForwardAction(true) {
            performAction(action: action)
        }
    }
    func backwardBtnAction () {
        if let action = ChiefsPlayer.shared.delegate?.chiefsplayerBackwardAction(true) {
            performAction(action: action)
        }
    }
    
    
    func seek(seconds:Int) {
        if ChiefsPlayer.shared.isCastingTo == .chromecast {
            CChromecastRemoteControlFunctions.seek(by: seconds)
            return
        }
        if let current = player?.currentTime() {
            player?.seek(to: current + CMTime.init(seconds: Double(seconds), preferredTimescale: 1))
        }
    }
    func performAction (action:SeekAction) {
        switch action {
        case .custom(_):
            // Custom type is intended to be used to apply custom developer action outside of the ChiefsPlayer
            break
        case .play(let sourceArray):
            ChiefsPlayer.shared.play(from: sourceArray, with: nil)
            break
        case .seek(let seconds):
            // Cancel
            seek(seconds: seconds)
            break
        }
    }
}


////////////////////////////////////////////////////////////////
// MARK:- More Btn Action
////////////////////////////////////////////////////////////////
extension CControlsManager {
    func moreBtnAction (_ sender:UIView) {
        
        let subtitleAction = UIAlertAction(title: localized("change_subtitle_btn"),
                                           style: .default) { (alert) in
            DispatchQueue.main.asyncAfter( deadline: .now() + 0.3) {
                self.subtitleBtnAction(sender)
            }
        }
        
        let subtitleStyleAction = UIAlertAction(title: localized("change_subtitle_style_btn"),
                                           style: .default) { (alert) in
            DispatchQueue.main.asyncAfter( deadline: .now() + 0.3) {
                self.changeSubtitleStyleBtnAction(sender)
            }
        }
        
        let alertSheet = alert(
            title: nil,
            body: nil,
            cancel: localized("dismiss"),
            actions: [
                subtitleAction, subtitleStyleAction
            ],
            style: .actionSheet
        )
        if let presenter = alertSheet.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        ChiefsPlayer.shared.parentVC.present(alertSheet,
                                             animated: true,
                                             completion: nil)
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Delegate adding and deleting
////////////////////////////////////////////////////////////////

extension CControlsManager
{
    func addDelegate(_ observer:CControlsManagerDelegate)
    {
        for currentObs in self.delegates {
            if(observer.isEqual(currentObs))
            {
                //we don't want add again
                return
            }
        }
        
        self.delegates.append(observer)
        
        //Tell controller about current player info (resolutions, subtitles ... etc)
        update(controller: observer)
    }
    
    func removeDelegate(_ observer:CControlsManagerDelegate)
    {
        var observerIndex = -1
        for (index,currObserver) in self.delegates.enumerated() {
            if(observer.isEqual(currObserver)) {
                observerIndex = index
                break
            }
        }
        if(observerIndex != -1) {
            self.delegates.remove(at: observerIndex)
        }
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Subtitles
////////////////////////////////////////////////////////////////
extension CControlsManager {
    func updateAllControllers () {
        delegates.forEach({ [weak self] in
            if let observer = $0 {
                self?.update(controller: observer)
            }
        })
    }
    func update (controller observer:CControlsManagerDelegate) {
        let chiefsPlayer = ChiefsPlayer.shared
        
        observer.controlsLeftAccessoryViewsDidChange(to: leftButtons?())
        observer.controlsRightAccessoryViewsDidChange(to: rightButtons?())
        
        
        if let backwardAction = chiefsPlayer.delegate?.chiefsplayerBackwardAction(false) {
            observer.controlsBackwardActionDidChange(to: backwardAction)
        } else {
            observer.controlsBackwardActionDidChange(to: nil)
        }
        
        if let forwardAction = chiefsPlayer.delegate?.chiefsplayerForwardAction(false) {
            observer.controlsForwardActionDidChange(to: forwardAction)
        } else {
            observer.controlsForwardActionDidChange(to: nil)
        }
        
        if let backwardAction = chiefsPlayer.delegate?.chiefsplayerPrevAction(false) {
            observer.controlsPrevActionDidChange(to: backwardAction)
        } else {
            observer.controlsPrevActionDidChange(to: nil)
        }
        
        if let forwardAction = chiefsPlayer.delegate?.chiefsplayerNextAction(false) {
            observer.controlsNextActionDidChange(to: forwardAction)
        } else {
            observer.controlsNextActionDidChange(to: nil)
        }
        
        observer.controlsPlayer(has: chiefsPlayer.selectedSource.resolutions)
        observer.controlsPlayerDidChangeResolution(to: chiefsPlayer.selectedSource.resolutions[chiefsPlayer._selectedResolutionIndex])
        if let isPlaying = player?.isPlaying {
            observer.controlsPlayPauseChanged(to: isPlaying)
        }
        checkSubtitlesAvailability()
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Subtitle action
////////////////////////////////////////////////////////////////

extension CControlsManager
{
    private func changeSubtitleStyleBtnAction (_ sender:UIView) {
        
        // If can't change subtitle styel, then show change captions alert
        // else show two options (change style & change captions)
        if !canChangeSubtitleStyle {
            subtitleBtnAction(sender)
            return
        }
        
        
        let sizes : [(String,CGFloat)] = [
            ("subtitle_style.size.small" , 18),
            ("subtitle_style.size.medium" , 22),
            ("subtitle_style.size.large" , 25),
            ("subtitle_style.size.xlarge" , 29),
            ("subtitle_style.size.xxlarge" , 33)
        ]
        
        var actions = [UIAlertAction]()
        
        let currentSize = Subtitles.getFont().pointSize
        
        for (title, size) in sizes {
            let sizeAction = UIAlertAction(
                title: localized(title),
                style: .default) { (alert) in
                
                Subtitles.setFontSize(size)
                
            }
            if currentSize == size {
                sizeAction.setValue(true, forKey: "checked")
            }
            actions.append(sizeAction)
        }
        
        let alertSheet = alert(
            title: nil,
            body: nil,
            cancel: localized("dismiss"),
            actions: actions,
            style: .actionSheet
        )
        if let presenter = alertSheet.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        ChiefsPlayer.shared.parentVC.present(alertSheet,
                                             animated: true,
                                             completion: nil)
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Subtitle action
////////////////////////////////////////////////////////////////

extension CControlsManager
{
    ///Called when video is ready to play for the first time only
    private func checkSubtitlesAvailability () {
        //From manual srt import
        if let subs = ChiefsPlayer.shared.selectedSource.subtitles , subs.count > 0 {
            delegates.forEach({$0?.controlsSubtitles(are: true)})
            return
        }
        
        //From m3u8
        if let subs = player?.currentItem?
            .asset
            .mediaSelectionGroup(forMediaCharacteristic: .legible)
        {
            //Remove "cc" option if exist
            //"cc" is a strange option, It's not subtitle, I don't know what is it
            let options = subs.options.filter({$0.mediaType.rawValue != "clcp"})
            
            if options.count != 0 {
                player?.currentItem?.select(subs.options.first, in: subs) //Select first found subtitle
                delegates.forEach({$0?.controlsSubtitles(are: true)})
                return
            }
        }
        
        delegates.forEach({$0?.controlsSubtitles(are: false)})
    }
    
    
    var canChangeSubtitleStyle:Bool {
        
        // Only srt is styllable
        if let subs = ChiefsPlayer.shared.selectedSource.subtitles , subs.count > 0 {
            return true
        }
        return false
    }
    
    func subtitleBtnAction (_ sender:UIView) {
        
        ////////////////////////////////////////////////
        /// #From manual srt import
        ////////////////////////////////////////////////
        
        if let subs = ChiefsPlayer.shared.selectedSource.subtitles , subs.count > 0 {
            var actions = [UIAlertAction]()
            
            let selectedSubtitle = ChiefsPlayer.shared._selectedSubtitleIndex
            
            //Disable captions action
            let noCaptionsAction = UIAlertAction(
                title: localized("no_caption"),
                style: .default) { (_) in
                    ChiefsPlayer.shared._selectedSubtitleIndex = nil
                    ChiefsPlayer.shared.removeCurrentSubtitles()
                    CChromecastRemoteControlFunctions.subtitleDidChanged_srt()
                    //Tell Parent App
                    ChiefsPlayer.shared.delegate?
                    .chiefsplayerAttachedSubtitleChanged(to: nil, from: ChiefsPlayer.shared.selectedSource)
            }
            if selectedSubtitle == nil {
                noCaptionsAction.setValue(true, forKey: "checked")
            }
            actions.append(noCaptionsAction)
            
            //Available captions action
            for (thisIndex,sub) in subs.enumerated() {
                let action = UIAlertAction(
                    title: sub.title,
                    style: .default) { [thisIndex = thisIndex] (_) in
                        
                        ChiefsPlayer.shared._selectedSubtitleIndex = thisIndex
                        ChiefsPlayer.shared.open(fileFromRemote: sub.source)
                        CChromecastRemoteControlFunctions.subtitleDidChanged_srt()
                        //Tell Parent App
                        ChiefsPlayer.shared.delegate?
                        .chiefsplayerAttachedSubtitleChanged(to: sub, from: ChiefsPlayer.shared.selectedSource)
                        
                }
                if thisIndex == selectedSubtitle {
                    action.setValue(true, forKey: "checked")
                }
                actions.append(action)
            }
            
            //Present action sheet
            let a = alert(title: localized("pick_subtitle_title"), body: nil, cancel: localized("dismiss"), actions: actions, style: .actionSheet)
            if let presenter = a.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.bounds
            }
            ChiefsPlayer.shared.parentVC.present(a, animated: true, completion: nil)
            return
        }
        
        ////////////////////////////////////////////////
        /// #From m3u8
        ////////////////////////////////////////////////
        if let subs = player?.currentItem?
            .asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        {
            //            let filtered = AVMediaSelectionGroup.mediaSelectionOptions(from: subs.options, filteredAndSortedAccordingToPreferredLanguages: ["en","ar"])
            
            let selected = player?.currentItem?.selectedMediaOption(in: subs)
            var actions = [UIAlertAction]()
            
            //Disable captions action
            let noCaptionsAction = UIAlertAction(
                title: localized("no_caption"),
                style: .default) { (_) in
                    self.player?.currentItem?.select(nil, in: subs)
                    CChromecastRemoteControlFunctions.subtitleDidChanged_m3u8()
            }
            if selected == nil {
                noCaptionsAction.setValue(true, forKey: "checked")
            }
            actions.append(noCaptionsAction)
            
            //Available captions action
            for sub in subs.options {
                let action = UIAlertAction(
                    title: sub.displayName(with: Locale.current),
                    style: .default) { (_) in
                        
                        self.player?.currentItem?.select(sub, in: subs)
                        CChromecastRemoteControlFunctions.subtitleDidChanged_m3u8()
                }
                if sub == selected {
                    action.setValue(true, forKey: "checked")
                }
                actions.append(action)
            }
            
            //Present action sheet
            let a = alert(title: localized("pick_subtitle_title"), body: nil, cancel: localized("dismiss"), actions: actions, style: .actionSheet)
            if let presenter = a.popoverPresentationController {
                presenter.sourceView = sender
                presenter.sourceRect = sender.bounds
            }
            ChiefsPlayer.shared.parentVC.present(a, animated: true, completion: nil)
            
        }
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Fullscreen btn
////////////////////////////////////////////////////////////////
extension CControlsManager {
    func fullscreenBtnAction () {
        ChiefsPlayer.shared.toggleFullscreen()
        //ChiefsPlayer.shared.videoView.showFullscreenTutorial()
    }
    var isPortraitInterface : Bool {
        return screenHeight > screenWidth
    }
    
}


////////////////////////////////////////////////////////////////
// MARK:- Play/Pause btn
////////////////////////////////////////////////////////////////
extension CControlsManager {
    func reloadVideoInfo () {
        checkSubtitlesAvailability()
    }
}

////////////////////////////////////////////////////////////////
// MARK:- Toggle Aspect btn
////////////////////////////////////////////////////////////////
extension CControlsManager {
    func toggleVideoAspect () {
        ChiefsPlayer.shared.toggleVideoAspect()
    }
    
}

////////////////////////////////////////////////////////////////
// MARK:- Picture In Picture Btn
////////////////////////////////////////////////////////////////
extension CControlsManager: AVPictureInPictureControllerDelegate {
    var pipEnabled:Bool {
        return ChiefsPlayer.shared.delegate?.chiefsplayerPictureInPictureEnabled() == true
    }
    func setupPictureInPicture() {
        
        if !pipEnabled {
            return
        }
        
        // Ensure PiP is supported by current device.
        if AVPictureInPictureController.isPictureInPictureSupported() {
            
            // Create a new controller, passing the reference to the AVPlayerLayer.
            pipController = AVPictureInPictureController(playerLayer: ChiefsPlayer.shared.videoView.vLayer!)
            pipController?.delegate = self
            
            pipPossibleObservation =
                pipController?.observe(\AVPictureInPictureController.isPictureInPicturePossible,
                                                                        options: [.initial, .new]) { [weak self] _, change in
                // Update the PiP button's enabled state.
                self?.delegates.forEach({$0?.controlsPictureInPictureState(is: change.newValue ?? false)})
            }
        } else {
            // PiP isn't supported by the current device. Disable the PiP button.
            delegates.forEach({$0?.controlsPictureInPictureState(is: false)})
        }
    }
    
    @objc func togglePictureInPictureMode(_ sender: UIButton) {
        if pipController?.isPictureInPictureActive == true {
            pipController?.stopPictureInPicture()
        } else {
            pipController?.startPictureInPicture()
        }
    }
}


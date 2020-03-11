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
public enum SeekAction {
    case none, open(URL), seek(Int)
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
    
    
    private var player : CAVQueuePlayer {return ChiefsPlayer.shared.player}
    var delegates : [CControlsManagerDelegate?] = []
    
    override init() {
        super.init()
        startObserving()
    }
    var timeObserverToken:Any?
    func startObserving () {
        // Add time observer
        timeObserverToken =
            player.addPeriodicTimeObserver(
                forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1),
                queue: DispatchQueue.main,
                using: { [weak self] (time) in
                    guard let `self` = self else {return}
                    
                    let duration = AVCGlobalFuncs.timeFrom(seconds: self.player.currentTime())
                    let remaining = AVCGlobalFuncs.playerItemTimeRemainingString()
                    self.delegates.forEach({$0?.controlsTimeUpdated(to: duration, remaining: remaining, andPlayer: self.player.isPlaying)})
            })
    }
    func endPlayerObserving () {
        player.removeTimeObserver(timeObserverToken!)
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
    func shouldShowControlsAboveVideo(for deviceOrientation:UIDeviceOrientation) -> Bool {
        return delegates.first??.controlsShouldAppearAboveVideo(in: deviceOrientation) ?? true
    }
    ////////////////////////////////////////////////////////////////
    // MARK:- Forward / Backward actions
    ////////////////////////////////////////////////////////////////

    
    public var forwardAction : SeekActionBlock? {
        didSet {
            delegates.forEach({$0?.controlsForwardActionDidChange(to: forwardAction?(player))})
        }
    }
    public var backwardAction : SeekActionBlock? {
        didSet {
            delegates.forEach({$0?.controlsBackwardActionDidChange(to: backwardAction?(player))})
        }
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
            if player.isPlaying {
                player.pause()
                out = .isPaused
            } else {
                player.play()
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
    func nextBtnAction () {
        if let action = forwardAction?(player) {
            performAction(action: action)
        }
    }
    func prevBtnAction () {
        if let action = backwardAction?(player) {
            performAction(action: action)
        }
    }
    
    
    func seek(seconds:Int) {
        if ChiefsPlayer.shared.isCastingTo == .chromecast {
            CChromecastRemoteControlFunctions.seek(by: seconds)
            return
        }
        let current = player.currentTime()
        player.seek(to: current + CMTime.init(seconds: Double(seconds), preferredTimescale: 1))
    }
    func performAction (action:SeekAction) {
        switch action {
        case .open(let url):
            ChiefsPlayer.shared.reinitPlayer(with: url)
            break
        case .seek(let seconds):
            seek(seconds: seconds)
            break
        default:
            return
        }
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
        observer.controlsLeftAccessoryViewsDidChange(to: leftButtons?())
        observer.controlsRightAccessoryViewsDidChange(to: rightButtons?())
        observer.controlsBackwardActionDidChange(to: backwardAction?(player))
        observer.controlsForwardActionDidChange(to: forwardAction?(player))
        let chiefsPlayer = ChiefsPlayer.shared
        observer.controlsPlayer(has: chiefsPlayer.selectedSource.resolutions)
        observer.controlsPlayerDidChangeResolution(to: chiefsPlayer.selectedSource.resolutions[chiefsPlayer._selectedResolutionIndex])
        observer.controlsPlayPauseChanged(to: player.isPlaying)
        checkSubtitlesAvailability()
    }
    ///Called when video is ready to play for the first time only
    private func checkSubtitlesAvailability () {
        //From manual srt import
        if let subs = ChiefsPlayer.shared.selectedSource.subtitles , subs.count > 0 {
            delegates.forEach({$0?.controlsSubtitles(are: true)})
            return
        }
        
        //From m3u8
        if let subs = player.currentItem?
            .asset
            .mediaSelectionGroup(forMediaCharacteristic: .legible)
        {
            //Remove "cc" option if exist
            //"cc" is a strange option, It's not subtitle, I don't know what is it
            let options = subs.options.filter({$0.mediaType.rawValue != "clcp"})
            
            if options.count != 0 {
                player.currentItem?.select(subs.options.first, in: subs) //Select first found subtitle
                delegates.forEach({$0?.controlsSubtitles(are: true)})
                return
            }
        }
        
        delegates.forEach({$0?.controlsSubtitles(are: false)})
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
        if let subs = player.currentItem?
            .asset.mediaSelectionGroup(forMediaCharacteristic: .legible)
        {
            //            let filtered = AVMediaSelectionGroup.mediaSelectionOptions(from: subs.options, filteredAndSortedAccordingToPreferredLanguages: ["en","ar"])
            
            let selected = player.currentItem?.selectedMediaOption(in: subs)
            var actions = [UIAlertAction]()
            
            //Disable captions action
            let noCaptionsAction = UIAlertAction(
                title: localized("no_caption"),
                style: .default) { (_) in
                    self.player.currentItem?.select(nil, in: subs)
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
                        
                        self.player.currentItem?.select(sub, in: subs)
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
        print(screenWidth,screenHeight)
        if isPortraitInterface {
            forcelandscapeRight()
        } else {
            setPortrait()
        }
        NotificationCenter.default.post(name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    var isPortraitInterface : Bool {
        return screenHeight > screenWidth
    }
    func forcelandscapeRight() {
        let value:Int = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    func setPortrait() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
}


////////////////////////////////////////////////////////////////
// MARK:- Play/Pause btn
////////////////////////////////////////////////////////////////
extension CControlsManager {
    func reloadVidoInfo () {
        checkSubtitlesAvailability()
    }
}

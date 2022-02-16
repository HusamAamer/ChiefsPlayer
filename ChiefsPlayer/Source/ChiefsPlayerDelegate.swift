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

public protocol ChiefsPlayerDelegate:AnyObject {
    ///Called whene player get maximized or fullscreen
    func chiefsplayerStatusBarShouldBe (hidden:Bool)
    
    
    ///Called only once, when player state is ReadyToPlay for the first time
    func chiefsplayerReadyToPlay (_ item:CPlayerItem, resolution: CPlayerResolutionSource, from source:CPlayerSource)
    
    ///Called when user change resolution manually
    func chiefsplayerResolutionChanged (to resolution:CPlayerResolutionSource, from source:CPlayerSource)
    
    ///Called when user change subtitle manually. Not called for m3u8 subtitles
    func chiefsplayerAttachedSubtitleChanged (to subtitle:CPlayerSubtitleSource?, from source:CPlayerSource)
    
    ///Called on dismiss() or playing another video
    func chiefsplayerWillStop (playing item:CPlayerItem)
    
    ///Called periodically every when video is playing
    func chiefsplayer (isPlaying item:CPlayerItem, at second:Float, of totalSeconds:Float)
    
    func chiefsplayerAppeared ()
    func chiefsplayerDismissed()
    func chiefsplayerMaximized()
    func chiefsplayerMinimized()
    
    ///Called when video needs to be oriented
    func chiefsplayerOrientationChanged (to newOrientation:UIInterfaceOrientation, shouldLock:Bool, isMaximized:Bool)
    
    ///Called when player is streaming to airply or chromecast
    func chiefsplayer(isCastingTo castingService:CastingService?)
    
    ///Here you can apply any modification to source before casting starts
    func chiefsplayerWillStartCasting(from source:CPlayerSource) -> CPlayerSource?
    
    ///Optionaly write logs to firebase or other service for crash reporting
    func chiefsplayerDebugLog(_ string:String)
    
    /// Backward action, Return nil to hide backward button
    /// - Parameter willTriggerAction: a boolean value indicating thet action will be triggered now
    func chiefsplayerBackwardAction(_ willTriggerAction:Bool) -> CControlsManager.Action?
    
    /// Forward action, Return nil to hide forward button
    /// - Parameter willTriggerAction: a boolean value indicating thet action will be triggered now
    func chiefsplayerForwardAction(_ willTriggerAction:Bool) -> CControlsManager.Action?
    
    /// Previous action, Return nil to hide previous button
    /// - Parameter willTriggerAction: a boolean value indicating thet action will be triggered now
    func chiefsplayerPrevAction(_ willTriggerAction:Bool) -> CControlsManager.Action?
    
    /// Next action, Return nil to hide next button
    /// - Parameter willTriggerAction: a boolean value indicating thet action will be triggered now
    func chiefsplayerNextAction(_ willTriggerAction:Bool) -> CControlsManager.Action?
    
    /// Called when player has just entered one of the specified timelines passed, return an action
    /// if you need to perfrom a specific action.
    func chiefsPlayer(_ player: ChiefsPlayer, didEnterTimeline timeline: Timeline) -> CControlsManager.Action?
    
    /// Called when player has just exitted one of the specified timelines passed, return an action
    /// if you need to perfrom a specific action.
    func chiefsPlayer(_ player: ChiefsPlayer, didExitTimeline timeline: Timeline) -> CControlsManager.Action?
    
    func chiefsplayerPictureInPictureEnabled() -> Bool
}

//Make functions optional
public extension ChiefsPlayerDelegate {
    func chiefsplayerStatusBarShouldBe (hidden:Bool) {}
    func chiefsplayerWillStart (playing item:CPlayerItem) {}
    func chiefsplayerReadyToPlay (_ item:CPlayerItem, resolution: CPlayerResolutionSource, from source:CPlayerSource) {}
    func chiefsplayerResolutionChanged (to resolution:CPlayerResolutionSource, from source:CPlayerSource) {}
    func chiefsplayerAttachedSubtitleChanged (to subtitle:CPlayerSubtitleSource?, from source:CPlayerSource) {}
    func chiefsplayerWillStop (playing item:CPlayerItem) {}
    func chiefsplayer (isPlaying item:CPlayerItem, at second:Float, of totalSeconds:Float) {}
    func chiefsplayerAppeared () {}
    func chiefsplayerDismissed() {}
    func chiefsplayerMaximized() {}
    func chiefsplayerMinimized() {}
    func chiefsplayerOrientationChanged (to newOrientation:UIInterfaceOrientation) {}
    func chiefsplayer(isCastingTo castingService:CastingService?){}
    func chiefsplayerWillStartCasting(from source:CPlayerSource) -> CPlayerSource? { return nil}
    func chiefsplayerDebugLog(_ string:String) {}
    func chiefsplayerBackwardAction(_ willTriggerAction:Bool) -> CControlsManager.Action? {return nil}
    func chiefsplayerForwardAction(_ willTriggerAction:Bool) -> CControlsManager.Action?  {return nil}
    func chiefsplayerPrevAction(_ willTriggerAction:Bool) -> CControlsManager.Action? {return nil}
    func chiefsplayerNextAction(_ willTriggerAction:Bool) -> CControlsManager.Action? {return nil}
    
    func chiefsplayerPictureInPictureEnabled() -> Bool {return false}
}

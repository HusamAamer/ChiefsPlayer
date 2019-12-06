//
//  CChromecastRemoteControlFunctions.swift
//  Giganet
//
//  Created by Husam Aamer on 8/28/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import GoogleCast
import AVFoundation
class CChromecastRemoteControlFunctions: NSObject {
    static var castedMediaInformation:GCKMediaInformation? { return  GCKCastContext.sharedInstance()
        .sessionManager
        .currentCastSession?
        .remoteMediaClient?
        .mediaStatus?
        .mediaInformation
    }
    static var castedMediaDuration:TimeInterval? { return CChromecastRemoteControlFunctions
        .castedMediaInformation?
        .streamDuration
    }
    static var castedMediaStreamPosition:TimeInterval? {
        return CChromecastRemoteControlFunctions
        .remote?
        .mediaStatus?
        .streamPosition
    }
    
    static var remote : GCKRemoteMediaClient? {
        get {
            return GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        }
    }
    
    
    static func seek (by seconds:Int) {
        let seekOptions = GCKMediaSeekOptions()
        seekOptions.interval = Double(seconds)
        seekOptions.relative = true
        remote?.seek(with: seekOptions)
    }
    
    static func seek (to interval:TimeInterval) {
        let seekOptions = GCKMediaSeekOptions()
        seekOptions.interval = Double(interval)
        remote?.seek(with: seekOptions)
    }
    
//    static func seek (to percent:CGFloat) {
//        remote?.seek(with: seekOptions)
//    }
    typealias PlayToggleResult = (Toggled:Bool,NewStateIsPlaying:Bool?)
    static func playPause () -> PlayToggleResult {
        guard let state = remote?.mediaStatus?.playerState else {return (false,nil)}
        switch state {
        case GCKMediaPlayerState.playing:
            remote?.pause()
            return (true,false)
        case GCKMediaPlayerState.paused:
            remote?.play()
            return (true,true)
        default:
            return (false,nil)
        }
    }
    
    static var canChangeProgress: Bool {
        guard let _ = remote?.mediaStatus?.playerState else {return false}
        if remote?.mediaStatus?.isMediaCommandSupported(kGCKMediaCommandSeek) == false {
            return false
        }
        return true
    }
    @objc static func updateProgressUI() {
        guard let media = remote?.mediaStatus else {
            return
        }
        var playerDuration : TimeInterval!
        if let duration = AVCGlobalFuncs.playerItemDuration() {
            playerDuration = duration
            
        } else {
            //If duration is unknown then set current time as duration
            playerDuration = CMTimeGetSeconds(ChiefsPlayer.shared.player.currentTime())
            
        }
        var duration = CGFloat(playerDuration)
        if duration.isNaN || duration.isInfinite {duration = 0} //Happens when user is on error only
        
        ChiefsPlayer.shared.videoView.progressView.progressBar.progress = CGFloat(media.streamPosition / playerDuration)
        
    }
}

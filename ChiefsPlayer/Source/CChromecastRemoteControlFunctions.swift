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
internal class CChromecastRemoteControlFunctions: NSObject {
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
        //Because the function is static, call might be done even if the player was smashed
        if ChiefsPlayer.shared.player == nil {return}
        
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
    
    /**
     # This is a print of `CChromecastRemoteControlFunctions.castedMediaInformation?.mediaTracks` for certian rich m3u8 file
     
     [
     <0x1103dd220: GCKMediaTrack; id = 1, content-id = (null), content-type = video/mp2t, type = 3, subtype = 0, name = '(null)', lang = (null)>,
     <0x1103e9760: GCKMediaTrack; id = 2, content-id = (null), content-type = audio/mp4, type = 2, subtype = 0, name = 'BipBop Audio 2', lang = eng>,
     <0x11032d2e0: GCKMediaTrack; id = 3, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = 'English', lang = en>,
     <0x1103f9150: GCKMediaTrack; id = 4, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = 'English (Forced)', lang = en>,
     <0x1103e57b0: GCKMediaTrack; id = 5, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = 'Français', lang = fr>,
     <0x1103bfa70: GCKMediaTrack; id = 6, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = 'Français (Forced)', lang = fr>,
     <0x1103e7190: GCKMediaTrack; id = 7, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = 'Español', lang = es>,
     <0x1103f4f80: GCKMediaTrack; id = 8, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = 'Español (Forced)', lang = es>,
     <0x11030acd0: GCKMediaTrack; id = 9, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = '日本語', lang = ja>,
     <0x1103d0540: GCKMediaTrack; id = 10, content-id = (null), content-type = text/vtt, type = 1, subtype = 0, name = '日本語 (Forced)', lang = ja>]
     **/
    static func subtitleDidChanged_m3u8 () {
        DispatchQueue.main.async {
            guard let currentItem = ChiefsPlayer.shared.player.currentItem else {return}
            guard let subs = currentItem
                .asset
                .mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
            
            guard let option = currentItem.currentMediaSelection
                .selectedMediaOption(in: subs) else { return }
            
            guard let index = subs.options.firstIndex(of: option) else { return }
            
            guard let mediaTracks = CChromecastRemoteControlFunctions.castedMediaInformation?.mediaTracks else {
                return
            }
            
            let vttTracks = mediaTracks.filter({$0.type == .text})
            if index < vttTracks.count {
                let vttTrack = vttTracks[index]
                GCKCastContext.sharedInstance()
                    .sessionManager
                    .currentSession?
                    .remoteMediaClient?
                    .setActiveTrackIDs([NSNumber(integerLiteral:vttTrack.identifier)])
            }
        }
    }
    static func subtitleDidChanged_srt () {
        
    }
}

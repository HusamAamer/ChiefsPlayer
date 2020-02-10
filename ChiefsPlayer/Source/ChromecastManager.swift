//
//  ChromecastManager.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 8/28/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import GoogleCast
import AVFoundation


extension ChiefsPlayer {
    /// To use google cast app
    /// add app id as value to key `ChiefsPlayerChromecastAppID` in info.plist
    private static let appId : String? = Bundle.main.infoDictionary?["ChiefsPlayerChromecastAppID"] as? String
    
    /// Initialize Google Cast SDK before using player to reduce player launch delay
    /// and discover devices before launching player
    static public func initializeChromecastDiscovery() {
        var castOptions : GCKCastOptions!
        if let appId = appId, !appId.isEmpty {
            let discoveryCriteria = GCKDiscoveryCriteria(applicationID: appId)
            castOptions = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        } else {
            let discoveryCriteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
            castOptions = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        }
        GCKCastContext.setSharedInstanceWith(castOptions)
    }
}



class ChromecastManager: NSObject {
    private var sharedPlayer   = ChiefsPlayer.shared
    private var sessionManager : GCKSessionManager!
    private var castSession    : GCKCastSession? {
        get {return sessionManager?.currentCastSession}
    }
    private var progressTimer  : Timer?
    
    override init() {
        super.init()
        
        if !GCKCastContext.isSharedInstanceInitialized() {
            ChiefsPlayer.initializeChromecastDiscovery()
        }
        
        #if DEBUG
        GCKLogger.sharedInstance().delegate = self
        #endif
        sessionManager = GCKCastContext.sharedInstance().sessionManager
        sessionManager.add(self)
    }
    
    
    func startCastingCurrentItem () {
        
        let selectedSource = ChiefsPlayer.shared.selectedSource
        let modifiedSource = ChiefsPlayer.shared.delegate?.chiefsplayerWillStartCasting(from: selectedSource)
        
        let selectedResolution = (modifiedSource ?? selectedSource).resolutions[ChiefsPlayer.shared._selectedResolutionIndex]
        
        let toPlayUrl = selectedResolution.source_m3u8 ?? selectedResolution.source_file!
        
        /// Check if url is local
        if toPlayUrl.absoluteString.hasPrefix("file://") {
            showAlert(withTitle: "Error", message: "Local content could not be streamed to Chromecast")
            self.castSession?.end(with: .stopCasting)
            return
        }
        
        var subtitleTracks:[GCKMediaTrack]?
        if let subs = selectedSource.subtitles {
            subtitleTracks = []
            for (index,sub) in subs.enumerated() {
                
                /// Check if url is local
                if sub.source.absoluteString.hasPrefix("file://") {
                    continue
                }
                
                let track = GCKMediaTrack(
                    identifier: index + 1,
                    contentIdentifier: sub.source.absoluteString,
                    contentType: "text/vtt",
                    type: .text,
                    textSubtype: .subtitles,
                    name: sub.title,
                    languageCode: "ar",
                    customData: nil)
                subtitleTracks?.append(track)
            }
        }
        
        let media = mediaInfo(with: selectedResolution.source_m3u8 ?? selectedResolution.source_file!,
                              and: subtitleTracks,
                              and: modifiedSource?.metadata)
        load(media: media, byAppending: false)
        
        //Listen to controls
        castSession?.remoteMediaClient?.add(self)
    }
    func end (andStopCasting:Bool) {
        progressTimer?.invalidate()
        sharedPlayer.isCastingTo = nil
        
        if andStopCasting {
            sessionManager.endSessionAndStopCasting(true)
        }
    }
    
    
    deinit {
        sessionManager.remove(self)
        progressTimer?.invalidate()
        print("Chromecast Manager deinit")
    }
    
    
    func showAlert(withTitle title: String, message: String) {
        let a = alert(title: title, body: message, cancel: localized("dismiss"))
        ChiefsPlayer.shared.parentVC.present(a, animated: true, completion: nil)
    }
}
extension ChromecastManager: GCKLoggerDelegate {
    func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        print("Message from Chromecast at level = \(level.rawValue) \n Function:\(function) \n Message:\(message) \n Location: \(location)")
    }
}

// MARK: - GCKSessionManagerListener
extension ChromecastManager: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        sharedPlayer.isCastingTo = .chromecast
        
        startCastingCurrentItem()
    }
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print("didResumeCastSession")
        
//        let urls = sharedPlayer.mediaQueue.map({$0.url})
//        if let firstURL = urls.first {
//            print(session.remoteMediaClient)
//            print(session.remoteMediaClient?.mediaStatus)
//            print(session.remoteMediaClient?.mediaStatus?.mediaInformation)
//            print(session.remoteMediaClient?.mediaStatus?.mediaInformation?.contentID)
//          print(session.remoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration)
//
//            print(session.remoteMediaClient?.queueFetchItemIDs())
//            if session.remoteMediaClient?.mediaStatus?.mediaInformation?.contentID
//                == firstURL.absoluteString {
//                sharedPlayer.isCastingTo = .chromecast
//
//                self.castSession = session as? GCKCastSession
//
//                //Listen to controls
//                session.remoteMediaClient?.add(self)
//            }
//        }
    }
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        print("didResumeSession")
//        print(session.remoteMediaClient)
//        print(session.remoteMediaClient?.mediaStatus)
//        print(session.remoteMediaClient?.mediaStatus?.mediaInformation)
//        print(session.remoteMediaClient?.mediaStatus?.mediaInformation?.contentID)
//        print(session.remoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration)
//        print(session.remoteMediaClient?.queueFetchItemIDs())
    }
    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        end(andStopCasting: false)
    }
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
                
        if error == nil {
            //if let view = UIApplication.shared.keyWindow?.rootViewController?.view {
                //Toast.displayMessage("Session ended", for: 3, in: view)
            //}
        } else {
            let message = "Session ended unexpectedly:\n\(error?.localizedDescription ?? "")"
            showAlert(withTitle: "Session error", message: message)
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        let message = "Failed to start session:\n\(error.localizedDescription)"
        showAlert(withTitle: "Session error", message: message)
        end(andStopCasting: true)
    }
    
}










extension ChromecastManager {
    func mediaInfo(with mediaURL:URL,
                   and mediaTracks:[GCKMediaTrack]?,
                   and metadata:CPlayerMetadata? = nil) -> GCKMediaInformation
    {
        
        let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaURL)
        mediaInfoBuilder.streamType = GCKMediaStreamType.buffered;
        mediaInfoBuilder.contentID = mediaURL.absoluteString
        
        if mediaURL.absoluteString.contains("m3u8") {
            mediaInfoBuilder.contentType = "videos/m3u8"
        } else {
            mediaInfoBuilder.contentType = "videos/mp4"
        }
        
        
        let gckMetadata = GCKMediaMetadata.init(metadataType: .movie)
        
        if let metadata = metadata {
            //Set title
            gckMetadata.setString(metadata.title, forKey: kGCKMetadataKeyTitle)
            
            //Set image
            if let metadataImage = metadata.image {
                gckMetadata.addImage(GCKImage(url: metadataImage, width: 50, height: 100))
                
            }
            
            //Set description
            if let desc = metadata.description {
                gckMetadata.setString(desc, forKey: kGCKMetadataKeyDiscNumber)
            }
        }
        
        mediaInfoBuilder.metadata = gckMetadata
        mediaInfoBuilder.mediaTracks = mediaTracks;
        
        return mediaInfoBuilder.build()
    }
}


extension ChromecastManager {
    
    /**
     * Loads the currently selected item in the current cast media session.
     * @param appending If YES, the item is appended to the current queue if there
     * is one. If NO, or if
     * there is no queue, a new queue containing only the selected item is created.
     */
    
    func load(media: GCKMediaInformation, byAppending appending: Bool) {
        if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
            let builder = GCKMediaQueueItemBuilder()
            builder.mediaInformation = media
            builder.autoplay = true

            //builder.preloadTime = TimeInterval(UserDefaults.standard.integer(forKey: kPrefPreloadTime))
            let item = builder.build
            let playPosition = TimeInterval(sharedPlayer.player.currentItem?.currentTime().asFloat ?? 0)
            if (remoteMediaClient.mediaStatus != nil) && appending {
                let request = remoteMediaClient.queueInsertAndPlay(item(), beforeItemWithID: kGCKMediaQueueInvalidItemID, playPosition: playPosition, customData: nil)
                request.delegate = self
            } else {
                let repeatMode = remoteMediaClient.mediaStatus?.queueRepeatMode ?? .off
                let options = GCKMediaQueueLoadOptions()
                options.startIndex = 0
                options.playPosition = playPosition
                options.repeatMode = repeatMode

                let builder = GCKMediaQueueItemBuilder()
                builder.mediaInformation = media
                builder.autoplay = true
                builder.preloadTime = 3
                let item = builder.build

                let request = remoteMediaClient.queueLoad([item()], with: options)
                request.delegate = self
            }
        }
        
//        if let remoteMediaClient = sessionManager.currentCastSession?.remoteMediaClient {
//          let mediaQueueItemBuilder = GCKMediaQueueItemBuilder()
//          mediaQueueItemBuilder.mediaInformation = media
//          mediaQueueItemBuilder.autoplay = true
//          mediaQueueItemBuilder.preloadTime = 3
//          let mediaQueueItem = mediaQueueItemBuilder.build()
//          if appending {
//            let request = remoteMediaClient.queueInsert(mediaQueueItem, beforeItemWithID: kGCKMediaQueueInvalidItemID)
//            request.delegate = self
//          } else {
//            let queueDataBuilder = GCKMediaQueueDataBuilder(queueType: .generic)
//            queueDataBuilder.items = [mediaQueueItem]
//            queueDataBuilder.repeatMode = remoteMediaClient.mediaStatus?.queueRepeatMode ?? .off
//
//            let mediaLoadRequestDataBuilder = GCKMediaLoadRequestDataBuilder()
//            mediaLoadRequestDataBuilder.queueData = queueDataBuilder.build()
//
//            let request = remoteMediaClient.loadMedia(with: mediaLoadRequestDataBuilder.build())
//            request.delegate = self
//          }
//        }
    }
}


extension ChromecastManager : GCKRequestDelegate {
    func requestDidComplete(_ request: GCKRequest) {
        print("request \(Int(request.requestID)) completed")
        
        if progressTimer != nil {
            progressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateProgressUI), userInfo: nil, repeats: true)
        }
        
        guard let currentItem = sharedPlayer.player.currentItem else {return}
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //If m3u8
        ///////////////////////////////////////
        if let subs = currentItem
            .asset
            .mediaSelectionGroup(forMediaCharacteristic: .legible)
        {
            if let option = currentItem
                .currentMediaSelection
                .selectedMediaOption(in: subs)
            {
                if let index = subs.options.firstIndex(of: option) {
                    
                    sessionManager
                        .currentSession?
                        .remoteMediaClient?
                        .setActiveTrackIDs([NSNumber(integerLiteral:index + 2)])
                    
                }
            }
        }
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //If mp4
        ///////////////////////////////////////
        else if let subtitleIndex = ChiefsPlayer.shared._selectedSubtitleIndex {
            
            sessionManager
            .currentSession?
            .remoteMediaClient?
            .setActiveTrackIDs([NSNumber(integerLiteral: subtitleIndex + 1)])
        }
    }
    
    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        print("request \(Int(request.requestID)) failed with error \(error)")
        let errorMessage = """
        "Message": \(error.localizedDescription)
        "Reason": \(error.localizedFailureReason ?? "Unknown")
        "Suggestion": \(error.localizedRecoverySuggestion ?? "No suggestion")
        "Error Code": \(error.code)
        """
        showAlert(withTitle: "Casting failed", message: errorMessage)
        
        end(andStopCasting: true)
    }
    @objc func updateProgressUI () {
        CChromecastRemoteControlFunctions.updateProgressUI()
        
        let fullTime = CChromecastRemoteControlFunctions.castedMediaDuration ?? 0
        let streamPosition = CChromecastRemoteControlFunctions.castedMediaStreamPosition ?? 0
        
        
        // Assuming player is playing
        let playerIsPlaying = true
        let duration = AVCGlobalFuncs.timeFrom(seconds: streamPosition)
        let remaining = "-" + AVCGlobalFuncs.timeFrom(seconds: fullTime - streamPosition)
        CControlsManager.shared.delegates.forEach({$0?.controlsTimeUpdated(to: duration, remaining: remaining, andPlayer: playerIsPlaying)})
        
    }
}



extension ChromecastManager:GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
        print(#function,sessionID)
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceive queueItems: [GCKMediaQueueItem]) {
        print(#function,queueItems)
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        
        guard let state = mediaStatus?.playerState else {return}
        switch state {
        case GCKMediaPlayerState.playing:
            CControlsManager.shared.delegates.forEach({$0?.controlsPlayPauseChanged(to:true)})
            break
        case GCKMediaPlayerState.paused:
            CControlsManager.shared.delegates.forEach({$0?.controlsPlayPauseChanged(to:false)})
            break
        default:
            return
        }
    }
    func remoteMediaClientDidUpdatePreloadStatus(_ client: GCKRemoteMediaClient) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceiveQueueItemIDs queueItemIDs: [NSNumber]) {
        
    }
}

//
//  CPlayerItem.swift
//  ChiefsPlayer
//
//  Created by Husam Aamer on 2/10/20.
//  Copyright © 2020 AppChief. All rights reserved.
//

import AVFoundation

public class CPlayerItem: AVPlayerItem {
    private var isObserving = false
    public var delegate:CPlayerItemDelegate? {
        didSet {
            if delegate == nil {
                stopObserving()
            } else {
                startObserving()
            }
        }
    }

    private var paths: [String] {
        return [
            "playbackLikelyToKeepUp",
            "playbackBufferEmpty",
            "playbackBufferFull",
            //#keyPath(player.status),
            #keyPath(status),
            #keyPath(error)
        ]
    }
    
    
    func startObserving () {
        if !isObserving {
            paths.forEach({
                addObserver(self,
                            forKeyPath: $0,
                            options: [.initial,.new],
                            context: nil)
            })
            
            NotificationCenter.default
                .addObserver(
                    self,
                    selector: #selector(playerItemDidPlayToEndTime(_:)),
                    name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                    object: self)

            
            isObserving = true
        }
    }
    func stopObserving () {
        if isObserving {
            for path in paths {
                removeObserver(self, forKeyPath: path)
            }
            
            NotificationCenter.default
                .removeObserver(self,
                                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                object: self)
            
            delegate?.cplayerItemWillStopObserving()
            isObserving = false
        }
    }
    
    deinit {
        debugPrint(">>>>>> Will be deinited")
        stopObserving()
        ChiefsPlayer.Log(event: "Item deinited")
        debugPrint(">>>>>> Item deinited")
    }
    
    /// Called if error happened or player ended
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        if let userInfo = notification.userInfo,
            let error = userInfo["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? NSError
        {
            ChiefsPlayer.Log(event: "\(#function)")
            delegate?.cplayerItemError(error)
        } else {
            delegate?.cplayerItemDidPlayToEndTime()
        }
    }
    @objc func playerError (error:NSError) {
        ChiefsPlayer.Log(event: "\(#function) \(error.localizedDescription)")
        delegate?.cplayerItemError(error)
    }
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?) {
        
        debugPrint("\(#function) -> \(keyPath)")
        in_main { [weak self] in
            
            guard let `self` = self else {return}
            
            let delegate = self.delegate
            
            if keyPath == #keyPath(error) {
                ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) (ItemError)")
                if let error = self.error {
                    delegate?.cplayerItemError(error)
                }
                
            } else
            if keyPath == #keyPath(status) {
                ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) ItemStatus = \(self.status.rawValue)")
                
                // FAILED
                if self.status == .failed {
                    delegate?.cplayerItemFailed()
                }
                
                // READY TO PLAY
                else if self.status == .readyToPlay {
                    delegate?.cplayerItemReadyToPlay()
                }
            }
            
            if keyPath == "playbackBufferEmpty" {
                if self.isPlaybackBufferEmpty {
                    delegate?.cplayerItemPlayebackBufferEmpty()
                    
                    ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) (playbackBufferEmpty)")
                }
            }
            else if keyPath == "playbackBufferFull" {
                if self.isPlaybackBufferFull {
                    delegate?.cplayerItemPlaybackBufferFull()
                    
                    ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) (playbackBufferFull)")
                }
            }
            else if keyPath == "playbackLikelyToKeepUp" {
                if self.isPlaybackLikelyToKeepUp {
                    delegate?.cplayerItemPlaybackLikelyToKeepUp()
                    ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) (playbackLikelyToKeepUp)")
                }
            }
        }
    }
}

public protocol CPlayerItemDelegate:class {
    func cplayerItemReadyToPlay ()
    func cplayerItemFailed()
    func cplayerItemPlaybackLikelyToKeepUp()
    func cplayerItemPlaybackBufferFull()
    func cplayerItemPlayebackBufferEmpty()
    func cplayerItemError(_ error:Error)
    func cplayerItemDidPlayToEndTime()
    func cplayerItemWillStopObserving()
}

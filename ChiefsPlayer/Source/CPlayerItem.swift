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

    @objc var player : AVPlayer? {
        return ChiefsPlayer.shared.player
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
                    object: nil)

            
            isObserving = true
        }
    }
    @objc func stopObserving () {
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
        ChiefsPlayer.Log(event: "Item will be deinited")
        //performSelector(onMainThread: #selector(stopObserving), with: self, waitUntilDone: true)
        stopObserving()
        ChiefsPlayer.Log(event: "Item deinited")
    }
    
    /// Called if error happened or player ended
    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        in_main {
            if let userInfo = notification.userInfo,
                let error = userInfo["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? NSError
            {
                ChiefsPlayer.Log(event: "\(#function) + ERROR")
                self.delegate?.cplayerItemError(error)
            } else {
                ChiefsPlayer.Log(event: "\(#function) + SUCCESS")
                self.delegate?.cplayerItemDidPlayToEndTime()
            }
        }
    }
    override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?) {
        
        in_main { [weak self] in
            
            guard let `self` = self else {return}
            
            let delegate = self.delegate
            
            if keyPath == #keyPath(error) {
                if let error = self.error {
                    ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) (ItemError)")
                    delegate?.cplayerItemError(error)
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
            } else if keyPath == "status" {
                if self.status == .readyToPlay {
                    delegate?.cplayerItemReadyToPlay()
                }
            }
        }
    }
}

public protocol CPlayerItemDelegate:class {
    func cplayerItemReadyToPlay()
    func cplayerItemPlaybackLikelyToKeepUp()
    func cplayerItemPlaybackBufferFull()
    func cplayerItemPlayebackBufferEmpty()
    func cplayerItemError(_ error:Error)
    func cplayerItemDidPlayToEndTime()
    /// This might be called in background thread from deinit function
    func cplayerItemWillStopObserving()
}

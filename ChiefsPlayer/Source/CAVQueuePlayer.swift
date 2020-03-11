//
//  CPlayerItem.swift
//  ChiefsPlayer
//
//  Created by Husam Aamer on 2/10/20.
//  Copyright © 2020 AppChief. All rights reserved.
//

import AVFoundation

public class CAVQueuePlayer: AVQueuePlayer {
    public var delegate:CAVQueuePlayerDelegate?
    var isObserving = false
    private var paths: [String] {
        return [
            #keyPath(status),
            #keyPath(rate)
        ]
    }
    
    public convenience init(with items: [AVPlayerItem]) {
        self.init(items: items)
    }
    public override func replaceCurrentItem(with item: AVPlayerItem?) {
        stopObserving()
        super.replaceCurrentItem(with: item)
        if item != nil {
            startObserving()
            delegate?.cavqueueplayerItemReplaced(with:item)
        }
    }
    deinit {
        ChiefsPlayer.Log(event: "CAVQueuePlayer will be deinited")
        stopObserving()
        ChiefsPlayer.Log(event: "CAVQueuePlayer deinited")
    }
    
    func startObserving () {
        isObserving = true
        ChiefsPlayer.Log(event: "CAVQueuePlayer \(#function)")
        paths.forEach({
            addObserver(self,
                        forKeyPath: $0,
                        options: [.new,.initial],
                        context: nil)
        })
    }
    func stopObserving () {
        if isObserving {
            isObserving = false
            ChiefsPlayer.Log(event: "CAVQueuePlayer \(#function)")
            for path in paths {
                removeObserver(self, forKeyPath: path)
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
            
            if keyPath == #keyPath(status) {
                ChiefsPlayer.Log(event: "\(#function) -> Line \(#line) PlayerStatus = \(self.status.rawValue)")
                
                // FAILED
                if self.status == .failed {
                    delegate?.cavqueueplayerFailed()
                }
                
                // READY TO PLAY
                else if self.status == .readyToPlay {
                    delegate?.cavqueueplayerReadyToPlay()
                }
            }
            
            if keyPath == #keyPath(rate) {
                print(self.rate)
                delegate?.cavqueueplayerPlayingStatus(is: self.rate == 1)
            }
        }
    }
}

public protocol CAVQueuePlayerDelegate:class {
    func cavqueueplayerReadyToPlay ()
    func cavqueueplayerFailed()
    func cavqueueplayerItemReplaced(with item:AVPlayerItem?)
    func cavqueueplayerPlayingStatus(is playing:Bool)
}

//
//  CAVQueuePlayer.swift
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
			#keyPath(rate),
			#keyPath(volume),
			#keyPath(isMuted)
		]
	}
	
	public convenience init(with items: [AVPlayerItem]) {
		self.init(items: items)
		startObserving()
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
		stopObserving()
	}
	
	func startObserving () {
		isObserving = true
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
					
					// FAILED
					if self.status == .failed {
						delegate?.cavqueueplayerFailed()
					}
					
					// READY TO PLAY
					else if self.status == .readyToPlay {
						delegate?.cavqueueplayerReadyToPlay()
					}
				}
				
				else if keyPath == #keyPath(rate) {
					delegate?.cavqueueplayerPlayingStatus(is: self.rate == 1)
				}
				
				else if keyPath == #keyPath(volume) {
					if let newValue = change?[.newKey] as? Float {
						delegate?.cavqueueplayerVolumeChanged(to: newValue)
					}
				}
				
				else if keyPath == #keyPath(isMuted) {
					if let newValue = change?[.newKey] as? Bool {
						delegate?.cavqueueplayerMuted(newValue)
					}
				}
			}
		}
}

public protocol CAVQueuePlayerDelegate:AnyObject {
	func cavqueueplayerReadyToPlay ()
	func cavqueueplayerFailed()
	func cavqueueplayerItemReplaced(with item:AVPlayerItem?)
	func cavqueueplayerPlayingStatus(is playing:Bool)
	func cavqueueplayerVolumeChanged(to volumn:Float)
	func cavqueueplayerMuted(_ muted:Bool)
}

extension CAVQueuePlayerDelegate {
	public func cavqueueplayerVolumeChanged(to volumn:Float) {}
	public func cavqueueplayerMuted(_ muted:Bool) {}
}

## ChiefsPlayer
Advanced floating player with streaming services.


### Changelog

v1.5
- Better fullscreen support for iPad
- Update code to Swift 5
- Many fixes and improvements
- New icons for fullscreen and aspect size

v1.4.2
- Moved from flipping icons for RTL programmatically to the asset attribute option called `Direction` 

v1.4.1
- New Feature: Resize Video Gesture with pinch in and out
- Fix a bug where next/prev btn are off screen in small devices for youtube style

v1.4
- New subtitle resize options for srt subtitles
- Improved seeking by progress bar  
- New `tintColor` in configuration
- Fix minimze action when called programmatically

v1.3.3
- Fix modified chromecast source issue, where modiefied source captions was ignored. 

v1.3.2
- Fix an issue where `CControlsManager.endPlayerObserving()` causes a crash.

v1.3.1
- Ignore playing presention if passed resolution index was empty, and use index = 0 if passed resolution index was out of range.    
- replacing `func chiefsplayerReadyToPlay (_ resolution: CPlayerResolutionSource, from source:CPlayerSource)` with `func chiefsplayerReadyToPlay (_ item:CPlayerItem, resolution: CPlayerResolutionSource, from source:CPlayerSource)`
- deprecating of `func chiefsplayerWillStart (playing item:CPlayerItem)`

v1.3
- Next, Prev, Forward and Backward separated buttons with all needed delegate methods.  
- Automatically hides over player controls after 2 secs  
- New delegate methods for events where user changes resolution or subtitle  
- Automatically trigger next button action (If delegate available) if player ended playing current item instead of showing retry button
- New custom seek action.

	func chiefsplayerForwardAction(_ willTriggerAction: Bool) -> SeekAction? {
		 if willTriggerAction {
		     present(alert(title: "hoho", body: nil, cancel: nil), animated: true, completion: nil)
		 }
		 return .custom(nil)
	}


v1.2.3
- Support for mirroring device screen to AirPlay  
> Previous versions are not logged  

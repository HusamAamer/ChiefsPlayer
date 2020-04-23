## ChiefsPlayer
Advanced floating player with streaming services.


### Changelog

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

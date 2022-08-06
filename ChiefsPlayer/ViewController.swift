//
//  ViewController.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 11/11/19.
//  Copyright © 2019 AppChief. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		ChiefsPlayer.initializeChromecastDiscovery()
	}
	
	
	var resolutions : [CPlayerResolutionSource] {
		let localVideo = Bundle.main.path(forResource: "sample", ofType: "mp4")
		let localVideoURL = URL(fileURLWithPath: localVideo!)
		let resoultion = CPlayerResolutionSource(title: "Local file", localVideoURL)
		
		let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!
		let resoultion1 = CPlayerResolutionSource(title: "Remote m3u8 + Subs", url)
		
		let url2 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/ForBiggerBlazes.m3u8")!
		let resoultion2 = CPlayerResolutionSource(title: "ForBiggerBlazes m3u8", url2)
		
		let url3 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/DesigningForGoogleCast.mp4")!
		let resoultion3 = CPlayerResolutionSource(title: "Designing... mp4", url3)
		
		let url4 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/DesigningForGoogleCast.m3u8")!
		let resoultion4 = CPlayerResolutionSource(title: "Designing... m3u8", url4)
		
		return [resoultion,resoultion4,resoultion1,resoultion2,resoultion3]
	}
	
	
	var metaData:CPlayerMetadata {
		let metaData = CPlayerMetadata(title: "Chiefs Player",
									   image: URL(string: "https://scontent.fbgt1-2.fna.fbcdn.net/v/t1.0-9/28660963_1654832364585296_985124833228488704_n.png?_nc_cat=104&_nc_ohc=_Mzc7IU8FBsAX8F5yFe&_nc_ht=scontent.fbgt1-2.fna&oh=0dfaf144a15eab6997c208b015d0241e&oe=5EBC83EC"),
									   description: "Description here")
		return metaData
	}
	
	
	var sources : [CPlayerSource] {
		
		let sources = [CPlayerSource(resolutions: resolutions,
									 subtitles: nil,
									 metadata: metaData, timelines: [
										Timeline(id: "ID1", startTime: 5, endTime: 10),
										Timeline(id: "ID2", startTime: 10, endTime: 20)
									 ])]
		return sources
	}
	
	
	var sourcesWithLocalSubtitle : [CPlayerSource] {
		//Local subtitle
		let subtitleFile = Bundle.main.path(forResource: "sample", ofType: "srt")
		let localSubtitleURL = URL(fileURLWithPath: subtitleFile!)
		
		let localSubtitle = CPlayerSubtitleSource(title: "Local url", source: localSubtitleURL)
		let subtitleSources = [localSubtitle]
		
		let sources = [CPlayerSource(resolutions: resolutions,
									 subtitles: subtitleSources,
									 metadata: metaData)]
		return sources
	}
	var sourcesWithRemoteSubtitle : [CPlayerSource] {
		//Remote subtitle
		let subtitleURL = URL(string: "https://raw.githubusercontent.com/andreyvit/subtitle-tools/master/sample.srt")!
		
		let remoteSubtitle = CPlayerSubtitleSource(title: "Remote url", source: subtitleURL)
		let subtitleSources = [remoteSubtitle]
		
		let sources = [CPlayerSource(resolutions: resolutions,
									 subtitles: subtitleSources,
									 metadata: metaData)]
		return sources
	}
	@IBAction func youtubeStylePlayer(_ sender: Any) {
		let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
		testV.backgroundColor = .darkGray
		
		playVideo(with: sources, and: testV, with: .youtube)
		
		CControlsManager.shared.leftButtons = {
			return [UIButton(type: .contactAdd)]
		}
		CControlsManager.shared.rightButtons = {
			return [UIButton(type: .detailDisclosure)]
		}
	}
	@IBAction func barStylePlayer(_ sender: Any) {
		let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
		testV.backgroundColor = .gray
		
		playVideo(with: sources, and: testV, with: .barStyle)
		
		CControlsManager.shared.leftButtons = {
			let btn = UIButton(type: .contactAdd)
			return [
				btn
			]
		}
		CControlsManager.shared.rightButtons = {
			return [UIButton(type: .detailDisclosure)]
		}
		
	}
	
	@IBAction func withLocalSubtitleAction(_ sender: Any) {
		let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
		testV.backgroundColor = .green
		playVideo(with: sourcesWithLocalSubtitle, and: testV, with: .barStyle)
	}
	
	@IBAction func withRemoteSubtitleAction(_ sender: Any) {
		let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
		testV.backgroundColor = .green
		playVideo(with: sourcesWithRemoteSubtitle, and: testV, with: .barStyle)
	}
	
	//////////////////////////////////////////////////////////////////
	/// Private: Play any thing
	//////////////////////////////////////////////////////////////////
	
	fileprivate func playVideo (with sources:[CPlayerSource],
								and detailsView:UIView? = nil,
								with style:CVConfiguration.ControlsStyle)
	{
		//Playing another video without changing the details view
		if detailsView == nil {
			ChiefsPlayer.shared.play(from: sources, with: nil, startWithResoultionAt: 100)
		} else {
			//let table = MovieVideoDetails(frame: .zero, style: .plain)
			let player = ChiefsPlayer.shared
			
			player.delegate = self
			player.configs.controlsStyle = style
			player.configs.videoRatio = .widescreen
			player.configs.progressBarStyle.showsLivePanDuration = true
			player.configs.tintColor = .red
			//player.configs.minimizeBackgroundColor = .black
			//player.configs.maximizedBackgroundColor = .darkGray
			//player.configs.onMinimizedAdditionalBottomSafeArea = 20
			//player.bottomSafeArea = tabBar.frame.height - screenSafeInsets.bottom
			
			player.play(from: sources, with: detailsView, startWithResoultionAt: 100)
			
			//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
			ChiefsPlayer.shared.present(on: self.navigationController!)
			//            }
			
		}
		
		
		//Customizing player colors temporarely
		//        ChiefsPlayer.shared.controls.backgroundColor = Colors.background
		//        ChiefsPlayer.shared.controls.separator.backgroundColor = Colors.separator
		//        ChiefsPlayer.shared.controls.play.setBackgroundImage(UIImage.init(named: "PlayButtonBackground"), for: .normal)
		//        ChiefsPlayer.shared.controls.play.gradientColors = []
	}
	
	var statusBarShouldBeHidden = false {
		didSet {
			UIView.animate(withDuration: 0.4) {
				self.setNeedsStatusBarAppearanceUpdate()
			}
		}
	}
	override var prefersStatusBarHidden: Bool {
		return statusBarShouldBeHidden
	}
}

extension ViewController:ChiefsPlayerDelegate {
	func chiefsPlayer(_ player: ChiefsPlayer, didEnterTimeline timeline: Timeline) -> CControlsManager.Action? {
		// Asynchronous skip button action
		//        .skip(title: timeline.id, timeline: timeline) { completion in
		//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
		//                completion(.seekBy(5))
		//            }
		//        }
		
		// Synchronous skip button action
		//        if timeline.id == "ID2" {
		//            return .seekBy(30)
		//        }
		//
		return .showButton(withTitle: "Skip \(timeline.id)", action: .seekBy(5))
	}
	
	func chiefsPlayer(_ player: ChiefsPlayer, didExitTimeline timeline: Timeline) -> CControlsManager.Action? {
		return .hideButton
	}
	
	func chiefsplayerAppeared() {
		AppUtility.lockOrientation(.all)
	}
	func chiefsplayerDismissed() {
		AppUtility.lockOrientation([.portraitUpsideDown,.portrait])
	}
	func chiefsplayerMinimized() {
		AppUtility.lockOrientation([.portraitUpsideDown,.portrait])
	}
	func chiefsplayerMaximized() {
		AppUtility.lockOrientation(.all)
	}
	func chiefsplayerOrientationChanged(to newOrientation: UIInterfaceOrientation, shouldLock: Bool, isMaximized:Bool) {
		
		if shouldLock {
			let mask = UIInterfaceOrientationMask.landscape
			AppUtility.lockOrientation(mask)
			print("OO","landscape")
		} else if isMaximized {
			print("OO","all")
			AppUtility.lockOrientation(.all)
		} else {
			print("OO","portrait")
			AppUtility.lockOrientation(.portrait)
		}
	}
	func chiefsplayerResolutionChanged(to resolution: CPlayerResolutionSource, from source: CPlayerSource) {
		//print(resolution,source)
	}
	func chiefsplayerAttachedSubtitleChanged(to subtitle: CPlayerSubtitleSource?, from source: CPlayerSource) {
		//print(subtitle,source)
	}
	func chiefsplayerBackwardAction(_ willTriggerAction: Bool) -> CControlsManager.Action? {
		return .seekBy(-8)
	}
	func chiefsplayerReadyToPlay(_ item: CPlayerItem, resolution: CPlayerResolutionSource, from source: CPlayerSource) {
		
	}
	
	/**
	 EXAMPLE OF USING CUSTOM SEEK ACTION
	 
	 func chiefsplayerForwardAction(_ willTriggerAction: Bool) -> SeekAction? {
	 if willTriggerAction {
	 present(alert(title: "hoho", body: nil, cancel: nil), animated: true, completion: nil)
	 }
	 return .custom(nil)
	 }
	 
	 */
	func chiefsplayerForwardAction(_ willTriggerAction: Bool) -> CControlsManager.Action? {
		return .seekBy(10)
	}
	func chiefsplayerNextAction(_ willTriggerAction: Bool) -> CControlsManager.Action? {
		//return nil
		return .play([CPlayerSource(resolutions: [resolutions.last!], timelines: [
			Timeline(id: "ID1", startTime: 5, endTime: 10),
			Timeline(id: "ID2", startTime: 10, endTime: 20)
		])])
	}
	func chiefsplayerPrevAction(_ willTriggerAction: Bool) -> CControlsManager.Action? {
		//return nil
		return .play([CPlayerSource(resolutions: [resolutions.last!])])
	}
	func chiefsplayerWillStartCasting(from source: CPlayerSource) -> CPlayerSource? {
		
		return nil
		
	}
	func chiefsplayer(isCastingTo castingService: CastingService?) {
		//let service = castingService == nil ? "Not casting" : "\(castingService!)"
	}
	
	func chiefsplayerStatusBarShouldBe(hidden: Bool) {
		print("OOOO",hidden)
		statusBarShouldBeHidden = hidden
	}
	
	func chiefsplayerPictureInPictureEnabled() -> Bool {
		return true
	}
	
	//    func chiefsplayerWillStop(playing item: AVPlayerItem) {
	//        //guard
	//        //    let left = item.currentTime().asFloat,
	//        //    let duration = item.duration.asFloat else {
	//        //        return
	//        //}
	//        //let per  = left / duration
	//        //print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
	//        //print(left,per)
	//        //RealmManager.userFinishedWatching(playingShowId!, leftAt: left,and: per)
	//        //print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
	//
	//    }
	//    func chiefsplayerWillStart(playing item: AVPlayerItem) {
	//        guard let rm = playingRmContinue else {return}
	//        item.seek(to: CMTime(seconds: Double(rm.left_at), preferredTimescale: 1), completionHandler: nil)
	//
	//    }
	//    func chiefsplayer(isPlaying item: AVPlayerItem, at second: Float, of totalSeconds: Float) {
	//        guard let rm = playingRmContinue else {
	//            return
	//        }
	//        let perc = second / totalSeconds
	//        RealmManager.updateWatchingProgress(for: rm, leftAt: Int(second), and: perc)
	//    }
	//    func chiefsplayerAppeared() {
	//        AppUtility.lockOrientation(.all)
	//    }
	//    func chiefsplayerDismissed() {
	//        AppUtility.lockOrientation([.portraitUpsideDown,.portrait])
	//    }
	//    func chiefsplayerMinimized() {
	//        AppUtility.lockOrientation([.portraitUpsideDown,.portrait])
	//    }
	//    func chiefsplayerMaximized() {
	//        AppUtility.lockOrientation(.all)
	//    }
	//    func chiefsplayerOrientationChanged(to newOrientation: UIInterfaceOrientation) {
	//        //AppUtility.lockOrientation([.landscapeLeft,.portrait])
	//        if newOrientation == .landscapeLeft || newOrientation == .landscapeRight {
	//            homeIndicatorShouldBeHidden = true
	//        } else {
	//            homeIndicatorShouldBeHidden = false
	//        }
	//
	//        if #available(iOS 11.0, *) {
	//            setNeedsUpdateOfHomeIndicatorAutoHidden()
	//            setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
	//        } else {
	//            // Fallback on earlier versions
	//        }
	//    }
}

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
        
        
        
//        let url_1 = URL(string: "")!
//        let resoultion1_1 = CPlayerResolutionSource(title: "SC m3u8", url_1)
//
//        let url_2 = URL(string: "")!
//        let resoultion1_2 = CPlayerResolutionSource(title: "SC Mp4", url_2)
        
        
        
//        let urlyt1 = URL(string: "https://cinema.shoofnetwork.net:8099/ad4962a3-0bd6-4a8b-a3cb-e29e66ab6e5b/PWIZCBbQttBP8Mu/PWIZCBbQttBP8Mu_1080.mp4")!
//        let shoof = CPlayerResolutionSource(title: "Shoof Movie", urlyt1)
		
		let urlyt1 = URL(string: "http://stream.giganet.iq:6066/enter/ch2/adaptive.m3u8")!
		let shoof = CPlayerResolutionSource(title: "4:3 Giganet channel", urlyt1)
	
        let urlyt2 = URL(string: "https://r1---sn-x5guiapo3uxax-cbfe7.googlevideo.com/videoplayback?expire=1582147998&ei=PlVNXr21C9Ok8gPIm7voBg&ip=37.237.70.32&id=o-ADMfJS7GP1d1zHkYdCYecspWqCxFOK04uudo6qrI5TWW&itag=18&source=youtube&requiressl=yes&mm=31,29&mn=sn-x5guiapo3uxax-cbfe7,sn-4g5ednsz&ms=au,rdu&mv=m&mvi=0&pl=24&initcwndbps=316250&vprv=1&mime=video/mp4&gir=yes&clen=234454050&ratebypass=yes&dur=4319.143&lmt=1540295945090483&mt=1582126270&fvip=1&fexp=23842630&c=WEB&txp=5531432&sparams=expire,ei,ip,id,itag,source,requiressl,vprv,mime,gir,clen,ratebypass,dur,lmt&lsparams=mm,mn,ms,mv,mvi,pl,initcwndbps&lsig=AHylml4wRQIgfQDWGgdm2pdLQxdKvbH2pWudGIDErttetvW42CFRwqQCIQDXm94QMH2UPezBrypOjuDODmASg4FaQ-ozJvHrezvXfg==&sig=ALgxI2wwRQIhAOBYp0w2hmUWmQBDtAQtoSPOR6sSns7t1tPXAcmlGXd0AiAC4Z4TQgeowt81p61zTdqlFYh2SXzfrGHA0e8b_hkGxg==")!
        let resoultion_yt2 = CPlayerResolutionSource(title: "720", urlyt2)
        
        
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!
        let resoultion1 = CPlayerResolutionSource(title: "Remote m3u8 + Subs", url)
        
        let url2 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/ForBiggerBlazes.m3u8")!
        let resoultion2 = CPlayerResolutionSource(title: "ForBiggerBlazes m3u8", url2)
        
        let url3 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/DesigningForGoogleCast.mp4")!
        let resoultion3 = CPlayerResolutionSource(title: "Designing... mp4", url3)
        
        let url4 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/DesigningForGoogleCast.m3u8")!
        let resoultion4 = CPlayerResolutionSource(title: "Designing... m3u8", url4)
        
        
        let url5 = URL(string: "https://cndw1.shabakaty.com/mp4-480/F0FE6644-F0DE-3820-CEF5-956AE1E8D50A_video.mp4?response-content-disposition=attachment%3B%20filename%3D%22Attack%20on%20Titan.mp4%22&AWSAccessKeyId=RNA4592845GSJIHHTO9T&Expires=1617052547&Signature=x%2FZltTaCZ6l%2FYAzVcQ8j1D7KuG8%3D")!
        let cinemanaSource = CPlayerResolutionSource(title: "Cinemana mp4", url5)
        
        
        //return [resoultion,resoultion,resoultion,resoultion,resoultion,resoultion,resoultion,resoultion]
        
        return [shoof, resoultion ,cinemanaSource,resoultion_yt2,resoultion4,resoultion1,resoultion2,resoultion3]
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
                                     metadata: metaData)]
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
    func chiefsplayerBackwardAction(_ willTriggerAction: Bool) -> SeekAction? {
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
    func chiefsplayerForwardAction(_ willTriggerAction: Bool) -> SeekAction? {
        return .seekBy(10)
    }
    func chiefsplayerNextAction(_ willTriggerAction: Bool) -> SeekAction? {
        //return nil
        return .play([CPlayerSource(resolutions: [resolutions.last!])])
    }
    func chiefsplayerPrevAction(_ willTriggerAction: Bool) -> SeekAction? {
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

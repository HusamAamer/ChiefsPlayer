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
    
    
    var sources : [CPlayerSource] {
        let localVideo = Bundle.main.path(forResource: "sample", ofType: "mp4")
        let localVideoURL = URL(fileURLWithPath: localVideo!)
        let resoultion = CPlayerResolutionSource(title: "Local file", localVideoURL)
        
        let url = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!
        let resoultion1 = CPlayerResolutionSource(title: "Remote m3u8", url)
        
        let url2 = URL(string: "http://stream.shabakaty.com:6001/sport/ch2/adaptive.m3u8")!
        let resoultion2 = CPlayerResolutionSource(title: "BEIN", url2)
        
        //https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4
        let url3 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/DesigningForGoogleCast.mp4")!
        let resoultion3 = CPlayerResolutionSource(title: "Remote mp4", url3)
        
        let url4 = URL(string: "https://cndw2.shabakaty.com/m480/93F44BD4-6458-9302-3082-70A81BB5B472_video.mp4?response-content-disposition=attachment%3B%20filename%3D%22video.mp4%22&AWSAccessKeyId=RNA4592845GSJIHHTO9T&Expires=1581455750&Signature=lIi0iLXGqnVFsfcJlS%2B5Mxl%2BUig%3D")!
        let resoultion4 = CPlayerResolutionSource(title: "1917 movie mp4", url4)
        
        //Remote subtitle
        let subtitleURL = URL(string: "https://raw.githubusercontent.com/andreyvit/subtitle-tools/master/sample.srt")!
        
        //Local subtitle
        let subtitleFile = Bundle.main.path(forResource: "sample", ofType: "srt")
        let localSubtitleURL = URL(fileURLWithPath: subtitleFile!)
        
        let remoteSubtitle = CPlayerSubtitleSource(title: "Remote url", source: subtitleURL)
        let localSubtitle = CPlayerSubtitleSource(title: "Local url", source: localSubtitleURL)
        let subtitleSources = [localSubtitle,remoteSubtitle]
        let sources = [CPlayerSource(resolutions: [resoultion4,resoultion,resoultion1,resoultion2,resoultion3],
                                     subtitles: subtitleSources)]
        return sources
    }
    @IBAction func youtubeStylePlayer(_ sender: Any) {
        let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        testV.backgroundColor = .darkGray
        
        playVideo(with: sources, and: testV, with: .youtube)
        CControlsManager.shared.backwardAction = { _ in
            return SeekAction.seek(-5)
            //                return SeekAction.open(URL(string:server + "/gen.php")!)
        }
        CControlsManager.shared.forwardAction = { _ in
            return SeekAction.seek(5)
            //                return SeekAction.open(URL(string:server + "/gen.php")!)
        }
    }
    @IBAction func barStylePlayer(_ sender: Any) {
        let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        testV.backgroundColor = .gray
        
        playVideo(with: sources, and: testV, with: .barStyle)
        CControlsManager.shared.backwardAction = { _ in
            return SeekAction.seek(-5)
            //                return SeekAction.open(URL(string:server + "/gen.php")!)
        }
        CControlsManager.shared.forwardAction = { _ in
            return SeekAction.seek(5)
            //                return SeekAction.open(URL(string:server + "/gen.php")!)
        }
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
            ChiefsPlayer.shared.play(from: sources, with: nil)
        } else {
            //let table = MovieVideoDetails(frame: .zero, style: .plain)
            let player = ChiefsPlayer.shared
            player.delegate = self
            player.play(from: sources, with: detailsView)
            //player.bottomSafeArea = tabBar.frame.height - screenSafeInsets.bottom
            player.configs.controlsStyle = style
            player.configs.videoRatio = .widescreen
            CControlsManager.shared.backwardAction = { _ in
                return SeekAction.seek(-5)
                //return SeekAction.open(URL(string:server + "/gen.php")!)
            }
            CControlsManager.shared.forwardAction = { _ in
                return SeekAction.seek(5)
                //return SeekAction.open(URL(string:server + "/gen.php")!)
            }
            player.present(on: self.navigationController!)
        }
        
        
        //Customizing player colors temporarely
//        ChiefsPlayer.shared.controls.backgroundColor = Colors.background
//        ChiefsPlayer.shared.controls.separator.backgroundColor = Colors.separator
//        ChiefsPlayer.shared.controls.play.setBackgroundImage(UIImage.init(named: "PlayButtonBackground"), for: .normal)
//        ChiefsPlayer.shared.controls.play.gradientColors = []
    }
}

extension ViewController:ChiefsPlayerDelegate {
//    func chiefsplayer(isCastingTo castingService: CastingService?) {
//        let service = castingService == nil ? "Not casting" : "\(castingService!)"
//        FABLog(event: "Casting to : \(service)")
//
//        if castingService == .airplay {
//            FBSDKSet(userProperty: 1, name: .hasAppleTV)
//        } else if castingService == .chromecast {
//            FBSDKSet(userProperty: 1, name: .hasChromecast)
//        }
//    }
//
//    func chiefsplayerStatusBarShouldBe(hidden: Bool) {
//        statusBarShouldBeHidden = hidden
//    }
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

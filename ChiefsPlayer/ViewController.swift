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
        
        
        
//        let url_1 = URL(string: "")!
//        let resoultion1_1 = CPlayerResolutionSource(title: "SC m3u8", url_1)
//
//        let url_2 = URL(string: "")!
//        let resoultion1_2 = CPlayerResolutionSource(title: "SC Mp4", url_2)
        
        
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!
        let resoultion1 = CPlayerResolutionSource(title: "Remote m3u8 + Subs", url)
        
        let url2 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/ForBiggerBlazes.m3u8")!
        let resoultion2 = CPlayerResolutionSource(title: "ForBiggerBlazes m3u8", url2)
        
        let url3 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/mp4/DesigningForGoogleCast.mp4")!
        let resoultion3 = CPlayerResolutionSource(title: "Designing... mp4", url3)
        
        let url4 = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/DesigningForGoogleCast.m3u8")!
        let resoultion4 = CPlayerResolutionSource(title: "Designing... m3u8", url4)
        
        //Remote subtitle
        let subtitleURL = URL(string: "https://raw.githubusercontent.com/andreyvit/subtitle-tools/master/sample.srt")!
        
        //Local subtitle
        let subtitleFile = Bundle.main.path(forResource: "sample", ofType: "srt")
        let localSubtitleURL = URL(fileURLWithPath: subtitleFile!)
        
        let remoteSubtitle = CPlayerSubtitleSource(title: "Remote url", source: subtitleURL)
        let localSubtitle = CPlayerSubtitleSource(title: "Local url", source: localSubtitleURL)
        let subtitleSources = [localSubtitle,remoteSubtitle]
        
        let metaData = CPlayerMetadata(title: "Chiefs Player",
                                       image: URL(string: "https://scontent.fbgt1-2.fna.fbcdn.net/v/t1.0-9/28660963_1654832364585296_985124833228488704_n.png?_nc_cat=104&_nc_ohc=_Mzc7IU8FBsAX8F5yFe&_nc_ht=scontent.fbgt1-2.fna&oh=0dfaf144a15eab6997c208b015d0241e&oe=5EBC83EC"),
                                                  description: "Description here")
        let sources = [CPlayerSource(resolutions: [resoultion4,resoultion1,resoultion,resoultion2,resoultion3],
                                     subtitles: nil,
                                     metadata: metaData)]
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

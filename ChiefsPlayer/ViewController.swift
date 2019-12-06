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

        // Do any additional setup after loading the view.
    }
    @IBAction func playBtn(_ sender: Any) {
        let testV = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        
        let url = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!
        let resoultion = CPlayerResolutionSource(title: "Title", source: url)
        
        let url2 = URL(string: "http://stream.shabakaty.com:6001/sport/ch2/adaptive.m3u8")!
        let resoultion2 = CPlayerResolutionSource(title: "Title", source: url2)
        
        //Remote subtitle
        let subtitleURL = URL(string: "https://raw.githubusercontent.com/andreyvit/subtitle-tools/master/sample.srt")!
        
        //Local subtitle
        let subtitleFile = Bundle.main.path(forResource: "sample", ofType: "srt")
        let localSubtitleURL = URL(fileURLWithPath: subtitleFile!)
        
        let remoteSubtitle = CPlayerSubtitleSource(title: "Remote url", source: subtitleURL)
        let localSubtitle = CPlayerSubtitleSource(title: "Local url", source: localSubtitleURL)
        let subtitleSources = [remoteSubtitle,localSubtitle]
        let sources = [CPlayerSource(resolutions: [resoultion2,resoultion],
                                     subtitles: subtitleSources)]

            
            playVideo(with: sources, and: testV)
            CControlsManager.shared.backwardAction = { _ in
                return SeekAction.seek(-5)
                //                return SeekAction.open(URL(string:server + "/gen.php")!)
            }
            CControlsManager.shared.forwardAction = { _ in
                return SeekAction.seek(5)
                //                return SeekAction.open(URL(string:server + "/gen.php")!)
            }
    }
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
        
    }

    //////////////////////////////////////////////////////////////////
    /// Private: Play any thing
    //////////////////////////////////////////////////////////////////
    fileprivate func playVideo (with sources:[CPlayerSource],and detailsView:UIView? = nil)
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
            player.configs.controlsStyle = .barStyle
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

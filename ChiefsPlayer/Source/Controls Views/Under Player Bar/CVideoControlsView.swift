//
//  ACVideoPlayer.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 3/24/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import MediaPlayer
import GoogleCast

class CVideoControlsView: CBaseControlsView {
    
    @IBOutlet weak var rightStack: UIStackView!
    
    @IBOutlet weak private var nextButton: UIButton!
    @IBOutlet weak private var playButton: UIButton!
    @IBOutlet weak private var prevButton: UIButton!
    @IBOutlet weak var subtitlesBtn: UIButton!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var resolutionBtn: UIButton!
    var play: UIRoundedButton!
    var separator:UIView!
    
    class func instanceFromNib() -> CVideoControlsView {
        return super.instanceFromNib(with: "CVideoControlsView")
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor(red:0.13, green:0.16, blue:0.24, alpha:1.00)
        separator = UIView()
        
        
    }
    
    //Init UI
    override func awakeFromNib() {
        
        subtitlesBtn.isHidden = true
        resolutionBtn.isHidden = true
        
        
        currentTime.text = nil
        duration.text = nil
        
        
        let gradients = [
            UIColor(red: 253/255, green: 90/255, blue: 148/255, alpha: 1),
            UIColor(red: 134/255, green: 65/255, blue: 163/255, alpha: 1)
        ]
        play = UIRoundedButton(gradientColors: gradients)
        play.setImage(UIImage.make(name: "pause-1"), for: .normal)
        play.setImage(UIImage.make(name: "play-1"), for: .selected)
        play.addTarget(self, action: #selector(playBtn(_:)), for: .touchUpInside)
        play.frame = CGRect(x: 0, y: 0, width: 47, height: 47)
        play.center = playButton.center
        play.autoresizingMask = [.flexibleTopMargin,.flexibleLeftMargin,.flexibleRightMargin,.flexibleBottomMargin]
        addSubview(play)
        
        
        // Add bottom decoration
        let sepHeight:CGFloat = 2
        separator.frame.size = CGSize(width: frame.width - 30, height: sepHeight)
        addSubview(separator)
        separator.backgroundColor = UIColor(red:0.20, green:0.22, blue:0.31, alpha:1.00)
        separator.autoresizingMask = [.flexibleTopMargin,.flexibleWidth]
        separator.center = CGPoint(x: frame.width/2, y: frame.height - sepHeight/2)
        
        //play.isSelected = !player.isPlaying
        
        //Setup AirPlay button
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            if let castButton = self.castButton {
//                castButton.tintColor = UIColor.white
//                castButton.alpha = 0.6
//                self.rightStack.insertArrangedSubview(castButton, at: 0)
//            }
//        }
        
        if let airView = airView {
            airView.sizeToFit()
            airView.tintColor = UIColor.white
            airView.alpha = 0.6
            rightStack.insertArrangedSubview(airView, at: 0)
        }
        if Device.IS_IPAD {
            fullscreenBtn.isHidden = true
        }
        
        CControlsManager.shared.addDelegate(self)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let sv = superview {
            if sv is UIStackView {
                heightAnchor.constraint(equalToConstant: 116).isActive = true
            } else {
                translatesAutoresizingMaskIntoConstraints = false
                leadingAnchor.constraint(equalTo: sv.leadingAnchor).isActive = true
                trailingAnchor.constraint(equalTo: sv.trailingAnchor).isActive = true
                bottomAnchor.constraint(equalTo: sv.bottomAnchor).isActive = true
                heightAnchor.constraint(equalToConstant: screenSafeInsets.bottom + 116).isActive = true
                //topAnchor.constraint(equalTo: sv.topAnchor).isActive = true
            }
        } else {
            CControlsManager.shared.removeDelegate(self)
        }
    }
    
    @IBAction func playBtn(_ sender: UIButton) {
        let state = CControlsManager.shared.play()
        if state != .Unknown {
            sender.isSelected = state == .isPaused
        }
    }
    @IBAction func nextBtn(_ sender: UIButton) {
        CControlsManager.shared.nextBtnAction()
    }
    @IBAction func prevBtn(_ sender: UIButton) {
        CControlsManager.shared.prevBtnAction()
    }
    
    
    
    
    
    
    
    
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    @IBOutlet weak var fullscreenBtn: UIButton!
    @IBAction func fullscreenBtn (_ sender:UIButton) {
        CControlsManager.shared.fullscreenBtnAction()
    }
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    @IBAction func subtitlesBtn (_ sender: UIButton)
    {
        CControlsManager.shared.subtitleBtnAction(sender)
    }
    
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    @IBAction func resolutionBtn(_ sender: UIButton) {
        presentResolutionsAction(from :sender)
    }
    
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    deinit {
        print("CVideoControlsView deinit")
    }
}

extension CVideoControlsView : CControlsManagerDelegate {
    func controlsForwardActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            switch action {
            case .open(_):
                
                nextButton.setImage(UIImage.make(name: "NextTrack-1")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
                break
            case .seek(_):
                nextButton.setImage(UIImage.make(name: "NextTrack2-1")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
                break
            default:
                return
            }
        } else {
            nextButton.isHidden = true
        }

    }
    func controlsBackwardActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            switch action {
            case .open(_):
                prevButton.setImage(UIImage.make(name: "BackTrack-1")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
                break
            case .seek(_):
                prevButton.setImage(UIImage.make(name: "BackTrack2-1")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
                break
            default:
                return
            }
        } else {
            prevButton.isHidden = true
        }
    }
    func controlsSubtitles(are available:Bool) {
        subtitlesBtn.isHidden = !available
    }
    func controlsTimeUpdated(to currentTime: String, remaining: String, andPlayer isPlaying: Bool) {
        self.duration.text    = currentTime == "" ? "● Live" : currentTime
        self.currentTime.text = remaining   == "" ? "" : remaining
        //Update play button according to current playing state
    }
    func controlsShouldAppearAboveVideo(in deviceOrientation: UIDeviceOrientation) -> Bool {
        switch deviceOrientation {
        case .landscapeLeft, .landscapeRight:
            return true
        case .portrait:
            return false
        default:
            return false
        }
    }
    func controlsPlayPauseChanged(to isPlaying: Bool) {
        play.isSelected = !isPlaying
    }
    func controlsPlayer(has resolutions: [CPlayerResolutionSource]) {
        resolutionBtn.isHidden = resolutions.count == 0
    }
    func controlsPlayerDidChangeResolution(to resolution: CPlayerResolutionSource) {
        resolutionBtn.setTitle(resolution.title, for: .normal)
    }
    func controlsProgressBarBottomPositionValueForLandscape() -> CGFloat {
        return frame.height
    }
}

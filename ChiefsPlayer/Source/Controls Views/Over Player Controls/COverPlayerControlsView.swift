//
//  COverPlayerControls.swift
//  SuperCell
//
//  Created by Husam Aamer on 7/8/19.
//  Copyright © 2019 AppChief. All rights reserved.
//

import UIKit
import MediaPlayer
import GoogleCast

class COverPlayerControlsView: CBaseControlsView {
    
    @IBOutlet weak var rightStack: UIStackView!
    
    @IBOutlet weak private var nextButton: UIButton!
    @IBOutlet weak private var playButton: UIButton!
    @IBOutlet weak private var prevButton: UIButton!
    @IBOutlet weak var subtitlesBtn: UIButton!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    var separator:UIView!
    
    @IBOutlet weak var resolutionBtn: UIButton!
    @IBOutlet weak var airViewContainer: UIView!
    
    class func instanceFromNib() -> COverPlayerControlsView {
        return super.instanceFromNib(with: "COverPlayerControlsView")
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
        
        // Add bottom decoration
        let sepHeight:CGFloat = 2
        separator.frame.size = CGSize(width: frame.width - 30, height: sepHeight)
        addSubview(separator)
        separator.backgroundColor = UIColor(red:0.20, green:0.22, blue:0.31, alpha:1.00)
        separator.autoresizingMask = [.flexibleTopMargin,.flexibleWidth]
        separator.center = CGPoint(x: frame.width/2, y: frame.height - sepHeight/2)
        
        //play.isSelected = !player.isPlaying
        
        //Setup AirPlay button
        if let airView = airView {
            airView.showsRouteButton  = true
            airView.showsVolumeSlider = false
            airView.sizeToFit()
            airView.tintColor = UIColor.black
            airView.alpha = 0.6
            airViewContainer.addSubview(airView)
            airView.center = CGPoint(x: airViewContainer.frame.width/2, y: airViewContainer.frame.height/2)
            rightStack.insertArrangedSubview(airViewContainer, at: 0)
        }
        if let castButton = castButton {
            castButton.tintColor = UIColor.white
            castButton.alpha = 0.6
            rightStack.insertArrangedSubview(castButton, at: 1)
        }
        
        
        if Device.IS_IPAD {
            fullscreenBtn.isHidden = true
        }
        
        CControlsManager.shared.addDelegate(self)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let sv = superview {
            translatesAutoresizingMaskIntoConstraints = false
            leadingAnchor.constraint(equalTo: sv.leadingAnchor).isActive = true
            trailingAnchor.constraint(equalTo: sv.trailingAnchor).isActive = true
            bottomAnchor.constraint(equalTo: sv.bottomAnchor).isActive = true
            topAnchor.constraint(equalTo: sv.topAnchor).isActive = true
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
        presentResolutionsAction(from:sender)
    }
    
    //xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    deinit {
        print("CVideoControlsView deinit")
    }
}

extension COverPlayerControlsView : CControlsManagerDelegate {
    func controlsForwardActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            switch action {
            case .open(_):
                nextButton.setImage(UIImage.make(name: "NextTrack")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
                break
            case .seek(_):
                nextButton.setImage(UIImage.make(name: "NextTrack2")?.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
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
                let icon = UIImage.make(name: "BackTrack")?.imageFlippedForRightToLeftLayoutDirection()
                prevButton.setImage(icon, for: .normal)
                break
            case .seek(_):
                let icon =  UIImage.make(name: "BackTrack2")?.imageFlippedForRightToLeftLayoutDirection()
                prevButton.setImage(icon, for: .normal)
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
        self.duration.text = currentTime == "" ? "● Live" : currentTime
        self.currentTime.text = remaining == "" ? "" : remaining
        //Update play button according to current playing state
        self.playButton.isSelected = !isPlaying
    }
    func controlsShouldAppearAboveVideo(in deviceOrientation: UIDeviceOrientation) -> Bool {
        return true // Always on video
    }
    func controlsPlayPauseChanged(to isPlaying: Bool) {
        self.playButton.isSelected = !isPlaying
    }
    func controlsPlayer(has resolutions: [CPlayerResolutionSource]) {
        resolutionBtn.isHidden = resolutions.count <= 1
    }
    func controlsPlayerDidChangeResolution(to resolution: CPlayerResolutionSource) {
        resolutionBtn.setTitle(resolution.title, for: .normal)
    }
    func controlsProgressBarBottomPositionValueForLandscape() -> CGFloat {
        return 30
    }
}

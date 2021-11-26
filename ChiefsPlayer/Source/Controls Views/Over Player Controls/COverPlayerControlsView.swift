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
import AVKit

class COverPlayerControlsView: CBaseControlsView {
    
    @IBOutlet weak var leftStack: UIStackView!
    @IBOutlet weak var rightStack: UIStackView!
    
    @IBOutlet weak private var nextButton: UIButton!
    @IBOutlet weak var forwardSeekButton: UIButton!
    @IBOutlet weak private var playButton: UIButton!
    @IBOutlet weak var backwardSeekButton: UIButton!
    @IBOutlet weak private var prevButton: UIButton!
    @IBOutlet weak var subtitlesBtn: UIButton!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var scaleButton : UIButton!
    var pipButton: UIButton?
    var separator:UIView!
    
    /// This layer added above this view to hide video view when get panned up for fullscreen toggling
    lazy var topGL:CAGradientLayer = CAGradientLayer()
    
    @IBOutlet weak var resolutionBtn: UIButton!
    @IBOutlet weak var airViewContainer: UIView!
    
    class func instanceFromNib() -> COverPlayerControlsView {
        return super.instanceFromNib(with: "COverPlayerControlsView")
    }
    
    var bgColor: UIColor {
        return UIColor(white: 0, alpha:0.50) // final color alpha is also controlled by cvideoview
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = bgColor
        separator = UIView()
        
    }
    
    //Init UI
    override func awakeFromNib() {
        subtitlesBtn.isHidden = true
        // Set icons manualy 
        subtitlesBtn.setImage(UIImage(named: "subtitles"), for: .normal)
        
        currentTime.text = nil
        duration.text = nil
        
        //play.isSelected = !player.isPlaying
        
        //Setup AirPlay button
        if let airView = airView {
            airView.sizeToFit()
            airView.tintColor = UIColor.white
            airView.alpha = 0.6
            if #available(iOS 11.0, *) {
                airViewContainer.removeFromSuperview()
                
                if let avRoute = airView as? AVRoutePickerView {
                    avRoute.activeTintColor = UIColor.red
                }
                rightStack.insertArrangedSubview(airView, at: 0)
                airView.widthAnchor.constraint(equalToConstant: 30).isActive = true
                airView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            } else {
                airView.translatesAutoresizingMaskIntoConstraints = false
                airViewContainer.clipsToBounds = true
                airViewContainer.addSubview(airView)
                //airView.center = CGPoint(x: airViewContainer.frame.width/2, y: airViewContainer.frame.height/2)
                airView.widthAnchor.constraint(equalTo: airViewContainer.widthAnchor).isActive = true
                airView.heightAnchor.constraint(equalTo: airViewContainer.heightAnchor).isActive = true
                airView.centerYAnchor.constraint(equalTo: airViewContainer.centerYAnchor).isActive = true
                airView.centerXAnchor.constraint(equalTo: airViewContainer.centerXAnchor).isActive = true
                
                rightStack.insertArrangedSubview(airViewContainer, at: 0)
                airViewContainer.widthAnchor.constraint(equalToConstant: 30).isActive = true
                airViewContainer.heightAnchor.constraint(equalToConstant: 30).isActive = true
            }
        }
        if let castButton = castButton {
            castButton.tintColor = UIColor.white
            castButton.alpha = 0.6
            rightStack.insertArrangedSubview(castButton, at: 0)
        }

        // Pip Button
        /*
        if #available(iOS 13.0, *) {
            if CControlsManager.shared.pipEnabled {
                pipButton = UIButton(type: .custom)
                pipButton?.addTarget(CControlsManager.shared,
                                    action: #selector(CControlsManager.shared.togglePictureInPictureMode(_:)),
                                    for: .touchUpInside)
                let startImage = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: .current)
                let stopImage = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: .current)
                
                pipButton?.setImage(startImage, for: .normal)
                pipButton?.setImage(stopImage, for: .selected)
                
                rightStack.addArrangedSubview(pipButton!)
            }
        }*/
        
        
        // Scale Button
        if ChiefsPlayer.shared.acvFullscreen.isActive {
            self.scaleButton.isHidden = false
        } else {
            self.scaleButton.isHidden = true
        }
        
        CControlsManager.shared.addDelegate(self)
        
        topGL.colors = [bgColor.withAlphaComponent(0).cgColor, bgColor.cgColor]
        layer.addSublayer(topGL)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if case ACVStyle.enlarging = ChiefsPlayer.shared.acvStyle {
            topGL.isHidden = false
        } else if case ACVStyle.maximized = ChiefsPlayer.shared.acvStyle {
            topGL.isHidden = false
        } else {
            topGL.isHidden = true
        }
        let glHeight:CGFloat = 100
        topGL.frame = CGRect(x: 0, y: -glHeight, width: bounds.width, height: glHeight)
        CATransaction.commit()
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
    @IBAction func forwardBtn(_ sender: UIButton) {
        CControlsManager.shared.forwardBtnAction()
    }
    @IBAction func backwardBtn(_ sender: UIButton) {
        CControlsManager.shared.backwardBtnAction()
    }
    @IBAction func nextBtn(_ sender: UIButton) {
        let _ = CControlsManager.shared.nextBtnAction()
    }
    @IBAction func prevBtn(_ sender: UIButton) {
        let _ = CControlsManager.shared.prevBtnAction()
    }
    
    
    
    
    @IBAction func scaleVideoTapped(_ sender : UIButton ) {
        CControlsManager.shared.toggleVideoAspect()
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
        CControlsManager.shared.moreBtnAction(sender)
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
    
    func controlsLeftAccessoryViewsDidChange(to newViews: [UIView]?) {
        
        //Remove old views
        let old = leftStack.arrangedSubviews.filter({$0.tag == CVideoControlsView.ACCESSORY_VIEW_TAG})
        old.forEach({$0.removeFromSuperview()})
        
        //Add new views
        if let views = newViews {
            views.forEach({
                let v = $0
                v.tag = CVideoControlsView.ACCESSORY_VIEW_TAG
                leftStack.addArrangedSubview(v)
            })
        }
        
    }
    
    func controlsRightAccessoryViewsDidChange(to newViews: [UIView]?) {
        //Remove old views
        let old = rightStack.arrangedSubviews.filter({$0.tag == CVideoControlsView.ACCESSORY_VIEW_TAG})
        old.forEach({$0.removeFromSuperview()})
        
        //Add new views
        if let views = newViews {
            views.forEach({
                let v = $0
                v.tag = CVideoControlsView.ACCESSORY_VIEW_TAG
                rightStack.insertArrangedSubview(v, at: 0)
            })
        }
    }
    
    func controlsForwardActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            forwardSeekButton.isHidden = false
            switch action {
            case .custom(let icon):
                forwardSeekButton.setImage(icon ?? UIImage.make(name: "NextTrack"), for: .normal)
                break
            case .play(_):
                forwardSeekButton.setImage(UIImage.make(name: "NextTrack"), for: .normal)
                break
            case .seekBy(_):
                forwardSeekButton.setImage(UIImage.make(name: "NextTrack2"), for: .normal)
                break
            case .seekTo(_):
                    break
            }
        } else {
            forwardSeekButton.isHidden = true
        }

    }
    func controlsBackwardActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            backwardSeekButton.isHidden = false
            switch action {
            case .custom(let icon):
                backwardSeekButton.setImage(icon ?? UIImage.make(name: "BackTrack"), for: .normal)
                break
            case .play(_):
                backwardSeekButton.setImage(UIImage.make(name: "BackTrack"), for: .normal)
                break
            case .seekBy(_):
                backwardSeekButton.setImage(UIImage.make(name: "BackTrack2"), for: .normal)
            case .seekTo(_):
                    break
            }
        } else {
            backwardSeekButton.isHidden = true
        }
    }
    func controlsNextActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            nextButton.isHidden = false
            switch action {
            case .custom(let icon):
                nextButton.setImage(icon ?? UIImage.make(name: "NextTrack"), for: .normal)
                break
            case .play(_):
                nextButton.setImage(UIImage.make(name: "NextTrack"), for: .normal)
                break
            case .seekBy(_):
                nextButton.setImage(UIImage.make(name: "NextTrack2"), for: .normal)
                break
            case .seekTo(_):
                    break
            }
        } else {
            nextButton.isHidden = true
        }
    }
    func controlsPrevActionDidChange(to newAction: SeekAction?) {
        if let action = newAction {
            prevButton.isHidden = false
            switch action {
            case .custom(let icon):
                prevButton.setImage(icon ?? UIImage.make(name: "BackTrack"), for: .normal)
                break
            case .play(_):
                prevButton.setImage(UIImage.make(name: "BackTrack"), for: .normal)
                break
            case .seekBy(_):
                prevButton.setImage(UIImage.make(name: "BackTrack2"), for: .normal)
                break
            case .seekTo(_):
                    break
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
    func controlsShouldAppearAboveVideo(in fullscreenMode:ACVFullscreen) -> Bool {
        return true // Always on video
    }
    func controlsPlayPauseChanged(to isPlaying: Bool) {
        self.playButton.isSelected = !isPlaying
    }
    func controlsPlayer(has resolutions: [CPlayerResolutionSource]) {
        resolutionBtn.isEnabled = resolutions.count > 1
    }
    func controlsPlayerDidChangeResolution(to resolution: CPlayerResolutionSource) {
        resolutionBtn.setTitle(resolution.title, for: .normal)
    }
    func controlsProgressBarBottomPositionValueForLandscape() -> CGFloat {
        return 30
    }
    
    func controlsPictureInPictureState(is possible: Bool) {
        pipButton?.isHidden = !possible
    }
    
    func controlsPlayerFullscreenState(changedTo fullscreenState: ACVFullscreen) {
        scaleButton.isHidden = fullscreenState.isNotActive
        let fullImage = UIImage.make(name:
                                        fullscreenState.isLocked ? "fullscreen-locked"
            : "fullscreen-2"
            )
        fullscreenBtn.setImage(fullImage, for: .normal)
    }
}

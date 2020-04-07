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
        
        currentTime.text = nil
        duration.text = nil
        
        //play.isSelected = !player.isPlaying
        
        //Setup AirPlay button
        if let airView = airView {
            airView.sizeToFit()
            airView.tintColor = UIColor.white
            airView.alpha = 0.6
            if #available(iOS 11.0, *) {
                if let avRoute = airView as? AVRoutePickerView {
                    avRoute.activeTintColor = UIColor.red
                }
                rightStack.addArrangedSubview(airView)
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
            rightStack.addArrangedSubview(castButton)
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
        resolutionBtn.isEnabled = resolutions.count > 1
    }
    func controlsPlayerDidChangeResolution(to resolution: CPlayerResolutionSource) {
        resolutionBtn.setTitle(resolution.title, for: .normal)
    }
    func controlsProgressBarBottomPositionValueForLandscape() -> CGFloat {
        return 30
    }
}

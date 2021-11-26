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
import AVKit

public class CBaseControlsView:UIView {
    
    //If chromecast manager is not initialized this causes an internal crash in chromecast sdk
    lazy var castButton:GCKUICastButton? = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
    
    var airView:UIView? {
        if #available(iOS 11.0, *) {
            let av = AVRoutePickerView()
            if #available(iOS 13.0, *) {
                av.prioritizesVideoDevices = true
            }
            return av
        } else {
            let v = MPVolumeView()
            v.showsRouteButton  = true
            v.showsVolumeSlider = false
            return v
        }
    }
    
    class func instanceFromNib<T>(with name:String) -> T {
        let podBundle = Bundle(for:self.classForCoder())
        if let bundleURL = podBundle.url(forResource: "ChiefsPlayer", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return UINib(nibName: name, bundle: bundle).instantiate(withOwner: nil, options: nil)[0] as! T
            } else {
                assertionFailure("Could not load the bundle")
            }
        } else {
            if let v = UINib(nibName: name, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? T {
                return v
            } else {
                assertionFailure("Could not create a path to the bundle")
            }
        }
        fatalError("Could not load nib from bundle, Check podspec")
    }
    
    /// Available resolutions action sheet
    func presentResolutionsAction (from buttonView:UIView) {
        var actions = [UIAlertAction]()
        let sources = ChiefsPlayer.shared.selectedSource.resolutions
        for resolutionSource in sources.enumerated() {
            let action = UIAlertAction(
                title: resolutionSource.element.title,
                style: .default, handler: {[offset = resolutionSource.offset, element = resolutionSource.element] (_) in

                    ChiefsPlayer.shared.play(from: ChiefsPlayer.shared.sources,
                                         with: nil,
                                         startWithResoultionAt: offset)
                    
                    //Tell Parent App
                    ChiefsPlayer.shared.delegate?
                        .chiefsplayerResolutionChanged(to: element, from: ChiefsPlayer.shared.selectedSource)
                    
                    CControlsManager.shared.delegates.forEach({$0?.controlsPlayerDidChangeResolution(to: element)})
            })

            if ChiefsPlayer.shared._selectedResolutionIndex == resolutionSource.offset {
                action.setValue(true, forKey: "checked")
            }

            actions.append(action)
        }
        
        if actions.count > 0 {
            let sheet = alert(title: localized("pick_resolution_title"),
                              body: nil, cancel: localized("dismiss"),
                              actions: actions, style: .actionSheet)
            sheet.popoverPresentationController?.sourceView = buttonView
            sheet.popoverPresentationController?.sourceRect = CGRect(x: buttonView.frame.midX, y: buttonView.frame.maxY, width: 0, height: 0)
            ChiefsPlayer.shared.parentVC.present(sheet, animated: true, completion: nil)
        }
    }
    
    // App >> CControlsManager {show/hide skip view}
    // Skip view {tapped} >> ChiefPlayerDelegate {Skip Tapped}
    // or ChiefPlayerDelegate {skipViewAction -> SeekAction}
}

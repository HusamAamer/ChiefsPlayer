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

class CBaseControlsView:UIView {
    
    //If chromecast manager is not initialized this causes an internal crash in chromecast sdk
    lazy var castButton:GCKUICastButton? = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
    //lazy var airView?     = MPVolumeView()
    var airView:MPVolumeView?
    
    class func instanceFromNib() -> CBaseControlsView {
        fatalError("No Sir!")
    }
    
    func presentResolutionsAction (from buttonView:UIView) {
        var actions = [UIAlertAction]()
        let sources = ChiefsPlayer.shared.selectedSource.resolutions
        for resolutionSource in sources.enumerated() {
            let action = UIAlertAction(
                title: resolutionSource.element.title,
                style: .default, handler: { (_) in
                
                    ChiefsPlayer.shared.play(from: ChiefsPlayer.shared.sources,
                                         with: nil,
                                         startWithResoultionAt: resolutionSource.offset)
                    CControlsManager.shared.delegates.forEach({$0?.controlsPlayerDidChangeResolution(to: resolutionSource.element)})
            })
            
            if ChiefsPlayer.shared._selectedResolutionIndex == resolutionSource.offset {
                action.setValue(true, forKey: "checked")
            }
            
            actions.append(action)
        }
        
        if actions.count > 0 {
            let sheet = UIAlertController(title: "تغيير الدقة", message: nil, preferredStyle: .actionSheet)
            sheet.popoverPresentationController?.sourceView = buttonView
            sheet.popoverPresentationController?.sourceRect = CGRect(x: buttonView.frame.midX, y: buttonView.frame.maxY, width: 0, height: 0)
            actions.append(.init(title: "رجوع", style: .cancel, handler: nil))
            actions.forEach({sheet.addAction($0)})
            UIApplication.shared.keyWindow?.rootViewController?.present(sheet, animated: true, completion: nil)
        }
    }

}

//extension CBaseControlsView : CControlsManagerDelegate {
//    func controlsForwardActionDidChange(to newAction: SeekAction?) {
//        
//    }
//    func controlsBackwardActionDidChange(to newAction: SeekAction?) {
//        
//    }
//    func controlsSubtitles(are available:Bool) {
//        
//    }
//    func controlsTimeUpdated(to currentTime: String, remaining: String, andPlayer isPlaying: Bool) {
//        
//    }
//    func controlsShouldAppearAboveVideo(in deviceOrientation: UIDeviceOrientation) -> Bool {
//        return false
//    }
//}

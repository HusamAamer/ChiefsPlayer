//
//  CControlsProtocol.swift
//  SuperCell
//
//  Created by Husam Aamer on 7/7/19.
//  Copyright © 2019 AppChief. All rights reserved.
//

import UIKit

////////////////////////////////////////////////////////////
struct CPlayerSource {
    var defaultSource:CPlayerResolutionSource {
        get {
            return resolutions.first!
        }
    }
    var resolutions:[CPlayerResolutionSource]
    var subtitles:[CPlayerSubtitleSource]? = nil
}
struct CPlayerResolutionSource : Codable {
    var title:String
    var source:URL
}
struct CPlayerSubtitleSource : Codable {
    var title:String
    var source:URL
}
protocol CControlsManagerDelegate : NSObjectProtocol {
    func controlsForwardActionDidChange (to newAction:SeekAction?)
    func controlsBackwardActionDidChange (to newAction:SeekAction?)
    func controlsSubtitles(are available:Bool)
    func controlsTimeUpdated (to currentTime:String, remaining:String,andPlayer isPlaying:Bool)
    func controlsShouldAppearAboveVideo (in deviceOrientation:UIDeviceOrientation) -> Bool
    func controlsPlayPauseChanged (to isPlaying:Bool)
    func controlsPlayer (has resolutions:[CPlayerResolutionSource])
    func controlsPlayerDidChangeResolution (to resolution:CPlayerResolutionSource)
    func controlsProgressBarBottomPositionValueForLandscape () -> CGFloat
}

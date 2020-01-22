//
//  CControlsProtocol.swift
//  SuperCell
//
//  Created by Husam Aamer on 7/7/19.
//  Copyright © 2019 AppChief. All rights reserved.
//

import UIKit

////////////////////////////////////////////////////////////
public struct CPlayerSource {
    
    public var defaultSource:CPlayerResolutionSource {
        get {
            return resolutions.first!
        }
    }
    public var resolutions:[CPlayerResolutionSource]
    public var subtitles:[CPlayerSubtitleSource]? = nil
    
    
    public init(resolutions: [CPlayerResolutionSource], subtitles:[CPlayerSubtitleSource]? = nil) {
        self.resolutions = resolutions
        self.subtitles = subtitles
    }
}
public struct CPlayerResolutionSource : Codable {
    public var title:String
    public var source_m3u8:URL?
    public var source_file:URL?
    
    public init(title: String,_ m3u8: URL?,_ fileUrl: URL? = nil) {
        self.title          = title
        if (m3u8 == nil && fileUrl == nil) {fatalError("M3u8 or fileUrl should be specified, Passed title is '\(title)'")}
        self.source_m3u8    = m3u8
        self.source_file    = fileUrl
    }
}
public struct CPlayerSubtitleSource : Codable {
    public var title:String
    public var source:URL
    
    public init(title: String, source: URL) {
        self.title = title
        self.source = source
    }
}
public protocol CControlsManagerDelegate : NSObjectProtocol {
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

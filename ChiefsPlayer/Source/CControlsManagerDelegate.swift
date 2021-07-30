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
    public var metadata:CPlayerMetadata? = nil
    
    public init(resolutions: [CPlayerResolutionSource],
                subtitles:[CPlayerSubtitleSource]? = nil,
                metadata:CPlayerMetadata? = nil) {
        self.resolutions = resolutions
        self.subtitles = subtitles
        self.metadata = metadata
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
/// Metadata to be used by player to show in chromcast for example
public struct CPlayerMetadata : Codable {
    public var title:String
    public var description:String? = nil
    public var image:URL? = nil
    
    public init(title: String, image: URL? = nil, description: String? = nil) {
        self.title = title
        self.image = image
        self.description = description
    }
}
public protocol CControlsManagerDelegate : NSObjectProtocol {
    func controlsLeftAccessoryViewsDidChange (to newViews:[UIView]?)
    func controlsRightAccessoryViewsDidChange (to newViews:[UIView]?)
    func controlsForwardActionDidChange (to newAction:SeekAction?)
    func controlsBackwardActionDidChange (to newAction:SeekAction?)
    func controlsNextActionDidChange (to newAction:SeekAction?)
    func controlsPrevActionDidChange (to newAction:SeekAction?)
    func controlsSubtitles(are available:Bool)
    func controlsTimeUpdated (to currentTime:String, remaining:String,andPlayer isPlaying:Bool)
    func controlsShouldAppearAboveVideo (in deviceOrientation:UIDeviceOrientation) -> Bool
    func controlsPlayPauseChanged (to isPlaying:Bool)
    func controlsPlayer (has resolutions:[CPlayerResolutionSource])
    func controlsPlayerDidChangeResolution (to resolution:CPlayerResolutionSource)
    func controlsProgressBarBottomPositionValueForLandscape () -> CGFloat
    
    func controlsPictureInPictureState (is possible:Bool)
}

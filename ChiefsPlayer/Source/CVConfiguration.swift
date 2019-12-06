//
//  ACVideoPlayer.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 3/24/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation


public struct CVConfiguration {
    public enum VideoRatio {
        case widescreen, //16:9  -> 1080p,720p ...
        classicTV, //4:3
        custom(CGFloat)
    }
    public enum ControlsStyle {
        case youtube, barStyle
    }
    
    // MARK: - Properties
    
    //static var shared = CVConfiguration()
    
    // MARK: - Variables
    public var controlsStyle : ControlsStyle = .youtube
    
    public var videoRatio : VideoRatio = .widescreen
    public var videoRatioValue : CGFloat {
        switch videoRatio {
        case .widescreen:
            return 16/9
        case .classicTV:
            return 4/3
        case .custom(let ratio):
            return ratio
        }
    }
    
    // Initialization
    
    init() {
        self.videoRatio = .widescreen
    }
}

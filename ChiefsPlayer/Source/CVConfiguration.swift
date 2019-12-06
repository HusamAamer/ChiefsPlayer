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


enum VideoRatio {
    case widescreen, //16:9  -> 1080p,720p ...
    classicTV, //4:3
    custom(CGFloat)
}
struct CVConfiguration {
    enum ControlsStyle {
        case youtube, barStyle
    }
    
    // MARK: - Properties
    
    //static var shared = CVConfiguration()
    
    // MARK: - Variables
    var controlsStyle : ControlsStyle = .youtube
    
    var videoRatio : VideoRatio = .widescreen
    var videoRatioValue : CGFloat {
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

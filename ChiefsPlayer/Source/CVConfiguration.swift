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
        
        var value:CGFloat {
            switch self {
            case .widescreen:
                return 16/9
            case .classicTV:
                return 4/3
            case .custom(let ratio):
                return ratio
            }
        }
    }
    public enum ControlsStyle {
        case youtube, barStyle
    }
    public enum Appearance {
        case automatic,dark, light
    }
    public enum Language:String {
        case automatic = "automatic",arabic = "ar", english = "en"
    }
    public struct ProgressBarStyle {
        public var defualtHeight : CGFloat = 3
        public var panningHeight : CGFloat = 6
        public var showsLivePanDuration = false
        
        public init () {
            
        }
        public init(defaultHeight:CGFloat? = nil, panningHeight:CGFloat? = nil, showsLivePanDuration:Bool? = nil) {
            self.defualtHeight = defaultHeight ?? self.defualtHeight
            self.panningHeight = panningHeight ?? self.panningHeight
            self.showsLivePanDuration = showsLivePanDuration ?? self.showsLivePanDuration
        }
    }
    
    // MARK: - Properties
    
    //static var shared = CVConfiguration()
    
    // MARK: - Variables
    public var controlsStyle : ControlsStyle = .youtube
    
    /// Appearance of alerts and some views
    public var appearance : Appearance = .automatic
    
    public var language : Language?
        
    public var videoRatio : VideoRatio = .widescreen
    
    public var progressBarStyle : ProgressBarStyle = .init()
    
    // Initialization
    
    init() {
        self.videoRatio = .widescreen
    }
}

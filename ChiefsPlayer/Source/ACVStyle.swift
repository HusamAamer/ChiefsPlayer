//
//  ACVideoPlayer.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 3/24/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import AVFoundation

public enum ACVStyle:Comparable {
    case minimized,
         maximized,
         moving(CGFloat),
         dismissing(CGFloat),
         fullscreen,
         fullscreenLocked
    
    var isFullscreen:Bool {
        return self == .fullscreen || self == .fullscreenLocked
    }
    
    public static func < (lhs: ACVStyle, rhs: ACVStyle) -> Bool {
        switch lhs {
        case .maximized:
            if rhs == .maximized {
                return true
            }
            return false
        case .minimized:
            if rhs == .minimized {
                return true
            }
            return false
        default:
            return false
        }
    }
}

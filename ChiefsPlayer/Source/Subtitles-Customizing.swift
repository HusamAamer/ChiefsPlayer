//
//  Subtitles-Customizing.swift
//  ChiefsPlayer
//
//  Created by Husam Aamer on 3/28/21.
//  Copyright © 2021 AppChief. All rights reserved.
//

import Foundation
import UIKit

extension Subtitles {
    public static func setFontSize (_ size:CGFloat) {
        fontSize = size
        ChiefsPlayer.shared.subtitleLabel?.font = getFont()
    }
    public static func getFont () -> UIFont {
        
        let size = fontSize ?? (UI_USER_INTERFACE_IDIOM() == .pad ? 25.0 : 20.0)
        
        return UIFont.boldSystemFont(ofSize: size)
    }
}

extension Subtitles {
    fileprivate enum Keys {
        static var fontSize = "com.AppChief.ChiefsPlayer.Subtitle.Size"
    }
    
    fileprivate static var fontSize:CGFloat? {
        set {
            defaults.setValue(newValue, forKey: Keys.fontSize)
        }
        get {
            defaults.value(forKey: Keys.fontSize) as? CGFloat
        }
    }
    
    fileprivate static var defaults : UserDefaults {
        return UserDefaults.standard
    }
}

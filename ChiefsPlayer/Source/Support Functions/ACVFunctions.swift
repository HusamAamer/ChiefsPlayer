//
//  ACVideoPlayer.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 3/24/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import AVKit

extension UIView {
    func sizeAchor(equalsTo view:UIView,
                   leftOffset:CGFloat = 0,
                   rightOffset:CGFloat = 0,
                   topOffset:CGFloat = 0,
                   bottomOffset:CGFloat = 0) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let le = leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let tr = trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let top = topAnchor.constraint(equalTo: view.topAnchor)
        let bot = bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        le.constant = leftOffset
        tr.constant = rightOffset
        top.constant = topOffset
        bot.constant = bottomOffset
        
        le.isActive = true
        tr.isActive = true
        top.isActive = true
        bot.isActive = true
    }
}
extension CMTime {
    var asInt : Int? {
        get {
            if let float = asFloat {
                return Int(float)
            }
            return nil
        }
    }
    var asFloat : Float? {
        get {
            if !isValid || isIndefinite {
                //If duration is unknown then set current time as duration
                return nil
            }
            let float = CMTimeGetSeconds(self)
            if float.isNaN || float.isInfinite {return nil} //Happens when user is on error only
            return Float(float)
        }
    }
}
class AVCGlobalFuncs: NSObject {
    static var bundle:Bundle {
        let podBundle = Bundle(for: ChiefsPlayer.self)

        let bundleURL = podBundle.url(forResource: "ChiefsPlayer", withExtension: "bundle")
        return Bundle(url: bundleURL!)!
    }
    static func playerItemDuration() -> TimeInterval? {
        let thePlayerItem = ChiefsPlayer.shared.player?.currentItem
        if thePlayerItem?.status == .readyToPlay,
            let duration = thePlayerItem?.duration {
            if !duration.isIndefinite, duration.isValid, duration.isNumeric
            {
                return CMTimeGetSeconds(duration)
            }
        }
        return nil
    }
    static func playerItemDurationString() -> String {
        if let duration = playerItemDuration()
        {
            return timeFrom(seconds: duration)
        }
        return ""
    }
    static func playerItemTimeRemainingString() -> String {
        if let duration = playerItemDuration()
        {
            let thePlayerItem = ChiefsPlayer.shared.player.currentItem
            return "-" + timeFrom(
                seconds: duration - CMTimeGetSeconds(thePlayerItem!.currentTime())
            )
        }
        return ""
    }
    static func timeFrom(seconds:CMTime) -> String
    {
        return AVCGlobalFuncs.timeFrom(seconds: CMTimeGetSeconds(seconds))
    }
    static func timeFrom(seconds:TimeInterval) -> String
    {
        var str = ""
        if seconds.isNaN || seconds.isInfinite {
            return ""
        }
        let secs = Int(seconds)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        
        let h = hours < 10 ? "0\(hours)" : "\(hours)"
        let m = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let s = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        if secs <= 3600 {
            str = "\(m):\(s)"
        } else {
            str = "\(h):\(m):\(s)"
        }
        return str
    }
}

extension UIPanGestureRecognizer {
    
    public struct PanGestureDirection: OptionSet {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
        static let Up = PanGestureDirection(rawValue: 1 << 0)
        static let Down = PanGestureDirection(rawValue: 1 << 1)
        static let Left = PanGestureDirection(rawValue: 1 << 2)
        static let Right = PanGestureDirection(rawValue: 1 << 3)
    }
    
    private func getDirectionBy(velocity: CGFloat, greater: PanGestureDirection, lower: PanGestureDirection) -> PanGestureDirection {
        if velocity == 0 {
            return []
        }
        return velocity > 0 ? greater : lower
    }
    
    public func direction(in view: UIView) -> PanGestureDirection {
        let velocity = self.velocity(in: view)
        let yDirection = getDirectionBy(velocity: velocity.y, greater: PanGestureDirection.Down, lower: PanGestureDirection.Up)
        let xDirection = getDirectionBy(velocity: velocity.x, greater: PanGestureDirection.Right, lower: PanGestureDirection.Left)
        return xDirection.union(yDirection)
    }
}

public extension AVPlayerItem {
    
    func totalBuffer() -> Double {
        return self.loadedTimeRanges
            .map({ $0.timeRangeValue })
            .reduce(0, { acc, cur in
                return acc + CMTimeGetSeconds(cur.start) + CMTimeGetSeconds(cur.duration)
            })
    }
    
    func currentBuffer() -> Double {
        let currentTime = self.currentTime()
        
        guard let timeRange = self.loadedTimeRanges.map({ $0.timeRangeValue })
            .first(where: { $0.containsTime(currentTime) }) else { return -1 }
        
        return CMTimeGetSeconds(timeRange.end) - currentTime.seconds
    }
    
}


extension AVPlayer {
    var isPlaying: Bool {return (self.rate != 0 && self.error == nil)}
}
extension CAVQueuePlayer {
    open override func pause() {
        if currentItem != nil {
            super.pause()
        }
    }
}

extension ChiefsPlayer {
    func interfaceOrientation (for deviceOrientation:UIDeviceOrientation) -> UIInterfaceOrientation? {
        
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait:
            return .portrait
        default:
            return nil
        }
    }
}

extension ChiefsPlayer {
    static func Log(event name:String) {
        ChiefsPlayer.shared.delegate?.chiefsplayerDebugLog(name)
        debugPrint(name)
    }
}

var screenWidth:CGFloat {return UIScreen.main.bounds.width}
var screenHeight:CGFloat {return UIScreen.main.bounds.height}

struct Device {
    // iDevice detection code
    static let IS_IPAD             = UIDevice.current.userInterfaceIdiom == .pad
    static let IS_IPHONE           = UIDevice.current.userInterfaceIdiom == .phone
    static var HAS_NOTCH : Bool {
        if #available(iOS 11.0, *) {
            let bottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            return bottom > 0
        } else {
            return false
        }
    }
}

var screenSafeInsets: UIEdgeInsets {
    get {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        } else {
            return .zero
        }
    }
}

func alert(title:String?, body:String?, cancel:String?,actions:[UIAlertAction]? = nil, style:UIAlertController.Style = .alert) -> UIAlertController {
    
    let a = UIAlertController(title: title, message: body, preferredStyle: style)
    
    let appearance = ChiefsPlayer.shared.configs.appearance
    if #available(iOS 13.0, *) {
        if appearance == .dark {
            a.overrideUserInterfaceStyle = .dark
        } else if appearance == .light {
            a.overrideUserInterfaceStyle = .light
        }
    }
    
    if let actionsArray = actions {
        for case let action in actionsArray as [UIAlertAction] {
            a.addAction(action)
        }
    }
    if let cancelStr = cancel {
        let cancelBtn = UIAlertAction(title: cancelStr, style: .cancel,
                                   handler: nil)
        a.addAction(cancelBtn)
    }
    
    return a
}

func in_main (_ block:@escaping () -> ()){
    DispatchQueue.main.async { () -> Void in
        block()
    }
}
public extension UIImage {
  static func make(name: String) -> UIImage? {
    let bundle = Bundle(for: CBaseControlsView.self)
    return UIImage(named: "ChiefsPlayer.bundle/\(name)", in: bundle, compatibleWith: nil)
        ?? UIImage(named: name, in: bundle, compatibleWith: nil)
  }
}

func localized (_ string:String) -> String {
    
    let dic : [String:[String:String]] = ["dismiss": [
        "ar" : "إخفاء",
        "en" : "Dismiss"
    ], "no_caption": [
        "ar" : "بلا ترجمة",
        "en" : "OFF"
    ], "pick_subtitle_title": [
        "ar" : "إختر الترجمة",
        "en" : "Pick subtitle"
    ], "pick_resolution_title": [
        "ar" : "إختر الدقة",
        "en" : "Pick resolution"
    ],"streaming_in_progress": [
        "ar" : "البث جـاهز",
        "en" : "Streaming Video"
    ],"chromecast_not_support_local": [
        "ar" : "جهاز كرومكاست لا يدعم بث محتوى من جهازك",
        "en" : "Chromecast doesn't support casting content saved in your device"
    ]]
    
    
    var localeAbbrev:String = "en"
    
    let language = ChiefsPlayer.shared.configs.language ?? .automatic
    if language == .automatic {
        if let abbr = Locale.current.languageCode {
            if ["ar","en"].contains(abbr) {
                localeAbbrev = abbr
            }
        }
    } else {
        localeAbbrev = language.rawValue
    }
    
    if let value = dic[string]?[localeAbbrev] {
        return value
    }
    
    return string
}
var isRTL:Bool {
    get {
        return UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft
    }
}

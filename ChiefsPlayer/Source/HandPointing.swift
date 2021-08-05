//
//  HandPointing.swift
//  iPrepaid
//
//  Created by Husam Aamer on 9/20/17.
//  Copyright © 2017 HA. All rights reserved.
//

import UIKit

class HandPointing: UIView {
    var hand:UIImageView!
    enum HandPointingPath {
        case UpToDown
        case DownToUp
        case UpToDownAndBack
        case Tapping
    }
    var path:HandPointingPath!
    var isAnimating = false
    
    init(frame: CGRect,path:HandPointingPath) {
        super.init(frame: CGRect(x:0,y:0,width:40,height:40))
        backgroundColor = .clear
        self.path = path
        
        hand = UIImageView(image: UIImage(named: "swipe-up-hand"))
        hand.center = CGPoint(x: frame.width/2, y: frame.height/2)
        addSubview(hand)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !isAnimating {
            startAnimation()
            isAnimating = true
        }
    }
    func startAnimation () {
        var endY:CGFloat = self.hand.frame.height/2
        switch path {
        case .DownToUp?:
            hand.center = CGPoint(
                x: frame.width/2,
                y: frame.height - hand.frame.height/2
            )
        default:
            endY = frame.height - hand.frame.height
        }
        
        var options:UIView.KeyframeAnimationOptions = [.beginFromCurrentState,.repeat]
        if path == HandPointingPath.UpToDownAndBack {
            options.update(with: .autoreverse)
        }
        self.hand.alpha = 0
        //I'm delaying animation because in SpotLightView all animations inside contentView are stopping on spotlight animation end
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animateKeyframes(withDuration: 0.7,
                                    delay: 0,
                                    options: options,
                                    animations: {
                                        self.hand.center = CGPoint(
                                            x: self.frame.width/2,
                                            y: endY
                                        )
                                        self.hand.alpha = 1
            },completion: nil)
        }
    }
}

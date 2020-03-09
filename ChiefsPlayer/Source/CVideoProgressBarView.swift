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

class CVideoProgressBarView: UIView {
    var userIsPanning : Bool = false {
        didSet {
            updateOrbFrame()
        }
    }
    /// Reached playing time indicator
    var progress:CGFloat = 0 {
        didSet {
            if progress < 0 || progress.isInfinite || progress.isNaN{
                progress = 0
            }
            updateBarFrame()
            updateOrbFrame()
        }
    }
    /// Loaded buffer bar in pixils
    var buffer:CGFloat = 0 {
        didSet {
            if buffer < 0 || buffer.isInfinite || buffer.isNaN{
                buffer = 0
            }
            updateBufferFrame()
        }
    }
    lazy var barLayer    : CAShapeLayer = CAShapeLayer()
    lazy var orb         : CAShapeLayer = CAShapeLayer()
    var gradient         : CAGradientLayer!
    lazy var bufferBar   : CAShapeLayer = CAShapeLayer()
    var orbSide          : CGFloat {
        get {
            return userIsPanning ? 12 : 6
        }
        set{}
    }
    private var heightConstraint:NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        layer.cornerRadius = 2
        
        backgroundColor = UIColor(red: 0.2147547934, green: 0.2642100249, blue: 0.364286835, alpha: 0.9)
        
        //Height of self
        heightConstraint = heightAnchor.constraint(equalToConstant: ChiefsPlayer.shared.configs.progressBarStyle.defualtHeight)
        heightConstraint.isActive = true
        
        //Buffer
        bufferBar.backgroundColor = UIColor(white: 1, alpha: 0.2).cgColor
        layer.addSublayer(bufferBar)
        
        layer.addSublayer(barLayer)
        
        let batTint = UIColor(red:0.85, green:0.13, blue:0.33, alpha:1.00)
        
        //barGradient
        gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
            //UIColor(red:0.53, green:0.22, blue:0.64, alpha:1.00).cgColor,
            //UIColor(red:0.65, green:0.25, blue:0.25, alpha:1.00).cgColor,
            UIColor(red:0.55, green:0.30, blue:0.41, alpha:1.00).cgColor,
            batTint.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.frame = bounds
        barLayer.masksToBounds = true
        barLayer.addSublayer(gradient)
        
        
        //Orb
        orb.cornerRadius = orbSide / 2
        orb.backgroundColor = batTint.cgColor
        layer.addSublayer(orb)
        
        updateBarFrame()
        updateBufferFrame()
        updateOrbFrame()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        bufferBar.frame = CGRect(x: bufferBar.frame.origin.x, y: 0, width: bufferBar.frame.width, height: bounds.height)
            
        updateBarFrame()
        updateBufferFrame()
        updateOrbFrame()
    }
    func updateBarFrame () {
        let newWidth = abs(progress) * frame.width
        let newX = isRTL ? bounds.width - newWidth : 0
        barLayer.frame = CGRect(x: newX,
                                y: 0,
                                width: newWidth,
                                height: bounds.height)
    }
    func updateBufferFrame () {
        if userIsPanning {return}
        let bufferWidth = barLayer.bounds.width + abs(buffer)
        let bufferBarX = isRTL ? (frame.width - bufferWidth) : 0
        bufferBar.frame = CGRect(x: bufferBarX,
                                 y: barLayer.frame.origin.y,
                                 width: bufferWidth,
                                 height: barLayer.frame.height)
    }
    func updateOrbFrame () {
        let orbSide = self.orbSide
        orb.cornerRadius = orbSide/2
        let newX = isRTL ? barLayer.frame.minX - orbSide/2 : barLayer.frame.maxX - orbSide/2
        
        let newOrbFrame = CGRect(x: newX,
                            y: bounds.height/2 - orbSide/2,
                            width: orbSide,
                            height: orbSide)
        

        self.heightConstraint.constant = userIsPanning ? ChiefsPlayer.shared.configs.progressBarStyle.panningHeight : ChiefsPlayer.shared.configs.progressBarStyle.defualtHeight
        UIView.animate(withDuration: 0.5) {
            self.orb.frame = newOrbFrame
            self.superview?.layoutIfNeeded()
        }
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        print("CVideoProgressBarView deinit")
    }
}

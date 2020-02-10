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
    /// Reached playing time indicator
    var progress:CGFloat = 0 {
        didSet {
            if progress < 0 || progress.isInfinite || progress.isNaN{
                progress = 0
            }
            barWidth.constant = abs(progress) * frame.width
            layoutIfNeeded()
        }
    }
    /// Loaded buffer bar
    var buffer:CGFloat = 0 {
        didSet {
            if buffer < 0 || buffer.isInfinite || buffer.isNaN{
                buffer = 0
            }
            bufferWidth.constant = abs(buffer)
        }
    }
    var bar:UIView = UIView()
    var barWidth:NSLayoutConstraint!
    var orb:UIView!
    var gradient :CAGradientLayer!
    var bufferBar   : UIView!
    var bufferWidth : NSLayoutConstraint!
    override init(frame: CGRect) {
        super.init(frame: .zero)
        layer.cornerRadius = 2
        //clipsToBounds = true
        backgroundColor = .gray
        addSubview(bar)
        
        bar.backgroundColor = UIColor(red:0.85, green:0.13, blue:0.33, alpha:1.00)
        
        backgroundColor = UIColor(red: 0.2147547934, green: 0.2642100249, blue: 0.364286835, alpha: 0.9)
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        let le = bar.leadingAnchor.constraint(equalTo: leadingAnchor)
        barWidth = bar.widthAnchor.constraint(equalToConstant: 0)
        let top = bar.topAnchor.constraint(equalTo: topAnchor)
        let bot = bar.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        le.isActive = true
        barWidth.isActive = true
        top.isActive = true
        bot.isActive = true
        
        
        //barGradient
        let barGradient = UIView()
        bar.addSubview(barGradient)
        barGradient.translatesAutoresizingMaskIntoConstraints = false
        barGradient.leadingAnchor.constraint(equalTo: bar.leadingAnchor).isActive = true
        barGradient.topAnchor.constraint(equalTo: bar.topAnchor).isActive = true
        barGradient.bottomAnchor.constraint(equalTo: bar.bottomAnchor).isActive = true
        barGradient.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        
        gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = [
            //UIColor(red:0.53, green:0.22, blue:0.64, alpha:1.00).cgColor,
            //UIColor(red:0.65, green:0.25, blue:0.25, alpha:1.00).cgColor,
            UIColor(red:0.55, green:0.30, blue:0.41, alpha:1.00).cgColor,
            bar.backgroundColor!.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = barGradient.bounds
        barGradient.layer.addSublayer(gradient)
        bar.clipsToBounds = true
        
        
        //Buffer
        bufferBar = UIView()
        bufferBar.backgroundColor = UIColor(white: 1, alpha: 0.2)
        addSubview(bufferBar)
        bufferBar.translatesAutoresizingMaskIntoConstraints = false
        bufferBar.leadingAnchor.constraint(equalTo: bar.trailingAnchor,constant:0).isActive = true
        bufferWidth = bufferBar.widthAnchor.constraint(equalToConstant:0)
        bufferWidth.priority = .defaultLow
        bufferWidth.isActive = true
        bufferBar.heightAnchor.constraint(equalTo: bar.heightAnchor, constant: 0).isActive = true
        bufferBar.lastBaselineAnchor.constraint(equalTo: bar.lastBaselineAnchor).isActive = true
        let bufferTrailing = bufferBar.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 0)
        bufferTrailing.priority = .defaultHigh
        bufferTrailing.isActive = true
        
        //Orb
        let orbSide : CGFloat = 6
        orb = UIView()
        orb.layer.cornerRadius = orbSide / 2
        orb.backgroundColor = bar.backgroundColor
        addSubview(orb)
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.leadingAnchor.constraint(
            equalTo: bar.trailingAnchor,
            constant: -orbSide / 2).isActive = true
        orb.topAnchor.constraint(
            equalTo: bar.centerYAnchor, constant: -orbSide / 2).isActive = true
        orb.widthAnchor.constraint(equalToConstant: orbSide).isActive = true
        orb.heightAnchor.constraint(equalToConstant: orbSide).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Reset progress according to new width
        //progress = CGFloat(progress)
        barWidth.constant = progress * frame.width
        gradient.frame = bounds
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        print("CVideoProgressBarView deinit")
    }
}

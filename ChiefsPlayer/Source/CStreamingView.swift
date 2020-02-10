//
//  CLoadingView.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 4/26/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit

class CStreamingView: UIView {
    
    lazy private var image:UIImageView = UIImageView(image: UIImage.make(name: "Streaming"))
    lazy private var label:UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    init(with frame:CGRect,and text: String) {
        super.init(frame: frame)

        backgroundColor = .clear
        
        addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        image.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        
        label = UILabel()
        label.textColor = .white
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 20).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
        label.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: -15).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true
        
    }
    
    /// Hide error view when player is getting minimized
    ///
    /// - Parameter percent: y translation percent to the last state
    func setMinimize (with percent:CGFloat)
    {
        let alpha = 1 - percent * 6
        label.alpha = alpha
        ChiefsPlayer.shared.subtitleLabel?.alpha = alpha
    }
    
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

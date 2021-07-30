//
//  ResolutionButton.swift
//  ChiefsPlayer
//
//  Created by Husam Aamer on 4/7/20.
//  Copyright © 2020 AppChief. All rights reserved.
//

import UIKit

class COPResolutionButton: UIButton {
//    override init(frame: CGRect) {
//        <#code#>
//    }
//    required init?(coder: NSCoder) {
//        <#code#>
//    }
//    func commonInit () {
//        contentEdgeInsets = UIEdgeInsets(top: <#T##CGFloat#>, left: <#T##CGFloat#>, bottom: <#T##CGFloat#>, right: <#T##CGFloat#>)
//    }
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                backgroundColor = (backgroundColor ?? .white).withAlphaComponent(1)
            } else {
                backgroundColor = (backgroundColor ?? .white).withAlphaComponent(0.5)
            }
        }
    }
}

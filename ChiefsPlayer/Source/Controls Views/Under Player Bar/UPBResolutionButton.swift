//
//  ResolutionButton.swift
//  ChiefsPlayer
//
//  Created by Husam Aamer on 4/7/20.
//  Copyright © 2020 AppChief. All rights reserved.
//

import UIKit

class UPBResolutionButton: UIButton {

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

//
//  CLoadingView.swift
//  TestAVPlayer
//
//  Created by Husam Aamer on 4/26/18.
//  Copyright © 2018 AppChief. All rights reserved.
//

import UIKit
import AVFoundation
class CLoadingView: UIView {
    enum State : Equatable {
        case isLoading,isPlaying,Error(msg:String)
        
        var isError : Bool {
            switch self {
            case .isLoading,.isPlaying:
                return false
            default:
                return true
            }
        }
    }
    var state : State = .isLoading {
        didSet {
            switch state {
            case .isLoading:
                indicator.startAnimating()
                removeErrorLabels()
            case .isPlaying:
                indicator.stopAnimating()
                removeErrorLabels()
            case .Error(msg: let msg):
                indicator.stopAnimating()
                addErrorLabels(msg: msg)
                break
            }
        }
    }
    private var indicator:UIActivityIndicatorView!
    private var reloadBtn:UIButton!
    private var errorLabel:UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.autoresizingMask = [.flexibleTopMargin,.flexibleLeftMargin,.flexibleRightMargin,.flexibleBottomMargin]
        indicator.hidesWhenStopped = true
        addSubview(indicator)
        
        indicator.startAnimating()
        //reloadBtn.isHidden = true
        clipsToBounds = true
    }
    @objc private func reloadPlayerAction () {
        ChiefsPlayer.shared.reloadPlayer()
    }
    
    private func addErrorLabels (msg:String) {
        removeErrorLabels()
        
        reloadBtn = UIButton(type: .system)
        reloadBtn.setImage(UIImage.make(name: "retry"), for: .normal)
        reloadBtn.tintColor = .white
        reloadBtn.addTarget(self, action: #selector(reloadPlayerAction), for: .touchUpInside)
        reloadBtn.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reloadBtn)
        reloadBtn.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        reloadBtn.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        reloadBtn.alpha = 1
        
        errorLabel = UILabel()
        errorLabel.textColor = .white
        errorLabel.text = msg
        errorLabel.font = UIFont.systemFont(ofSize: 15)
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.topAnchor.constraint(equalTo: reloadBtn.bottomAnchor, constant: 20).isActive = true
        errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
        errorLabel.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: 15).isActive = true
        errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15).isActive = true
        
        
    }
    private func removeErrorLabels () {
        if errorLabel != nil {
            errorLabel.removeFromSuperview()
            reloadBtn.removeFromSuperview()
            errorLabel = nil
            reloadBtn  = nil
        }
    }
    
    /// Hide error view when player is getting minimized
    ///
    /// - Parameter percent: y translation percent to the last state
    func setMinimize (with percent:CGFloat)
    {
        let alpha = 1 - percent * 6
        if errorLabel != nil {
            errorLabel.alpha = alpha
        }
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

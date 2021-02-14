//
//  SheeshView.swift
//  SwipeableCardStack_Example
//
//  Created by Nathan Kellert on 2/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class SheeshView: UILabel {
    
    private var hasLaidOut = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        alpha = 0
        
        // content
        text = "Calm the hell down. Sheesh."
        textAlignment = .center
        font = .systemFont(ofSize: 14)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // If we've already laid out return
        guard !hasLaidOut else {
            return
        }
        
        hasLaidOut = true
        
        // corner radius
        layer.cornerRadius = 8
        
        // border
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.lightGray.cgColor

        // shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 2, height: 1)
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 10.0
        
        layer.backgroundColor = UIColor.white.cgColor
        layer.masksToBounds = false
    }
}

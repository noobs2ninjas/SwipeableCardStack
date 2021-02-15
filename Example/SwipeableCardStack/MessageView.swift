//
//  SheeshView.swift
//  SwipeableCardStack_Example
//
//  Created by Nathan Kellert on 2/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class MessageView: UILabel {
    
    override func drawText(in rect: CGRect) {
        let edgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        super.drawText(in: rect.inset(by: edgeInsets))
    }
    
    override func layoutSubviews() {
        
        // corner radius
        layer.cornerRadius = 8
        
        // border
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.lightGray.cgColor

        // shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 10.0
        
        layer.backgroundColor = UIColor.white.cgColor
        layer.masksToBounds = false
        
        super.layoutSubviews()
    }
}

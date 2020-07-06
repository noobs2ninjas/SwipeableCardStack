//
//  DraggableCardView.swift
//  Swipeable Stack View
//
//  Created by Nathan Kellert on 1/25/19.
//  Copyright (c) 2019 Yalantis. All rights reserved.
//

import UIKit

class SelectedView: UIView {

    var backgroundImage: UIImageView!
    var image: UIImage?
    var color: UIColor?

    init(frame: CGRect, image: UIImage?, color: UIColor?){
        super.init(frame:frame)
        
        self.image = image
        self.color = color
        
        backgroundImage = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        addSubview(backgroundImage)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateMaskForView(imageView: backgroundImage, image: image, color: color)
    }

    func updateMaskForView(imageView: UIImageView, image: UIImage?, color: UIColor?) {
        
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, true, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context!.scaleBy(x: 1, y: -1);
        context!.translateBy(x: 0, y: -imageView.bounds.size.height);

        // draw rounded rectange inset of the button's entire dimensions
        UIColor.white.setStroke()
        let rect = imageView.bounds.insetBy(dx: 10, dy: 10)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 5)
        path.lineWidth = 4
        path.stroke()

        let imageContext = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // create image mask

        let cgimage = imageContext?.cgImage!
        let bytesPerRow = cgimage!.bytesPerRow
        let dataProvider = cgimage!.dataProvider
        let bitsPerPixel = cgimage!.bitsPerPixel
        let width = cgimage!.width
        let height = cgimage!.height
        let bitsPerComponent = cgimage!.bitsPerComponent
        let mask = CGImage(maskWidth: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, provider: dataProvider!, decode: nil, shouldInterpolate: false)

        // create background

        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0)
        UIGraphicsGetCurrentContext()!.clip(to: imageView.bounds, mask: mask!)
        color != nil ? color!.setFill() : UIColor.green.withAlphaComponent(0.4).setFill()
        UIBezierPath(rect: imageView.bounds).fill()
        let background = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let frameHeight = self.frame.height/2
        let frameWidth = self.frame.width/2

        let logoView = UIImageView(frame: CGRect(x: frameWidth - frameWidth/2, y: frameHeight - frameHeight/2, width: frameWidth, height: frameHeight))
        logoView.contentMode = .scaleAspectFit
        logoView.image = image

        addSubview(logoView)

        backgroundImage.image = background
    }
}

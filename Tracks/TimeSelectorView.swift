//
//  TimeSelectorView.swift
//  Tracks
//
//  Created by John Sloan on 9/16/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class TimeSelectorView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func drawRect(rect: CGRect) {
        // Draw center line for playback
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
        CGContextSetLineWidth(context, 1)
        CGContextMoveToPoint(context, self.frame.width / 2.0, 0)
        CGContextAddLineToPoint(context, self.frame.width / 2.0, self.frame.height)
        CGContextStrokePath(context)
        
        // Draw end circles
        CGContextSetFillColorWithColor(context, UIColor.blueColor().CGColor)
        CGContextBeginPath(context)
        CGContextAddArc(context, self.frame.width / 2.0, CGFloat(3.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
        CGContextFillPath(context)
        
        CGContextBeginPath(context)
        CGContextAddArc(context, self.frame.width / 2.0, self.frame.height - CGFloat(3.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
        CGContextFillPath(context)
    }
    
}

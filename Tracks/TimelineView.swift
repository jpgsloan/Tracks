//
//  TimelineView.swift
//  Tracks
//
//  Created by John Sloan on 9/10/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class TimelineView: UIView {

    var totalTime: NSTimeInterval!
    var leadingOffset: CGFloat = 0.0
    var trailingOffset: CGFloat = 0.0
    
    convenience init(frame: CGRect, duration: NSTimeInterval) {
        self.init(frame: frame)
        totalTime = duration
        setNeedsDisplay()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        totalTime = 0.0
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
        totalTime = 0.0
    }
    
    func addOffsets(leading: CGFloat, trailing: CGFloat) {
        leadingOffset = leading
        trailingOffset = trailing
    }
    
    func updateTimeline(duration: NSTimeInterval) {
        totalTime = duration
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        var stringAttrs = [NSFontAttributeName : UIFont.systemFontOfSize(13.0), NSForegroundColorAttributeName : UIColor.whiteColor()]

        var format = NSDateFormatter()
        if totalTime >= 3600 {
            format.dateFormat = "H:mm:ss"
        } else {
            format.dateFormat = "mm:ss"
        }
        
        // Draw underline
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(context, 1)
        CGContextMoveToPoint(context, 0, self.frame.height)
        CGContextAddLineToPoint(context, self.frame.width, self.frame.height)
        CGContextStrokePath(context)
        
        // often reused values
        var mainTickHeight = CGFloat(self.frame.height - 4.0)
        var subTickHeight = CGFloat(self.frame.height / 5.0)
        var widthWithOffset = self.frame.width - leadingOffset - trailingOffset
        for (var i = 0; i < Int(ceil((self.frame.width / widthWithOffset) * CGFloat(totalTime))); i++) {
            
            var newX = CGFloat(Float64(i) / totalTime) * widthWithOffset + leadingOffset
            // Draw time labels if necessary
            print("newX")
            println(newX)
            if newX <= self.frame.width - trailingOffset {
                // Create formatted time from current seconds
                var durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(Int64(i)))
                format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                var text = format.stringFromDate(durationDate)
                var attrStr: NSAttributedString = NSAttributedString(string: text, attributes: stringAttrs)
                attrStr.drawAtPoint(CGPoint(x: newX + CGFloat(2), y: 0 ))
            }
            
            // Draw tick marks
            CGContextBeginPath(context)
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextSetLineWidth(context, 1)
            
            for (var j: CGFloat = 0; j < 4; j++) {
                var subIncrement = (widthWithOffset / CGFloat(totalTime) ) / 4.0
                CGContextMoveToPoint(context, newX + (subIncrement * j), self.frame.height)
                if j == 0 {
                    CGContextAddLineToPoint(context, newX + (subIncrement * j), self.frame.height - mainTickHeight)
                } else {
                    CGContextAddLineToPoint(context, newX + (subIncrement * j), self.frame.height - subTickHeight)
                }
            }
            
            CGContextStrokePath(context)
        }
        
        // fill in leading offset with tick marks but no labels
        for (var i = 0; i < Int(ceil((leadingOffset / widthWithOffset) * CGFloat(totalTime))); i++) {
            
            var newX = leadingOffset - CGFloat(Float64(i) / totalTime) * widthWithOffset
            
            CGContextBeginPath(context)
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextSetLineWidth(context, 1)
            // Draw tick marks
            for (var j: CGFloat = 0; j < 4; j++) {
                var subIncrement = (widthWithOffset / CGFloat(totalTime) ) / 4.0
                CGContextMoveToPoint(context, newX - (subIncrement * j), self.frame.height)
                if j == 0 {
                    CGContextAddLineToPoint(context, newX - (subIncrement * j), self.frame.height - mainTickHeight)
                } else {
                    CGContextAddLineToPoint(context, newX - (subIncrement * j), self.frame.height - subTickHeight)
                }
            }
            CGContextStrokePath(context)
        }
        
    }
}

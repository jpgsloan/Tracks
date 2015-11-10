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
    var timeWindow: CMTime!
    var leadingOffset: CGFloat = 0.0
    var trailingOffset: CGFloat = 0.0
    var trimMode: Bool = false
    
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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
        totalTime = 0.0
    }
    
    func addOffsets(leading: CGFloat, trailing: CGFloat) {
        leadingOffset = leading
        trailingOffset = trailing
    }
    
    func updateTimeline(duration: NSTimeInterval, window: CMTime) {
        totalTime = duration
        timeWindow = window
        setNeedsDisplay()
    }
    
    func toggleTrimMode(isOn: Bool) {
        trimMode = isOn
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        let stringAttrs = [NSFontAttributeName : UIFont.systemFontOfSize(13.0), NSForegroundColorAttributeName : UIColor.whiteColor()]

        let format = NSDateFormatter()
        if totalTime >= 3600 {
            format.dateFormat = "H:mm:ss"
        } else {
            format.dateFormat = "mm:ss"
        }
        
        // Draw underline
        let context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(context, 1)
        CGContextMoveToPoint(context, 0, self.frame.height)
        CGContextAddLineToPoint(context, self.frame.width, self.frame.height)
        CGContextStrokePath(context)
        
        // often reused values
        let mainTickHeight = CGFloat(self.frame.height - 4.0)
        let subTickHeight = CGFloat(self.frame.height / 5.0)
        var widthWithoutOffsets = self.frame.width - leadingOffset - trailingOffset
        if widthWithoutOffsets == 0 {
            print("DIVIDE BY ZERO ERROR")
            widthWithoutOffsets = 1.0
        }
        
        // adjust timeline tick scale so they aren't too close together with long recordings.
        var incrementAdjust: Int = 1
        if timeWindow.seconds > 120 {
            incrementAdjust = 16
        } else if timeWindow.seconds > 80 {
            incrementAdjust = 8
        } else if timeWindow.seconds > 40 {
            incrementAdjust = 4
        } else if timeWindow.seconds > 12 {
            incrementAdjust = 2
        }

        let secondsWithOffsets = Int(ceil((self.frame.width / widthWithoutOffsets) * CGFloat(totalTime)))
        for (var i = 0; i < secondsWithOffsets; i += incrementAdjust) {
            
            let newX = CGFloat(Float64(i) / totalTime) * widthWithoutOffsets + leadingOffset
            // Draw time labels if necessary (in trim mode labels are hidden)
            if newX <= self.frame.width - trailingOffset && !trimMode {
                // Create formatted time from current seconds
                let durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(Int64(i)))
                format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                let text = format.stringFromDate(durationDate)
                let attrStr: NSAttributedString = NSAttributedString(string: text, attributes: stringAttrs)
                attrStr.drawAtPoint(CGPoint(x: newX + CGFloat(2), y: 0 ))
            }
            
            // Draw tick marks
            CGContextBeginPath(context)
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextSetLineWidth(context, 1)
            
            for (var j: CGFloat = 0; j < 4; j++) {
                let subIncrement = ((widthWithoutOffsets / CGFloat(totalTime) ) / 4.0) * CGFloat(incrementAdjust)
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
        for (var i = 0; i < Int(ceil((leadingOffset / widthWithoutOffsets) * CGFloat(totalTime))); i += incrementAdjust) {
            
            let newX = leadingOffset - CGFloat(Float64(i) / totalTime) * widthWithoutOffsets
            
            CGContextBeginPath(context)
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextSetLineWidth(context, 1)
            // Draw tick marks
            for (var j: CGFloat = 0; j < 4; j++) {
                let subIncrement = ((widthWithoutOffsets / CGFloat(totalTime) ) / 4.0) * CGFloat(incrementAdjust)
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

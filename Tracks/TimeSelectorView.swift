//
//  TimeSelectorView.swift
//  Tracks
//
//  Created by John Sloan on 9/16/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore

class TimeSelectorView: UIView {
    
    var isInTrimMode = false
    var startBarX: CGFloat!
    var endBarX: CGFloat!
    var didTouchStartTrimBar = false
    var didTouchEndTrimBar = false
    var startTouch: CGPoint!
    var curStartTime: CMTime!
    var curEndTime: CMTime!
    var lastTouch: CGPoint!
    let startBarShapeLayer = CAShapeLayer()
    let endBarShapeLayer = CAShapeLayer()
    let middleSquareShapeLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.userInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.userInteractionEnabled = false
    }
    
    func trimMode() {
        isInTrimMode = true
        self.userInteractionEnabled = true
        startBarX = self.frame.width / 10.0
        endBarX = self.frame.width * 9.0 / 10.0
        
        // draw middle square
        let middleSquarePath = UIBezierPath(rect: CGRectMake(startBarX, 22, endBarX - startBarX, self.frame.height - 29))
        middleSquareShapeLayer.path = middleSquarePath.CGPath
        middleSquareShapeLayer.fillColor = UIColor.blackColor().colorWithAlphaComponent(0.2).CGColor
        layer.addSublayer(middleSquareShapeLayer)
        
        // draw start bar
        let startBarPath = UIBezierPath()
        startBarPath.moveToPoint(CGPoint(x: startBarX, y: 22))
        startBarPath.addLineToPoint(CGPoint(x: startBarX, y: self.frame.height - 7))
        startBarPath.moveToPoint(CGPoint(x: startBarX, y: 19))
        startBarPath.addArcWithCenter(CGPoint(x: startBarX, y: 19), radius: CGFloat(3.0), startAngle: CGFloat(0.0), endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        startBarPath.moveToPoint(CGPoint(x: startBarX, y: self.frame.height - 4))
        startBarPath.addArcWithCenter(CGPoint(x: startBarX, y: self.frame.height - 4), radius: CGFloat(3.0), startAngle: CGFloat(0.0), endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        startBarShapeLayer.path = startBarPath.CGPath
        startBarShapeLayer.strokeColor = UIColor.redColor().CGColor
        startBarShapeLayer.fillColor = UIColor.redColor().CGColor
        startBarShapeLayer.lineWidth = 1
        layer.addSublayer(startBarShapeLayer)
        
        // draw end bar
        let endBarPath = UIBezierPath()
        endBarPath.moveToPoint(CGPoint(x: endBarX, y: 22))
        endBarPath.addLineToPoint(CGPoint(x: endBarX, y: self.frame.height - 7))
        endBarPath.moveToPoint(CGPoint(x: endBarX, y: 19))
        endBarPath.addArcWithCenter(CGPoint(x: endBarX, y: 19), radius: CGFloat(3.0), startAngle: CGFloat(0.0), endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        endBarPath.moveToPoint(CGPoint(x: endBarX, y: self.frame.height - 4))
        endBarPath.addArcWithCenter(CGPoint(x: endBarX, y: self.frame.height - 4), radius: CGFloat(3.0), startAngle: CGFloat(0.0), endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        endBarShapeLayer.path = endBarPath.CGPath
        endBarShapeLayer.strokeColor = UIColor.redColor().CGColor
        endBarShapeLayer.fillColor = UIColor.redColor().CGColor
        endBarShapeLayer.lineWidth = 1
        layer.addSublayer(endBarShapeLayer)
        
        setNeedsDisplay()
    }
    
    func exitTrimMode() {
        isInTrimMode = false
        self.userInteractionEnabled = false
        startBarX = self.frame.width / 10.0
        endBarX = self.frame.width * 9.0 / 10.0
        startBarShapeLayer.removeFromSuperlayer()
        endBarShapeLayer.removeFromSuperlayer()
        middleSquareShapeLayer.removeFromSuperlayer()
        setNeedsDisplay()
    }
    
    func checkBarDistance(withStart start: CGFloat, end: CGFloat) -> Bool {
        //check pixel distance first
        if end - start <= 6.0 {
            return false
        }
        
        //then check duration not less than 0.1 seconds
        let supervw = (self.superview?.superview as! WaveformEditView) //this line hurts my ego...
        var startTime = (((start - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
        if startTime < 0.0 {
            startTime = 0.0
        }
        
        var endTime = (((end - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
        if endTime > CGFloat(supervw.audioFile.duration) {
            endTime = CGFloat(supervw.audioFile.duration)
        }
        
        print("endTIME: \(endTime)")
        if endTime - startTime <= 0.1 {
            return false
        }
        
        return true
    }
    
    func createBarAnimation(withX x: CGFloat, duration: Double) -> CABasicAnimation {
        // creates animation for either trim bar.
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = duration
        
        // create new path
        let newBarPath = UIBezierPath()
        newBarPath.moveToPoint(CGPoint(x: x, y: 22))
        newBarPath.addLineToPoint(CGPoint(x: x, y: self.frame.height - 7))
        newBarPath.moveToPoint(CGPoint(x: x, y: 19))
        newBarPath.addArcWithCenter(CGPoint(x: x, y: 19), radius: CGFloat(3.0), startAngle: CGFloat(0.0), endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        newBarPath.moveToPoint(CGPoint(x: x, y: self.frame.height - 4))
        newBarPath.addArcWithCenter(CGPoint(x: x, y: self.frame.height - 4), radius: CGFloat(3.0), startAngle: CGFloat(0.0), endAngle: CGFloat(2.0 * M_PI), clockwise: true)
        
        animation.toValue = newBarPath.CGPath
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fillMode = kCAFillModeForwards
        animation.removedOnCompletion = false
        
        return animation
    }
    
    func createMidSquareAnimation(withX x: CGFloat, width: CGFloat, duration: Double) -> CABasicAnimation {
        // creates animation for grey middle square.
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = duration
        
        // create new path
        let newMidSquarePath = UIBezierPath(rect: CGRectMake(x, 22, width, self.frame.height - 29))
        animation.toValue = newMidSquarePath.CGPath
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fillMode = kCAFillModeForwards
        animation.removedOnCompletion = false
        
        return animation
    }
    
    func animateDidTouchStartBar() {
        let barAnimation = createBarAnimation(withX: endBarX, duration: 0.3)
        let midSquareAnimation = createMidSquareAnimation(withX: startBarX, width: endBarX - startBarX, duration: 0.3)
        endBarShapeLayer.addAnimation(barAnimation, forKey: nil)
        middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
    }
    
    func animateDidTouchEndBar() {
        // animates the start bar to just off screen (end bar was touched)
        let barAnimation = createBarAnimation(withX: startBarX, duration: 0.3)
        let midSquareAnimation = createMidSquareAnimation(withX: startBarX, width: endBarX - startBarX, duration: 0.3)
        startBarShapeLayer.addAnimation(barAnimation, forKey: nil)
        middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
    }
    
    func animateResetBars() {
        let startBarAnimation = createBarAnimation(withX: startBarX, duration: 0.3)
        let endBarAnimation = createBarAnimation(withX: endBarX, duration: 0.3)
        startBarShapeLayer.addAnimation(startBarAnimation, forKey: nil)
        endBarShapeLayer.addAnimation(endBarAnimation, forKey: nil)
        
        let midSquareAnimation = createMidSquareAnimation(withX: startBarX, width: endBarX - startBarX, duration: 0.3)
        middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
    }

    
    func currentStartTime() -> CMTime {
        let supervw = (self.superview?.superview as! WaveformEditView) //this line hurts my ego...
        var startTime = (((startBarX - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
        if startTime < 0.0 {
            startTime = 0.0
        }
        return CMTimeMakeWithSeconds(Float64(startTime), 10000)
    }
    
    func currentEndTime() -> CMTime {
        let supervw = (self.superview?.superview as! WaveformEditView)
        var endTime = (((endBarX - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
        if endTime > CGFloat(supervw.audioFile.duration) {
            endTime = CGFloat(supervw.audioFile.duration)
        }
        return CMTimeMakeWithSeconds(Float64(endTime), 10000)
    }
    
    func getBarXFromTime(time: CMTime) -> CGFloat {
        let supervw = (self.superview?.superview as! WaveformEditView)
        let barValue = ((CGFloat(time.seconds) / CGFloat(supervw.audioFile.duration)) * supervw.audioPlot.frame.width) - supervw.scrollView.contentOffset.x + (self.frame.width / 10.0)
        return barValue
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touches began timeSelectorView")
        let touch = touches.first!
        let location: CGPoint = touch.locationInView(touch.window)
        let supervw = (superview!.superview as! WaveformEditView)
        
        if location.x < self.frame.width * 2.0 / 10.0 {
            didTouchStartTrimBar = true
            curEndTime = currentEndTime()
            // zoom 3x for better trimming accuracy
            let newEndTime = CMTimeAdd(currentStartTime(), CMTimeMultiplyByRatio(supervw.timeWindow, 1, 3))
            supervw.setTimeRange(currentStartTime(), end: newEndTime)
            endBarX = getBarXFromTime(curEndTime)
            animateDidTouchStartBar()
        } else if location.x > self.frame.width * 8.0 / 10.0 {
            didTouchEndTrimBar = true
            curStartTime = currentStartTime()
            let newStartTime = CMTimeSubtract(currentEndTime(), CMTimeMultiplyByRatio(supervw.timeWindow, 1, 3))
            supervw.setTimeRange(newStartTime, end: currentEndTime())
            startBarX = getBarXFromTime(curStartTime)
            animateDidTouchEndBar()
        }
        
        startTouch = location
        lastTouch = startTouch
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touches moved timeSelectorView")
        let touch = touches.first!
        let location: CGPoint = touch.locationInView(touch.window)
        let deltaDirection = location.x - lastTouch.x
        // drag start or end bar
        if didTouchStartTrimBar {
            let newStartX = (self.frame.width / 10.0) + location.x - startTouch.x
            // if new X does not bring bars too close together, move and/or scroll
            if checkBarDistance(withStart: newStartX, end: endBarX) {
                if newStartX - (self.frame.width * 2.0 / 10.0) < 0 && deltaDirection <= 0 {
                    //scroll left
                    (superview!.superview as! WaveformEditView).scrollWithAcceleration(newStartX - (superview!.frame.width * 2.0 / 10.0), direction: true)
                    print("scroll left")
                } else if newStartX - (self.frame.width * 8.0 / 10.0) > 0 && deltaDirection >= 0 {
                    // scroll right
                    (superview!.superview as! WaveformEditView).scrollWithAcceleration(newStartX - (superview!.frame.width * 8.0 / 10.0), direction: false)
                    print("scroll right")
                } else {
                    (superview!.superview as! WaveformEditView).stopScrolling()
                }
                
                startBarX = newStartX
                let barAnimation = createBarAnimation(withX: startBarX, duration: 0.00001)
                print("SECOND: \(endBarX)")
                let midSquareAnimation = createMidSquareAnimation(withX: startBarX, width: endBarX - startBarX, duration: 0.00001)
                startBarShapeLayer.addAnimation(barAnimation, forKey: nil)
                middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
                setNeedsDisplay()
            }
        } else if didTouchEndTrimBar {
            let newEndX = (superview!.frame.width * 9.0 / 10.0) + location.x - startTouch.x
            if checkBarDistance(withStart: startBarX, end: newEndX) {
                if newEndX - (superview!.frame.width * 2.0 / 10.0) < 0 && deltaDirection < 0 {
                    //scroll left
                    (superview!.superview as! WaveformEditView).scrollWithAcceleration(newEndX - (superview!.frame.width * 2.0 / 10.0), direction: true)
                    print("scroll left")
                } else if newEndX - (superview!.frame.width * 8.0 / 10.0) > 0 && deltaDirection > 0 {
                    // scroll right
                    (superview!.superview as! WaveformEditView).scrollWithAcceleration(newEndX - (superview!.frame.width * 8.0 / 10.0), direction: false)
                    print("scroll right")
                } else {
                    (superview!.superview as! WaveformEditView).stopScrolling()
                }
                endBarX = newEndX
                let barAnimation = createBarAnimation(withX: endBarX, duration: 0.00001)
                endBarShapeLayer.addAnimation(barAnimation, forKey: nil)
                let midSquareAnimation = createMidSquareAnimation(withX: startBarX, width: endBarX - startBarX, duration: 0.00001)
                middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
                setNeedsDisplay()
            }
        }
        lastTouch = location
        // TODO: set a minimum limit for track length. Like .1 of a second possibly.
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("touches ended timeSelectorView")
        // readjust with new time window from start bar to end bar
        let supervw = (self.superview?.superview as! WaveformEditView)
        supervw.stopScrolling()
        if didTouchStartTrimBar {
            didTouchStartTrimBar = false
            var newStartTime = (((startBarX - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
            if newStartTime < 0.0 {
                newStartTime = 0.0
            }

            print("start: ", terminator: "")
            print(newStartTime)
            print("end: ", terminator: "")
            print(curEndTime)

            curStartTime = CMTimeMakeWithSeconds(Float64(newStartTime), 10000)

        } else if didTouchEndTrimBar {
            didTouchEndTrimBar = false
            var newEndTime = (((endBarX - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
            if newEndTime > CGFloat(supervw.audioFile.duration) {
                newEndTime = CGFloat(supervw.audioFile.duration)
            }
            
            curEndTime = CMTimeMakeWithSeconds(Float64(newEndTime), 10000)
        }
        
        if curStartTime != nil && curEndTime != nil {
            supervw.setTimeRange(curStartTime, end: curEndTime)
        }
        
        //reset bars
        startBarX = self.frame.width / 10.0
        endBarX = self.frame.width * 9.0 / 10.0
        animateResetBars()
        setNeedsDisplay()
    }
    
    
    override func drawRect(rect: CGRect) {
        // Draw center line for playback
        if isInTrimMode {
            // draw time labels
            let startTime = currentStartTime()
            let endTime = currentEndTime()
            let stringAttrs = [NSFontAttributeName : UIFont.systemFontOfSize(13.0), NSForegroundColorAttributeName : UIColor.whiteColor()]
            let format = NSDateFormatter()
            if endTime.seconds >= 3600 {
                format.dateFormat = "H:mm:ss:SS"
            } else {
                format.dateFormat = "mm:ss:SS"
            }
            
            //create start time label
            let startDate = NSDate(timeIntervalSince1970: startTime.seconds)
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            var text = format.stringFromDate(startDate)
            let attrStrStart: NSAttributedString = NSAttributedString(string: text, attributes: stringAttrs)
            
            // create end time label
            let endDate = NSDate(timeIntervalSince1970: endTime.seconds)
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            text = format.stringFromDate(endDate)
            let attrStrEnd = NSAttributedString(string: text, attributes: stringAttrs)
            
            // draw labels with proper adjustments to avoid overlap
            var adjustStartX = CGFloat(0.0)
            if didTouchStartTrimBar {
                if startBarX + attrStrStart.size().width > endBarX - attrStrEnd.size().width - 5.0 {
                    adjustStartX = (startBarX + attrStrStart.size().width) - (endBarX - attrStrEnd.size().width - 5.0)
                }
            }
            attrStrStart.drawAtPoint(CGPoint(x: startBarX - CGFloat(4) - adjustStartX, y: 1))
            
            var adjustEndX = CGFloat(0.0)
            if didTouchEndTrimBar {
                if endBarX - attrStrEnd.size().width - 5.0 < startBarX + attrStrStart.size().width {
                    adjustEndX = (startBarX + attrStrStart.size().width) - (endBarX - attrStrEnd.size().width - 5.0)
                }
            }
            attrStrEnd.drawAtPoint(CGPoint(x: endBarX - attrStrEnd.size().width + CGFloat(4) + adjustEndX, y: 1))

        } else {
            // draw playback bar
            let context = UIGraphicsGetCurrentContext()
            CGContextBeginPath(context)
            CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
            CGContextSetLineWidth(context, 1)
            CGContextMoveToPoint(context, self.frame.width / 2.0, 22)
            CGContextAddLineToPoint(context, self.frame.width / 2.0, self.frame.height - 7)
            CGContextStrokePath(context)
            
            // draw end circles
            CGContextSetFillColorWithColor(context, UIColor.blueColor().CGColor)
            CGContextBeginPath(context)
            CGContextAddArc(context, self.frame.width / 2.0, CGFloat(19.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
            CGContextFillPath(context)
            
            CGContextBeginPath(context)
            CGContextAddArc(context, self.frame.width / 2.0, self.frame.height - CGFloat(4.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
            CGContextFillPath(context)
        }
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if isInTrimMode {
            if point.x < self.frame.width * 2.0 / 10.0 || point.x > self.frame.width * 8.0 / 10.0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }

    }
}

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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.userInteractionEnabled = false
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.userInteractionEnabled = false
    }
    
    func trimMode() {
        isInTrimMode = true
        self.userInteractionEnabled = true
        startBarX = self.frame.width / 10.0
        endBarX = self.frame.width * 9.0 / 10.0
        setNeedsDisplay()
    }
    
    func exitTrimMode() {
        isInTrimMode = false
        self.userInteractionEnabled = false
        startBarX = self.frame.width / 10.0
        endBarX = self.frame.width * 9.0 / 10.0
        setNeedsDisplay()
    }
    
    func currentStartTime() -> CMTime {
        // readjust with new time window from start bar to end bar
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
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("touches began timeSelectorView")
        let touch = touches.first as! UITouch
        let location: CGPoint = touch.locationInView(touch.window)
        let supervw = (superview!.superview as! WaveformEditView)
        
        if location.x < self.frame.width * 2.0 / 10.0 {
            didTouchStartTrimBar = true
            curEndTime = currentEndTime()
            // zoom 3x for better trimming accuracy
            supervw.setTimeRange(currentStartTime(), end: CMTimeAdd(currentStartTime(), CMTimeMultiplyByRatio(supervw.timeWindow, 1, 3)))
            if (endBarX != nil) {
                endBarX! *= CGFloat(3.0)
            }
        } else if location.x > self.frame.width * 8.0 / 10.0 {
            didTouchEndTrimBar = true
            curStartTime = currentStartTime()
            supervw.setTimeRange(CMTimeSubtract(currentEndTime(), CMTimeMultiplyByRatio(supervw.timeWindow, 1, 3)), end: currentEndTime())
            if (startBarX != nil) {
                startBarX! *= -CGFloat(3.0)
            }
        }
        
        startTouch = location
        lastTouch = startTouch
        setNeedsDisplay()
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("touches moved timeSelectorView")
        let touch = touches.first as! UITouch
        let location: CGPoint = touch.locationInView(touch.window)
        let deltaDirection = location.x - lastTouch.x
        print("DELTA: ")
        println(deltaDirection)
        // drag start or end bar
        if didTouchStartTrimBar {
            let newStartX = (superview!.frame.width / 10.0) + location.x - startTouch.x
            if newStartX - (superview!.frame.width * 2.0 / 10.0) < 0 && deltaDirection < 0 {
                //scroll left
                (superview!.superview as! WaveformEditView).scrollWithAcceleration(newStartX - (superview!.frame.width * 2.0 / 10.0), direction: true)
                println("scroll left")
            } else if newStartX - (superview!.frame.width * 8.0 / 10.0) > 0 && deltaDirection > 0 {
                // scroll right
                (superview!.superview as! WaveformEditView).scrollWithAcceleration(newStartX - (superview!.frame.width * 8.0 / 10.0), direction: false)
                println("scroll right")
            } else {
                (superview!.superview as! WaveformEditView).stopScrolling()
            }
            print("start: ")
            println(newStartX)
            startBarX! = newStartX
            setNeedsDisplay()
        } else if didTouchEndTrimBar {
            let newEndX = (superview!.frame.width * 9.0 / 10.0) + location.x - startTouch.x
            print("end: ")
            println(newEndX)
            if newEndX - (superview!.frame.width * 2.0 / 10.0) < 0 && deltaDirection < 0 {
                //scroll left
                (superview!.superview as! WaveformEditView).scrollWithAcceleration(newEndX - (superview!.frame.width * 2.0 / 10.0), direction: true)
                println("scroll left")
            } else if newEndX - (superview!.frame.width * 8.0 / 10.0) > 0 && deltaDirection > 0 {
                // scroll right
                (superview!.superview as! WaveformEditView).scrollWithAcceleration(newEndX - (superview!.frame.width * 8.0 / 10.0), direction: false)
                println("scroll right")
            } else {
                (superview!.superview as! WaveformEditView).stopScrolling()
            }
            endBarX! = newEndX
            setNeedsDisplay()
        }
        lastTouch = location
        // TODO: set a minimum limit for track length. Like .1 of a second possibly.
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("touches ended timeSelectorView")
        // readjust with new time window from start bar to end bar
        let supervw = (self.superview?.superview as! WaveformEditView)
        supervw.stopScrolling()
        if didTouchStartTrimBar {
            didTouchStartTrimBar = false
            var newStartTime = (((startBarX - (self.frame.width / 10.0) + supervw.scrollView.contentOffset.x) / supervw.audioPlot.frame.width) * CGFloat(supervw.audioFile.duration))
            if newStartTime < 0.0 {
                newStartTime = 0.0
            }

            print("start: ")
            println(newStartTime)
            print("end: ")
            println(curEndTime)

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
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        // Draw center line for playback
        if isInTrimMode {
            // draw startbar
            var context = UIGraphicsGetCurrentContext()
            CGContextBeginPath(context)
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            CGContextSetLineWidth(context, 1)
            CGContextMoveToPoint(context, startBarX, 0)
            CGContextAddLineToPoint(context, startBarX, self.frame.height)
            CGContextStrokePath(context)
            
            CGContextSetFillColorWithColor(context, UIColor.redColor().CGColor)
            CGContextBeginPath(context)
            CGContextAddArc(context, startBarX, CGFloat(3.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
            CGContextFillPath(context)
            
            CGContextBeginPath(context)
            CGContextAddArc(context, startBarX, self.frame.height - CGFloat(3.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
            CGContextFillPath(context)
            
            // draw endbar
            CGContextBeginPath(context)
            CGContextSetLineWidth(context, 1)
            CGContextMoveToPoint(context, endBarX, 0)
            CGContextAddLineToPoint(context, endBarX, self.frame.height)
            CGContextStrokePath(context)
            
            CGContextBeginPath(context)
            CGContextAddArc(context, endBarX, CGFloat(3.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
            CGContextFillPath(context)
            
            CGContextBeginPath(context)
            CGContextAddArc(context, endBarX, self.frame.height - CGFloat(3.0), CGFloat(3.0), CGFloat(0.0), CGFloat(2.0 * M_PI), 1)
            CGContextFillPath(context)
            
            // draw middle square
            CGContextBeginPath(context)
            CGContextSetFillColorWithColor(context, UIColor.blackColor().colorWithAlphaComponent(0.2).CGColor)
            CGContextAddRect(context, CGRectMake(startBarX, 6, endBarX - startBarX, self.frame.height - 12))
            CGContextFillPath(context)
            
        } else {
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

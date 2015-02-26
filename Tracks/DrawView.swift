//
//  DrawView.swift
//  Tracks
//
//  Created by John Sloan on 2/10/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class DrawView: UIView {

    var allPaths: [[Line]] = []
    var curPath: [Line] = []
    var lastPoint: CGPoint!
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        lastPoint = touches.anyObject()?.locationInView(self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        var newPoint = touches.anyObject()?.locationInView(self)
        curPath.append(Line(start: lastPoint, end: newPoint!))
        lastPoint = newPoint
        
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if (!curPath.isEmpty) {
            allPaths.append(curPath)
        }
        curPath = []
    }

    override func drawRect(rect: CGRect) {
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        for path in allPaths {
            for line in path {
                CGContextMoveToPoint(context, line.start.x, line.start.y)
                CGContextAddLineToPoint(context, line.end.x, line.end.y)
            }
        }
        for line in curPath {
            CGContextMoveToPoint(context, line.start.x, line.start.y)
            CGContextAddLineToPoint(context, line.end.x, line.end.y)
        }
        CGContextSetRGBStrokeColor(context, 0.341, 0.341, 0.341, 1)
        CGContextSetLineWidth(context, 5)
        CGContextStrokePath(context)
    }
    
    func undoDraw() {
        allPaths.removeLast()
        self.setNeedsDisplay()
    }
    
}

//
//  Line.swift
//  Tracks
//
//  Created by John Sloan on 2/9/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class Line: NSObject {
    var start: CGPoint
    var end: CGPoint
    
    init(start _start: CGPoint, end _end: CGPoint) {
        start = _start
        end = _end
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        self.init(start: aDecoder.decodeCGPointForKey("start"), end: aDecoder.decodeCGPointForKey("end"))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeCGPoint(self.start, forKey: "start")
        aCoder.encodeCGPoint(self.end, forKey: "end")
    }
    
    func containsPoint(point: CGPoint) -> Bool {
        var path = UIBezierPath()
        path.moveToPoint(start)
        path.addLineToPoint(end)
        let tmp = CGPathCreateCopyByStrokingPath(path.CGPath, nil, 10, CGLineCap(rawValue: 0)!, CGLineJoin(rawValue: 0)!, 1)
        let fatPath = UIBezierPath(CGPath: tmp!)
        if fatPath.containsPoint(point) {
            return true
        }
        return false
    }
    
}
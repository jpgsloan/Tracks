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
    
}
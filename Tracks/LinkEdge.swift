//
//  LinkEdge.swift
//  Tracks
//
//  Created by John Sloan on 5/8/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class LinkEdge: NSObject {
   
    var startTrackNode: Track!
    var endTrackNode: Track!
    
    init (startTrackNode: Track, endTrackNode: Track) {
        self.startTrackNode = startTrackNode
        self.endTrackNode = endTrackNode
    }
    
    func containsPoint(point: CGPoint) -> Bool {
        var path = UIBezierPath()
        path.moveToPoint(startTrackNode.center)
        path.addLineToPoint(endTrackNode.center)
        let tmp = CGPathCreateCopyByStrokingPath(path.CGPath, nil, 15, CGLineCap(0), CGLineJoin(0), 1)
        let fatPath = UIBezierPath(CGPath: tmp)
        if fatPath.containsPoint(point) {
            return true
        }
        return false
    }
}

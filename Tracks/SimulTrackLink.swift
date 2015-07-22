//
//  SimulTrackLink.swift
//  Tracks
//
//  Created by John Sloan on 5/8/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore

class SimulTrackLink: UIView {

    var trackNodes: Array<Track> = [Track]()
    var linkEdges: Array<LinkEdge> = [LinkEdge]()
    var curTouchedTrack: Track!
    var mode: String = ""
    var startTrackNode: Track!
    var queuedTrackForAdding: Track!
    var wasDragged: Bool = false
    var curTouchLoc: CGPoint!
    var touchHitEdge: Bool = false
    
    init (frame: CGRect, withTrack track: Track) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        trackNodes.append(track)
        self.setNeedsDisplay()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func touchBegan(touches: NSSet, withEvent event: UIEvent) {
        println("TOUCHED TRACK LINK!")
        var touch: UITouch = touches.anyObject() as! UITouch
        var touchLoc: CGPoint = touch.locationInView(self)
        
        if mode == "ADD_SIMUL_LINK" {
            for track in trackNodes {
                if track.frame.contains(touchLoc) {
                    curTouchedTrack = track
                }
            }
            startTrackNode = curTouchedTrack
            self.curTouchLoc = touchLoc
        } else {
            var didTouchTrack = false
            touchHitEdge = true
            for track in trackNodes {
                if track.frame.contains(touchLoc) {
                    self.curTouchedTrack = track
                    didTouchTrack = true
                    touchHitEdge = false
                } else {
                    track.touchBegan(touches, withEvent: event)
                }
            }
            //touch current track last and readjust subviews for proper ordering.
            if didTouchTrack {
                self.curTouchedTrack.touchBegan(touches, withEvent: event)
            }
            var supervw = self.superview!
            supervw.insertSubview(self, atIndex: supervw.subviews.count - 4)
        }
    }

    func touchMoved(touches: NSSet, withEvent event: UIEvent) {
        println("TOUCHED TRACKLINK MOVED")
        var touch: UITouch = touches.anyObject() as! UITouch
        var touchLoc: CGPoint = touch.locationInView(self)

        if mode == "ADD_SIMUL_LINK" {
            self.curTouchLoc = touchLoc
            self.setNeedsDisplay()
        } else {
            if touchHitEdge {
                for track in trackNodes {
                    track.touchMoved(touches, withEvent: event)
                }
            } else {
                self.curTouchedTrack.touchMoved(touches, withEvent: event)
            }
            self.wasDragged = true
            self.setNeedsDisplay()
        }
    }
    
    func touchEnded(touches: NSSet, withEvent event: UIEvent) {
        if mode == "ADD_SIMUL_LINK" {
            self.curTouchLoc = nil
            self.curTouchedTrack = nil
        } else {
            if wasDragged {
                println("TOUCHED TRACK LINK ENDED")
                if touchHitEdge {
                    for track in trackNodes {
                        track.touchEnded(touches, withEvent: event)
                    }
                    self.wasDragged = false
                    self.setNeedsDisplay()
                } else {
                    self.wasDragged = false
                    self.curTouchedTrack.touchEnded(touches, withEvent: event)
                    self.curTouchedTrack = nil
                    self.setNeedsDisplay()
                }
            } else {
                for track in self.trackNodes {
                    track.touchEnded(touches, withEvent: event)
                }
            }
        }
    }
    
    func queueTrackForAdding(track: Track) {
        self.queuedTrackForAdding = track
        self.setNeedsDisplay()
    }
    
    func dequeueTrackFromAdding() {
        self.queuedTrackForAdding.layer.borderWidth = 0
        self.queuedTrackForAdding.layer.borderColor = UIColor.clearColor().CGColor
        self.queuedTrackForAdding = nil
        self.setNeedsDisplay()
    }
    
    func commitEdgeToLink() {
        println("ADDING TRACK!")
        self.trackNodes.append(self.queuedTrackForAdding)
        var newEdge = LinkEdge(startTrackNode: self.startTrackNode, endTrackNode: self.queuedTrackForAdding)
        self.linkEdges.append(newEdge)
        dequeueTrackFromAdding()
        self.setNeedsDisplay()
    }
    
    func prepareForDelete() {
        for track in trackNodes {
            track.layer.borderColor = UIColor.clearColor().CGColor
            track.layer.borderWidth = 0
        }
    }
    
    override func drawRect(rect: CGRect) {
        drawLinkEdges()
        drawTrackNodeOutlines()
        if mode == "ADD_SIMUL_LINK" && self.curTouchedTrack != nil {
            drawCurLinkAdd()
        }
    }
    
    func drawTrackNodeOutlines() {
        for node in trackNodes {
            /*var outLineFrame = node.frame
            var strokeColor = UIColor.blueColor()//.colorWithAlphaComponent(0.5)
            strokeColor.setStroke()
            var outline = UIBezierPath(roundedRect: outLineFrame, cornerRadius: 12)
            outline.lineWidth = 5
            outline.stroke()*/
            node.layer.borderColor = UIColor.blueColor().CGColor
            node.layer.borderWidth = 5
        }
        if self.queuedTrackForAdding != nil {
            /*var outLineFrame = self.queuedTrackForAdding.frame
            var strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
            strokeColor.setStroke()
            var outline = UIBezierPath(roundedRect: outLineFrame, cornerRadius: 12)
            outline.lineWidth = 5
            outline.stroke()*/
            self.queuedTrackForAdding.layer.borderColor = UIColor.blueColor().colorWithAlphaComponent(0.4).CGColor
            self.queuedTrackForAdding.layer.borderWidth = 5
        }
    }
    
    func drawLinkEdges() {
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().colorWithAlphaComponent(1).CGColor)
        CGContextSetLineWidth(context, 8)
        for linkEdge in self.linkEdges {
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, linkEdge.startTrackNode.center.x, linkEdge.startTrackNode.center.y)
            CGContextAddLineToPoint(context, linkEdge.endTrackNode.center.x, linkEdge.endTrackNode.center.y)
            CGContextStrokePath(context)
            
            CGContextClearRect(context, linkEdge.startTrackNode.frame)
            CGContextClearRect(context, linkEdge.endTrackNode.frame)
        }
    }
    
    func drawCurLinkAdd() {
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, self.curTouchedTrack.center.x, self.curTouchedTrack.center.y)
        CGContextAddLineToPoint(context, self.curTouchLoc.x, self.curTouchLoc.y)
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().colorWithAlphaComponent(1).CGColor)
        CGContextSetLineWidth(context, 8)
        CGContextStrokePath(context)
        CGContextClearRect(context, self.curTouchedTrack.frame)
        if self.queuedTrackForAdding != nil {
            CGContextClearRect(context, self.queuedTrackForAdding.frame)
        }
    }
    
    func deleteSimulTrackLink() {
        for track in trackNodes {
            track.layer.borderWidth = 0
        }
        self.removeFromSuperview()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for track in trackNodes {
            if track.frame.contains(point) {
                return true
            }
        }
        for edge in linkEdges {
            if edge.containsPoint(point) {
                return true
            }
        }
        return false
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        for track in trackNodes {
            if track.frame.contains(point) {
                return self
            }
        }
        for edge in linkEdges {
            if edge.containsPoint(point) {
                return self
            }
        }
        return nil
    }
    
}

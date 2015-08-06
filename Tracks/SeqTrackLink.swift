//
//  SeqTrackLink.swift
//  Tracks
//
//  Created by John Sloan on 5/8/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class SeqTrackLink: UIView, AVAudioPlayerDelegate {

    var trackNodeIDs: [AVAudioPlayer:SeqTrackNode] = [AVAudioPlayer:SeqTrackNode]()
    var rootTrackID: String!
    var rootTrackAudioPlayer: AVAudioPlayer!
    var mode = ""
    var seqLinkID = ""
    var curTouchedTrack: Track!
    var curTouchLoc: CGPoint!
    var touchHitEdge: Bool = false
    var wasDragged: Bool = false
    var queuedTrackForAdding: Track!
    
    init (frame: CGRect, withTrack track: Track) {
        super.init(frame: frame)
        
        //Set the link id
        if seqLinkID.isEmpty {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
            seqLinkID = "seqlink-" + formatter.stringFromDate(currentDateTime)
        }
        
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        rootTrackID = track.trackID
        rootTrackAudioPlayer = track.audioPlayer
        var rootNode = SeqTrackNode(track: track)
        trackNodeIDs[rootTrackAudioPlayer] = rootNode
        setNeedsDisplay()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        println("finished playing!!!")
        var node = trackNodeIDs[player]!
        for childID in node.childrenIDs {
            var child = (self.superview as! LinkManager).getTrackByID(childID)
            child?.audioPlayer.delegate = self
            child?.playAudio()
        }
    }
    
    func touchBegan(touches: NSSet, withEvent event: UIEvent) {
        println("TOUCHED SEQ TRACK LINK BEGAN")
        var touch: UITouch = touches.anyObject() as! UITouch
        var touchLoc: CGPoint = touch.locationInView(self)
        
        if mode == "ADD_SEQ_LINK" {
            var highestIndex = -1
            for audioPlayer in trackNodeIDs.keys {
                var trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                var track = (self.superview as! LinkManager).getTrackByID(trackID)
                var trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
                if trackIndex > highestIndex && track!.frame.contains(touchLoc) {
                    highestIndex = trackIndex
                    curTouchedTrack = track
                }
            }
            curTouchLoc = touchLoc
        } else {
            var didTouchTrack = false
            touchHitEdge = true
            
            //Make a dictionary of the track nodes with the current z-order index
            var trackSubviews = [Int: Track]()
            for audioPlayer in trackNodeIDs.keys {
                var trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                var track = (self.superview as! LinkManager).getTrackByID(trackID)
                var trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
                trackSubviews[trackIndex] = track!
            }
            
            //Now iterate through dictionary, sorted by keys(index), to distribute touch, and check if touch landed on an edge or a node.
            var sortedKeys = Array(trackSubviews.keys).sorted(<)
            for index in sortedKeys {
                var track = (trackSubviews[index] as Track!)
                if track.frame.contains(touchLoc) {
                    curTouchedTrack = track
                    didTouchTrack = true
                    touchHitEdge = false
                    track.touchBegan(touches, withEvent: event)
                } else {
                    track.touchBegan(touches, withEvent: event)
                }
            }
            
            //touch current track last and readjust simullink index for proper ordering.
            if didTouchTrack {
                curTouchedTrack.touchBegan(touches, withEvent: event)
            }
            var supervw = self.superview!
            supervw.insertSubview(self, atIndex: supervw.subviews.count - 4)
            self.setNeedsDisplay()
        }
    }

    func touchMoved(touches: NSSet, withEvent event: UIEvent) {
        println("TOUCHED SEQ TRACKLINK MOVED")
        var touch: UITouch = touches.anyObject() as! UITouch
        var touchLoc: CGPoint = touch.locationInView(self)
        
        if mode == "ADD_SEQ_LINK" {
            curTouchLoc = touchLoc
            self.setNeedsDisplay()
        } else {
            if touchHitEdge {
                for audioPlayer in trackNodeIDs.keys {
                    var trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                    var track = (self.superview as! LinkManager).getTrackByID(trackID)
                    track!.touchMoved(touches, withEvent: event)
                }
            } else {
                curTouchedTrack.touchMoved(touches, withEvent: event)
            }
            wasDragged = true
            self.setNeedsDisplay()
        }
    }
    
    func touchEnded(touches: NSSet, withEvent event: UIEvent) {
        if mode == "ADD_SEQ_LINK" {
            curTouchLoc = nil
            curTouchedTrack = nil
        } else {
            if wasDragged {
                println("TOUCHED TRACK LINK ENDED")
                if touchHitEdge {
                    for audioPlayer in trackNodeIDs.keys {
                        var trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                        var track = (self.superview as! LinkManager).getTrackByID(trackID)
                        track!.touchEnded(touches, withEvent: event)
                    }
                    wasDragged = false
                } else {
                    wasDragged = false
                    curTouchedTrack.touchEnded(touches, withEvent: event)
                    curTouchedTrack = nil
                }
            } else {
                println("PLAY HERE")
                beginPlaySequence(fromStartTrack: curTouchedTrack)
                curTouchedTrack = nil
            }
            self.setNeedsDisplay()
        }
    }
    
    func beginPlaySequence(fromStartTrack startTrack: Track) {
        for audioPlayer in trackNodeIDs.keys {
            var node = trackNodeIDs[audioPlayer]!
            var trackID = node.rootTrackID
            if trackID == startTrack.trackID {
                startTrack.audioPlayer.delegate = self
                startTrack.playAudio()
            }
        }
    }
    
    func queueTrackForAdding(track: Track) {
        self.queuedTrackForAdding = track
        self.setNeedsDisplay()
    }
    
    func dequeueTrackFromAdding() {
        if queuedTrackForAdding != nil {
            queuedTrackForAdding.layer.borderWidth = 0
            queuedTrackForAdding.layer.borderColor = UIColor.clearColor().CGColor
            queuedTrackForAdding = nil
            self.setNeedsDisplay()
        }
    }
    
    func commitEdgeToLink() {
        println("ADDING TRACK TO SEQ LINK!")
        //Add queued track to dictionary as a new node
        var newNode = SeqTrackNode(track: queuedTrackForAdding)
        trackNodeIDs[queuedTrackForAdding.audioPlayer] = newNode
        
        //Add queued track to children array of curTouchedTrack
        for audioPlayer in trackNodeIDs.keys {
            var node = trackNodeIDs[audioPlayer]!
            if node.rootTrackID == curTouchedTrack.trackID {
                println("appending child")
                node.childrenIDs.append(queuedTrackForAdding.trackID)
            }
        }
        
        dequeueTrackFromAdding()
        self.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        drawLinkEdges()
        drawTrackNodeOutlines()
        if mode == "ADD_SEQ_LINK" && curTouchedTrack != nil {
            drawCurLinkAdd()
        }
    }
    
    func drawLinkEdges() {
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().colorWithAlphaComponent(1).CGColor)
        CGContextSetLineWidth(context, 8)
        
        for audioPlayer in trackNodeIDs.keys {
            
            var node = trackNodeIDs[audioPlayer]!
            var trackID = node.rootTrackID
            var startTrack = (self.superview as! LinkManager).getTrackByID(trackID)
            
            for childTrackID in node.childrenIDs {
                var endTrack = (self.superview as! LinkManager).getTrackByID(childTrackID)
                //For each child, paint line from parent track node.
                CGContextBeginPath(context)
                CGContextMoveToPoint(context, startTrack!.center.x, startTrack!.center.y)
                CGContextAddLineToPoint(context, endTrack!.center.x, endTrack!.center.y)
                CGContextStrokePath(context)
            }
        }
    }
    
    func eraseLineOnTrack(track: Track) {
        //Draws clear fill over track node to erase link line from center to edge of node.
        var outLineFrame = track.frame
        var outline = UIBezierPath(roundedRect: outLineFrame, cornerRadius: 12)
        outline.fillWithBlendMode(kCGBlendModeClear, alpha: 1)
    }
    
    func drawTrackNodeOutlines() {
        for audioPlayer in trackNodeIDs.keys {
            var trackID = trackNodeIDs[audioPlayer]!.rootTrackID
            var track = (self.superview as! LinkManager).getTrackByID(trackID)
            track!.layer.borderColor = UIColor.redColor().CGColor
            track!.layer.borderWidth = 5
            eraseLineOnTrack(track!)
        }
        if self.queuedTrackForAdding != nil {
            self.queuedTrackForAdding.layer.borderColor = UIColor.redColor().colorWithAlphaComponent(0.4).CGColor
            self.queuedTrackForAdding.layer.borderWidth = 5
        }
    }
    
    func drawCurLinkAdd() {
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, curTouchedTrack.center.x, curTouchedTrack.center.y)
        CGContextAddLineToPoint(context, curTouchLoc.x, curTouchLoc.y)
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().colorWithAlphaComponent(1).CGColor)
        CGContextSetLineWidth(context, 8)
        CGContextStrokePath(context)
        eraseLineOnTrack(curTouchedTrack)
        if queuedTrackForAdding != nil {
            eraseLineOnTrack(queuedTrackForAdding)
        }
    }
    
    func deleteSeqTrackLink() {
        for audioPlayer in trackNodeIDs.keys {
            var trackID = trackNodeIDs[audioPlayer]!.rootTrackID
            var track = (self.superview as! LinkManager).getTrackByID(trackID)
            track!.layer.borderColor = UIColor.clearColor().CGColor
            track!.layer.borderWidth = 0
        }
        self.removeFromSuperview()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for audioPlayer in trackNodeIDs.keys {
            var node = trackNodeIDs[audioPlayer]!
            var trackID = node.rootTrackID
            var startTrack = (self.superview as! LinkManager).getTrackByID(trackID)
            if startTrack!.frame.contains(point) {
                return true
            }
            for childTrackID in node.childrenIDs {
                var endTrack = (self.superview as! LinkManager).getTrackByID(childTrackID)
                var edge = LinkEdge(startTrackNode: startTrack!, endTrackNode: endTrack!)
                if edge.containsPoint(point) {
                    return true
                }
            }
        }
        return false
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        for audioPlayer in trackNodeIDs.keys {
            var node = trackNodeIDs[audioPlayer]!
            var trackID = node.rootTrackID
            var startTrack = (self.superview as! LinkManager).getTrackByID(trackID)
            if startTrack!.frame.contains(point) {
                return self
            }
            for childTrackID in node.childrenIDs {
                var endTrack = (self.superview as! LinkManager).getTrackByID(childTrackID)
                var edge = LinkEdge(startTrackNode: startTrack!, endTrackNode: endTrack!)
                if edge.containsPoint(point) {
                    return self
                }
            }
        }
        return nil
    }
}

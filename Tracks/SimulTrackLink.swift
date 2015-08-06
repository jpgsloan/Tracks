//
//  SimulTrackLink.swift
//  Tracks
//
//  Created by John Sloan on 5/8/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore
import CoreData

class SimulTrackLink: UIView {

    var trackNodeIDs: Array<String> = [String]()
    var linkEdges: Array<LinkEdge> = [LinkEdge]()
    var simulLinkID: String = ""
    var curTouchedTrack: Track!
    var mode: String = ""
    var startTrackNode: Track!
    var queuedTrackForAdding: Track!
    var wasDragged: Bool = false
    var curTouchLoc: CGPoint!
    var touchHitEdge: Bool = false
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    init (frame: CGRect, withTrack track: Track) {
        super.init(frame: frame)
        
        //Set the link id
        if simulLinkID.isEmpty {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
            simulLinkID = "link-" + formatter.stringFromDate(currentDateTime)
        }
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        trackNodeIDs.append(track.trackID)
        self.setNeedsDisplay()
    }

    init (frame: CGRect, withTrackIDs trackNodeIDs: Array<String>, linkEdges linkEdges: Array<LinkEdge>, andLinkID simulLinkID: String) {
        super.init(frame: frame)
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        self.simulLinkID = simulLinkID
        self.trackNodeIDs = trackNodeIDs
        
        self.linkEdges = linkEdges
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
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
            var highestIndex = -1
            for trackID in trackNodeIDs {
                var track = (self.superview as! LinkManager).getTrackByID(trackID)
                var trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
                if trackIndex > highestIndex && track!.frame.contains(touchLoc) {
                    highestIndex = trackIndex
                    curTouchedTrack = track
                }
            }
            startTrackNode = curTouchedTrack
            self.curTouchLoc = touchLoc
            var supervw = self.superview!
            supervw.insertSubview(curTouchedTrack, atIndex: supervw.subviews.count - 4)
            supervw.insertSubview(self, atIndex: supervw.subviews.count - 4)
        } else {
            var didTouchTrack = false
            touchHitEdge = true
            
            //Make a dictionary of the track nodes with the current z-order index
            var trackSubviews = [Int: Track]()
            for trackID in trackNodeIDs {
                var track = (self.superview as! LinkManager).getTrackByID(trackID)
                var trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
                trackSubviews[trackIndex] = track!
            }
            
            //Now iterate through dictionary, sorted by keys(index)
            var sortedKeys = Array(trackSubviews.keys).sorted(<)
            for index in sortedKeys {
                var track = (trackSubviews[index] as Track!)
                if track.frame.contains(touchLoc) {
                    self.curTouchedTrack = track
                    didTouchTrack = true
                    touchHitEdge = false
                    track.touchBegan(touches, withEvent: event)
                } else {
                    track.touchBegan(touches, withEvent: event)
                }
            }
            
            //touch current track last and readjust simullink index for proper ordering.
            if didTouchTrack {
                self.curTouchedTrack.touchBegan(touches, withEvent: event)
            }
            var supervw = self.superview!
            supervw.insertSubview(self, atIndex: supervw.subviews.count - 4)
            self.setNeedsDisplay()
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
                for trackID in trackNodeIDs {
                    var track = (self.superview as! LinkManager).getTrackByID(trackID)
                    track!.touchMoved(touches, withEvent: event)
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
                    for trackID in trackNodeIDs {
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
                for trackID in trackNodeIDs {
                    var track = (self.superview as! LinkManager).getTrackByID(trackID)
                    track!.touchEnded(touches, withEvent: event)
                }
            }
            self.setNeedsDisplay()
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
        println("ADDING TRACK!")
        trackNodeIDs.append(queuedTrackForAdding.trackID)
        var newEdge = LinkEdge(startTrackNode: startTrackNode, endTrackNode: queuedTrackForAdding)
        linkEdges.append(newEdge)
        dequeueTrackFromAdding()
        self.setNeedsDisplay()
    }

    override func drawRect(rect: CGRect) {
        drawLinkEdges()
        drawTrackNodeOutlines()
        if mode == "ADD_SIMUL_LINK" && curTouchedTrack != nil {
            drawCurLinkAdd()
        }
    }
    
    func drawLinkEdges() {
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().colorWithAlphaComponent(1).CGColor)
        CGContextSetLineWidth(context, 8)
        for linkEdge in linkEdges {
            //For each link, paint line from one track node to the other.
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, linkEdge.startTrackNode.center.x, linkEdge.startTrackNode.center.y)
            CGContextAddLineToPoint(context, linkEdge.endTrackNode.center.x, linkEdge.endTrackNode.center.y)
            CGContextStrokePath(context)
        }
        for linkEdge in linkEdges {
            eraseLineOnTrack(linkEdge.startTrackNode)
            eraseLineOnTrack(linkEdge.endTrackNode)
        }
    }
    
    func drawTrackNodeOutlines() {
        for trackID in trackNodeIDs {
            var track = (self.superview as! LinkManager).getTrackByID(trackID)
            /*var outLineFrame = node.frame
            var strokeColor = UIColor.blueColor()//.colorWithAlphaComponent(0.5)
            strokeColor.setStroke()
            var outline = UIBezierPath(roundedRect: outLineFrame, cornerRadius: 12)
            outline.lineWidth = 5
            outline.stroke()*/
            track!.layer.borderColor = UIColor.blueColor().CGColor
            track!.layer.borderWidth = 5
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
    
    func eraseLineOnTrack(track: Track) {
        //Draws clear fill over track node to erase link line from center to edge of node.
        var outLineFrame = track.frame
        var outline = UIBezierPath(roundedRect: outLineFrame, cornerRadius: 12)
        outline.fillWithBlendMode(kCGBlendModeClear, alpha: 1)
    }
    
    func drawCurLinkAdd() {
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, curTouchedTrack.center.x, curTouchedTrack.center.y)
        CGContextAddLineToPoint(context, curTouchLoc.x, curTouchLoc.y)
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().colorWithAlphaComponent(1).CGColor)
        CGContextSetLineWidth(context, 8)
        CGContextStrokePath(context)
        eraseLineOnTrack(curTouchedTrack)
        if queuedTrackForAdding != nil {
            eraseLineOnTrack(queuedTrackForAdding)
        }
    }
    
    func deleteSimulTrackLink() {
        for trackID in trackNodeIDs {
            var track = (self.superview as! LinkManager).getTrackByID(trackID)
            track!.layer.borderColor = UIColor.clearColor().CGColor
            track!.layer.borderWidth = 0
        }
        deleteLinkFromCoreData()
        self.removeFromSuperview()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for trackID in trackNodeIDs {
            var track = (self.superview as! LinkManager).getTrackByID(trackID)
            if track!.frame.contains(point) {
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
        for trackID in trackNodeIDs {
            var track = (self.superview as! LinkManager).getTrackByID(trackID)
            if track!.frame.contains(point) {
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
    
    func updateLinkCoreData() {
        println("Updating link data")
        var request = NSFetchRequest(entityName: "SimulLinkEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "simulLinkID = %@", argumentArray: [simulLinkID])
        var results: NSArray = self.context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var simulLinkEntity = results[0] as! SimulLinkEntity
            
            //update trackIDs
            var trackIDs: NSData = NSKeyedArchiver.archivedDataWithRootObject(trackNodeIDs)
            simulLinkEntity.tracks = trackIDs
            
            //convert linkEdges to IDs for storing, then update
            var edgeIDs = Array<Array<String>>()
            for edge in linkEdges {
                println("save link edge")
                var idPair = [edge.startTrackNode.trackID,edge.endTrackNode.trackID]
                edgeIDs.append(idPair)
            }
            var edges: NSData = NSKeyedArchiver.archivedDataWithRootObject(edgeIDs)
            simulLinkEntity.edges = edges
        }
        self.context.save(nil)
    }
    
    func saveLinkCoreData(projectEntity: ProjectEntity) {
        println("first save of simul link: " + simulLinkID)
        //convert linkEdges to IDs for storing
        var edgeIDs = Array<Array<String>>()
        for edge in linkEdges {
            println("save link edge")
            var idPair = [edge.startTrackNode.trackID,edge.endTrackNode.trackID]
            edgeIDs.append(idPair)
        }
        var edges: NSData = NSKeyedArchiver.archivedDataWithRootObject(edgeIDs)
        var trackIDs: NSData = NSKeyedArchiver.archivedDataWithRootObject(trackNodeIDs)
        var simulLinkEntity = NSEntityDescription.insertNewObjectForEntityForName("SimulLinkEntity", inManagedObjectContext: context) as! SimulLinkEntity
        simulLinkEntity.tracks = trackIDs
        simulLinkEntity.project = projectEntity
        simulLinkEntity.simulLinkID = self.simulLinkID
        simulLinkEntity.edges = edges
        self.context.save(nil)
    }
    
    func deleteLinkFromCoreData() {
        var request = NSFetchRequest(entityName: "SimulLinkEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "simulLinkID = %@", argumentArray: [self.simulLinkID])
        var results: NSArray = self.context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var linkToDelete = results[0] as! SimulLinkEntity
            self.context.deleteObject(linkToDelete)
        }
    }

}

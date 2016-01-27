//
//  TrackLink.swift
//  Tracks
//
//  Created by John Sloan on 8/6/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore

class TrackLink: UIView, AVAudioPlayerDelegate {
   
    var trackNodeIDs: [AVAudioPlayer:TrackLinkNode] = [AVAudioPlayer:TrackLinkNode]()
    var unrecordedTracks: [Track:TrackLinkNode] = [Track: TrackLinkNode]()
    var rootTrackID: String!
    var rootTrackAudioPlayer: AVAudioPlayer!
    var mode = ""
    var linkID = ""
    var curTouchedTrack: Track!
    var curTouchLoc: CGPoint!
    var curAddingLink: Bool = false
    var touchHitEdge: Bool = false
    var wasDragged: Bool = false
    var queuedTrackForAdding: Track!
    var dashedLinePhase: CGFloat = 0.0
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var alertWindow: UIWindow?
    
    init (frame: CGRect, withTrack track: Track) {
        super.init(frame: frame)
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        //Set the link id
        if linkID.isEmpty {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
            linkID = "link-" + formatter.stringFromDate(currentDateTime)
        }
        
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        rootTrackID = track.trackID
        let rootNode = TrackLinkNode(track: track)
        if track.audioPlayer != nil {
            trackNodeIDs[track.audioPlayer!] = rootNode
        } else {
            unrecordedTracks[track] = rootNode
        }
        
        let displayLink = CADisplayLink(target: self, selector: "updateLinkLayer")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        layer.contentsScale = UIScreen.mainScreen().scale
    }
    
    init (frame: CGRect, withTrackNodeIDs trackNodeIDs: [AVAudioPlayer:TrackLinkNode], unrecordedTracks: [Track: TrackLinkNode], rootTrackID root: String, linkID: String) {
        super.init(frame: frame)
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        self.trackNodeIDs = trackNodeIDs
        self.unrecordedTracks = unrecordedTracks
        self.linkID = linkID
        self.rootTrackID = root
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        let displayLink = CADisplayLink(target: self, selector: "updateLinkLayer")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        layer.contentsScale = UIScreen.mainScreen().scale
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLinkLayer() {
        if dashedLinePhase < 20 {
            dashedLinePhase += 1
        } else {
            dashedLinePhase = 0
        }
        self.layer.setNeedsDisplay()
    }
    
    func touchBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TOUCHED TRACKLINK BEGAN")
        let touch: UITouch = touches.first!
        let touchLoc: CGPoint = touch.locationInView(self)
        
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            var highestIndex = -1
            for audioPlayer in trackNodeIDs.keys {
                let trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                let track = (self.superview as! LinkManager).getTrackByID(trackID)
                let trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
                if trackIndex > highestIndex && track!.frame.contains(touchLoc) {
                    highestIndex = trackIndex
                    curTouchedTrack = track
                }
            }
            for track in unrecordedTracks.keys {
                let trackIndex = (self.superview as! LinkManager).getTrackIndex(track)
                if trackIndex > highestIndex && track.frame.contains(touchLoc) {
                    highestIndex = trackIndex
                    curTouchedTrack = track
                }
            }
            curTouchLoc = touchLoc
            if curTouchedTrack != nil {
                let convertedTouch = self.convertPoint(touchLoc, toView: curTouchedTrack.view)
                
                // check if will be moving track or adding link
                if curTouchedTrack.linkImageView.frame.contains(convertedTouch) {
                    curTouchedTrack.selectTrack(convertedTouch)
                    curAddingLink = true
                } else {
                    curTouchedTrack.touchBegan(touches, withEvent: event)
                }
            }
        } else {
            var didTouchTrack = false
            if mode != "TRASH" {
                touchHitEdge = true
            }
            //Make a dictionary of the track nodes with the current z-order index
            var trackSubviews = [Int: Track]()
            for audioPlayer in trackNodeIDs.keys {
                let trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                let track = (self.superview as! LinkManager).getTrackByID(trackID)
                let trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
                trackSubviews[trackIndex] = track!
            }
            for track in unrecordedTracks.keys {
                let trackIndex = (self.superview as! LinkManager).getTrackIndex(track)
                trackSubviews[trackIndex] = track
            }
            
            //Now iterate through dictionary, sorted by keys(index), to distribute touch in order, and check if touch landed on an edge or a node.
            let sortedKeys = Array(trackSubviews.keys).sort(<)
            for index in sortedKeys {
                let track = (trackSubviews[index] as Track!)
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
            bringTrackLinkToFront()
            layer.setNeedsDisplay()
        }
        bringTrackLinkToFront()
    }
    
    func touchMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TOUCHED TRACKLINK MOVED")
        let touch: UITouch = touches.first!
        let touchLoc: CGPoint = touch.locationInView(self)
        
        if (mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK") && curAddingLink {
            curTouchLoc = touchLoc
            layer.setNeedsDisplay()
        } else {
            if touchHitEdge {
                for audioPlayer in trackNodeIDs.keys {
                    let trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                    let track = (self.superview as! LinkManager).getTrackByID(trackID)
                    track!.touchMoved(touches, withEvent: event)
                }
                for track in unrecordedTracks.keys {
                    track.touchMoved(touches, withEvent: event)
                }
            } else {
                if curTouchedTrack != nil {
                    curTouchedTrack.touchMoved(touches, withEvent: event)
                }
            }
            wasDragged = true
            layer.setNeedsDisplay()
        }
    }
    
    func touchEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TOUCHED TRACKLINK ENDED")
        
        if curTouchedTrack != nil {
            curTouchedTrack.deselectTrack()
        }
        
        if (mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK") && curAddingLink {
            curTouchLoc = nil
            curTouchedTrack = nil
            curAddingLink = false
        } else {
            if wasDragged {
                if touchHitEdge {
                    for audioPlayer in trackNodeIDs.keys {
                        let trackID = trackNodeIDs[audioPlayer]!.rootTrackID
                        let track = (self.superview as! LinkManager).getTrackByID(trackID)
                        track!.touchEnded(touches, withEvent: event)
                    }
                    for track in unrecordedTracks.keys {
                        track.touchEnded(touches, withEvent: event)
                    }
                } else {
                    if curTouchedTrack != nil {
                        curTouchedTrack.touchEnded(touches, withEvent: event)
                        curTouchedTrack = nil
                    }
                }
                wasDragged = false
            } else {
                if curTouchedTrack != nil && (mode != "ADD_SEQ_LINK" && mode != "ADD_SIMUL_LINK") {
                    beginPlaySequence(fromStartTrack: curTouchedTrack)
                    curTouchedTrack = nil
                }
            }
            layer.setNeedsDisplay()
            bringTrackLinkToFront()
        }
    }
    
    func bringTrackLinkToFront() {
        if let supervw = self.superview {
            supervw.insertSubview(self, atIndex: supervw.subviews.count - 6)
        }
    }
    
    func placeAllTracksBelow() {
        if let supervw = self.superview {
            for audioPlayer in trackNodeIDs.keys {
                let node = trackNodeIDs[audioPlayer]!
                let trackID = node.rootTrackID
                if let track = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                    supervw.insertSubview(track, belowSubview: self)
                }
            }
            
            for track in unrecordedTracks.keys {
                let node = unrecordedTracks[track]!
                let trackID = node.rootTrackID
                if let track = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                    supervw.insertSubview(track, belowSubview: self)
                }
            }
        }
    }
    
    func beginPlaySequence(fromStartTrack startTrack: Track) {
        var startNode: TrackLinkNode?
        let shortStartDelay: NSTimeInterval = 0.05
        var now: NSTimeInterval? = nil
        if startTrack.audioPlayer != nil {
            // If not nil, then continue as normal track
            if let node = trackNodeIDs[startTrack.audioPlayer!] {
                startNode = node
            } else {
                if let node = unrecordedTracks[startTrack] {
                    startNode = node
                    unrecordedTracks[startTrack] = nil
                    trackNodeIDs[startTrack.audioPlayer!] = node
                }
            }
            startTrack.audioPlayer!.delegate = self
            now = startTrack.audioPlayer!.deviceCurrentTime
            startTrack.playAudioAtTime(now! + shortStartDelay)
        } else {
            // Otherwise, begin/stop recording for start track
            if let node = unrecordedTracks[startTrack] {
                startNode = node
                now = startTrack.audioRecorder!.deviceCurrentTime
                
                // Check if needs to record, and startup recording if so.
                if !startTrack.hasStartedRecording && !startTrack.hasStoppedRecording {
                    startTrack.startRecording()//change to startRecording at time
                    
                } else if startTrack.hasStartedRecording && !startTrack.hasStoppedRecording {
                    startTrack.stopRecording()
                }
            }
        }
        
        if startNode != nil {
            let visitedSiblings = NSMutableArray()
            visitedSiblings.addObject(startTrack.trackID)
            var siblingQueue = [String]()
            //Append initial siblings.
            for siblingID in startNode!.siblingIDs {
                siblingQueue.append(siblingID)
            }
            
            //continue adding siblings of siblings to visited queue until all have been visited.
            while !siblingQueue.isEmpty {
                let siblingID = siblingQueue.removeAtIndex(0)
                if visitedSiblings.containsObject(siblingID) {
                    //if seen before, move on to next node in the queue
                    continue
                }
                if let sibling = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                    var sibNode: TrackLinkNode?
                    if sibling.audioPlayer != nil {
                        if let node = trackNodeIDs[sibling.audioPlayer!] {
                            sibNode = node
                        } else {
                            if let node = unrecordedTracks[sibling] {
                                sibNode = node
                                unrecordedTracks[sibling] = nil
                                trackNodeIDs[sibling.audioPlayer!] = node
                            }
                        }
                        sibling.audioPlayer!.delegate = self
                        if now == nil {
                            sibling.playAudio()
                        } else {
                            sibling.playAudioAtTime(now! + shortStartDelay)
                        }
                    } else {
                        sibNode = unrecordedTracks[sibling]
                        // Check if needs to record, and startup recording if so.
                        if !sibling.hasStartedRecording && !sibling.hasStoppedRecording {
                            sibling.startRecording()//change to startRecording at time
                        } else if sibling.hasStartedRecording && !sibling.hasStoppedRecording {
                            sibling.stopRecording()
                        }
                    }
                    
                    visitedSiblings.addObject(sibling.trackID)
                    if sibNode != nil {
                        print("======")
                        for siblingID in sibNode!.siblingIDs {
                            // if sibling is not yet visited, add to the queue.
                            print("checking sib: \(siblingID)")
                            if !visitedSiblings.containsObject(siblingID) {
                                print("appending sib: \(siblingID)")
                                siblingQueue.append(siblingID)
                            }
                        }
                        print("======")
                    } else {
                        print("No node saved for this sibling track, removing from siblingIDs")
                        for (i, sib) in startNode!.siblingIDs.enumerate() {
                            if sib == siblingID {
                                startNode!.siblingIDs.removeAtIndex(i)
                            }
                        }
                    }
                } else {
                    print("No track saved for this trackID, removing from siblingIDs")
                    for (i, sib) in startNode!.siblingIDs.enumerate() {
                        if sib == siblingID {
                            startNode!.siblingIDs.removeAtIndex(i)
                        }
                    }
                }
            }
        } else {
            print("startTrack did not belong to this link")
            
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing!!!")
        if let node = trackNodeIDs[player] {
            // if there are no other children, attempt to hide the stop button
            if node.childrenIDs.count == 0 {
                if superview != nil && superview is LinkManager {
                    (superview as! LinkManager).hideStopButton()// hideStopButton checks that no other tracks are currently playing
                }
            }
        
        
        if let curTrack = (self.superview as? LinkManager)?.getTrackByID(node.rootTrackID) {
            // reset progress view of track that just finished playing
            curTrack.progressViewConstraint.constant = 5
            curTrack.view.layoutIfNeeded()
            
            if curTrack.audioPlayer != nil {
                let shortStartDelay: NSTimeInterval = 0.05
                let now = curTrack.audioPlayer!.deviceCurrentTime
        
                // Begin playing each child and each child's siblings, if any.
                for childID in node.childrenIDs {
                    if let child = (self.superview as? LinkManager)?.getTrackByID(childID) {
                        var childNode: TrackLinkNode? = nil
                        if child.audioPlayer != nil {
                            if let cNode = trackNodeIDs[child.audioPlayer!] {
                                childNode = cNode
                                child.audioPlayer!.delegate = self
                                child.playAudioAtTime(now + shortStartDelay)
                            } else {
                                // If in unrecorded tracks, but now has finished recording, add to trackNodeIDs.
                                if let cNode = unrecordedTracks[child] {
                                    childNode = cNode
                                    unrecordedTracks[child] = nil
                                    trackNodeIDs[child.audioPlayer!] = cNode
                                    child.audioPlayer!.delegate = self
                                    child.playAudioAtTime(now + shortStartDelay)
                                }
                            }
                        } else {
                            // Child is unrecorded, or some error with audioPlayer.
                            if let cNode = unrecordedTracks[child] {
                                childNode = cNode
                                // Check if needs to record, and startup recording if so.
                                if !child.hasStartedRecording && !child.hasStoppedRecording {
                                    child.startRecording()//change to startRecording at time
                                    
                                } else if child.hasStartedRecording && !child.hasStoppedRecording {
                                    child.stopRecording()
                                }

                            } else {
                                print("didfinishPlaying, error with audioPlayer for child: \(child)")
                            }
                        }
                        
                        if childNode != nil {
                            let visitedSiblings = NSMutableArray()
                            visitedSiblings.addObject(child.trackID)
                            var siblingQueue = [String]()
                            // Append initial siblings.
                            for siblingID in childNode!.siblingIDs {
                                siblingQueue.append(siblingID)
                            }
                            // Continue adding siblings of siblings to queue until all have been visited.
                            while !siblingQueue.isEmpty {
                                let siblingID = siblingQueue.removeAtIndex(0)
                                if let sibling = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                                    var sibNode: TrackLinkNode? = nil
                                    if sibling.audioPlayer != nil {
                                        if let sNode = trackNodeIDs[sibling.audioPlayer!] {
                                            sibNode = sNode
                                            sibling.audioPlayer!.delegate = self
                                            sibling.playAudioAtTime(now + shortStartDelay)
                                        } else {
                                            if let sNode = unrecordedTracks[sibling] {
                                                sibNode = sNode
                                                unrecordedTracks[sibling] = nil
                                                trackNodeIDs[sibling.audioPlayer!] = sNode
                                                sibling.audioPlayer!.delegate = self
                                                sibling.playAudioAtTime(now + shortStartDelay)
                                            } else {
                                                print("didfinishPlaying, No node for sibling: \(sibling)")
                                            }
                                        }
                                    } else {
                                        // Sibling is unrecorded, or some error with audioPlayer.
                                        if let sNode = unrecordedTracks[sibling] {
                                            sibNode = sNode
                                            // Check if needs to record, and startup recording if so.
                                            if !sibling.hasStartedRecording && !sibling.hasStoppedRecording {
                                                sibling.startRecording()//change to startRecording at time
                                                
                                            } else if sibling.hasStartedRecording && !sibling.hasStoppedRecording {
                                                sibling.stopRecording()
                                            }
                                            
                                        } else {
                                            print("didfinishPlaying, error with audioPlayer for sibling: \(sibling)")
                                        }

                                    }
                                    
                                    
                                    if sibNode != nil {
                                        visitedSiblings.addObject(sibling.trackID)
                                        for siblingID in sibNode!.siblingIDs {
                                            if !visitedSiblings.containsObject(siblingID) {
                                                siblingQueue.append(siblingID)
                                            }
                                        }
                                    } else {
                                        print("No node saved for this sibling track, removing from siblingIDs")
                                        for (i, sib) in node.siblingIDs.enumerate() {
                                            if sib == siblingID {
                                                node.siblingIDs.removeAtIndex(i)
                                            }
                                        }
                                    }
                                } else {
                                    print("No track saved for this trackID, removing from siblingIDs")
                                    for (i, sib) in node.siblingIDs.enumerate() {
                                        if sib == siblingID {
                                            node.siblingIDs.removeAtIndex(i)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        } else {
            print("didfinishPlaying: no node for audioplayer: \(player)")
            //write function for determining if audio player SHOULD have a corresponding node, to recover from failure.
        }
    }
    
    func queueTrackForAdding(track: Track) {
        queuedTrackForAdding = track
        let touch = self.convertPoint(track.center, toView: track.view)
        queuedTrackForAdding.selectTrack(touch)
        layer.setNeedsDisplay()
    }
    
    func dequeueTrackFromAdding() {
        if queuedTrackForAdding != nil {
            queuedTrackForAdding.deselectTrack()
            queuedTrackForAdding = nil
            layer.setNeedsDisplay()
        }
    }
    
    func bringTrackToEditMode(location: CGPoint, gestureRecognizer: UIGestureRecognizer) {
        if let trackToEdit = trackAtPoint(location) {
            let editView = trackToEdit.editMode(gestureRecognizer)
            if let editView = editView {
                editView.trackLink = self
            }
        }
    }
    
    func updateTrackWithNewAudioPlayer(oldAudioPlayer: AVAudioPlayer, track: Track) {
        if let player = track.audioPlayer {
            trackNodeIDs[player] = trackNodeIDs[oldAudioPlayer]
            trackNodeIDs[oldAudioPlayer] = nil
            player.delegate = self
        }
        layer.setNeedsDisplay()
    }
    
    func trackAtPoint(location: CGPoint) -> Track? {
        // returns the track contained in the tracklink at a given touch loc (picks highest in subviews array).
        var highestIndex = -1
        var highestTrack: Track?
        for audioPlayer in trackNodeIDs.keys {
            let trackID = trackNodeIDs[audioPlayer]!.rootTrackID
            let track = (self.superview as! LinkManager).getTrackByID(trackID)
            let trackIndex = (self.superview as! LinkManager).getTrackIndex(track!)
            if trackIndex > highestIndex && track!.frame.contains(location) {
                highestIndex = trackIndex
                highestTrack = track
            }
        }
        for track in unrecordedTracks.keys {
            let trackIndex = (self.superview as! LinkManager).getTrackIndex(track)
            if trackIndex > highestIndex && track.frame.contains(location) {
                highestIndex = trackIndex
                highestTrack = track
            }
        }
        
        return highestTrack
    }
    
    class BasicViewController: UIViewController {
        override func prefersStatusBarHidden() -> Bool {
            return true
        }
    }
    
    func commitEdgeToLink(touches: Set<UITouch>) {
        print("ADDING TRACK TO TRACKLINK!")
        
        alertWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Add Link", message: "Links tracks together to play them at the same time or in sequence.", preferredStyle: .Alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.alertWindow?.hidden = true
            self.alertWindow = nil
            self.dequeueTrackFromAdding()
            let hasNoNodes = self.trackNodeIDs.isEmpty && self.unrecordedTracks.isEmpty
            let hasOneNode = (self.trackNodeIDs.count == 1 && self.unrecordedTracks.isEmpty) || (self.trackNodeIDs.isEmpty && self.unrecordedTracks.count == 1)
            // if tracklink contains one or zero nodes, delete it.
            if hasNoNodes || hasOneNode {
                self.deleteTrackLink()
            } else {
                if self.curTouchedTrack != nil {
                    self.curTouchedTrack.deselectTrack()
                    self.curTouchedTrack = nil
                }
                self.curAddingLink = false
            }
        }
        actionSheetController.addAction(cancelAction)
        
        let simulAction: UIAlertAction = UIAlertAction(title: "Simultaneous", style: .Default) { action -> Void in
            print("simultaneous")
            self.mode = "ADD_SIMUL_LINK"
            self.completeAddNode()
            self.alertWindow?.hidden = true
            self.alertWindow = nil
            self.touchEnded(touches, withEvent: nil)
        }
        actionSheetController.addAction(simulAction)
        
        let seqAction: UIAlertAction = UIAlertAction(title: "Sequential", style: .Default) { action -> Void in
            print("sequential")
            self.mode = "ADD_SEQ_LINK"
            self.completeAddNode()
            self.alertWindow?.hidden = true
            self.alertWindow = nil
            self.touchEnded(touches, withEvent: nil)
        }
        actionSheetController.addAction(seqAction)
        
        alertWindow!.makeKeyAndVisible()
        alertWindow!.rootViewController = BasicViewController()
        alertWindow!.windowLevel = UIWindowLevelAlert + 1
        alertWindow!.rootViewController!.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func completeAddNode() {
        let newNode: TrackLinkNode!
        if queuedTrackForAdding.audioPlayer != nil {
            // If not already a track in the tracklink, add queued track to dictionary as a new node
            if trackNodeIDs[queuedTrackForAdding.audioPlayer!] == nil {
                newNode = TrackLinkNode(track: queuedTrackForAdding)
                trackNodeIDs[queuedTrackForAdding.audioPlayer!] = newNode
            } else {
                newNode = trackNodeIDs[queuedTrackForAdding.audioPlayer!]
            }
        } else {
            // If unrecorded track not already in tracklink, add to dictionary as new node
            if unrecordedTracks[queuedTrackForAdding] == nil {
                newNode = TrackLinkNode(track: queuedTrackForAdding)
                unrecordedTracks[queuedTrackForAdding] = newNode
            } else {
                newNode = unrecordedTracks[queuedTrackForAdding]
            }
        }
        
        if mode == "ADD_SEQ_LINK" {
            // Add queued track to children array of curTouchedTrack
            if curTouchedTrack.audioPlayer != nil {
                if let node = trackNodeIDs[curTouchedTrack.audioPlayer!] {
                    node.childrenIDs.append(queuedTrackForAdding.trackID)
                }
            } else {
                if let node = unrecordedTracks[curTouchedTrack] {
                    node.childrenIDs.append(queuedTrackForAdding.trackID)
                }
            }
        } else if mode == "ADD_SIMUL_LINK" {
            // Add queued track to sibling array of curTouchedTrack
            if curTouchedTrack.audioPlayer != nil {
                if let node = trackNodeIDs[curTouchedTrack.audioPlayer!] {
                    node.siblingIDs.append(queuedTrackForAdding.trackID)
                    newNode.siblingIDs.append(node.rootTrackID)
                }
            } else {
                if let node = unrecordedTracks[curTouchedTrack] {
                    node.siblingIDs.append(queuedTrackForAdding.trackID)
                    newNode.siblingIDs.append(node.rootTrackID)
                }
            }
        }
        dequeueTrackFromAdding()
        updateLinkCoreData()
        layer.setNeedsDisplay()
    }
    
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
      
        UIGraphicsPushContext(ctx)
        let seqPath = UIBezierPath()
        seqPath.lineWidth = 4
        seqPath.lineCapStyle = CGLineCap.Round
        seqPath.setLineDash([12.0,8.0], count: 2, phase: -dashedLinePhase)
        
        let simPath = UIBezierPath()
        simPath.lineWidth = 4
        simPath.lineCapStyle = CGLineCap.Round
        UIColor.whiteColor().setStroke()
        
        for audioPlayer in self.trackNodeIDs.keys {
            
            let node = self.trackNodeIDs[audioPlayer]!
            let trackID = node.rootTrackID
            if let startTrack = (superview as? LinkManager)?.getTrackByID(trackID) {
                
                for childTrackID in node.childrenIDs {
                    if let endTrack = (superview as! LinkManager).getTrackByID(childTrackID) {
                        // Add dashed line for seq edges from center to center.
                        seqPath.moveToPoint(CGPointMake(startTrack.center.x, startTrack.center.y))
                        seqPath.addLineToPoint(CGPointMake(endTrack.center.x, endTrack.center.y))
                        
                    }
                }
                for siblingTrackID in node.siblingIDs {
                    if let endTrack = (superview as! LinkManager).getTrackByID(siblingTrackID) {
                        // Add solid line for sim edges from center to center.
                        simPath.moveToPoint(CGPointMake(startTrack.center.x, startTrack.center.y))
                        simPath.addLineToPoint(CGPointMake(endTrack.center.x, endTrack.center.y))
                    }
                }
            }
        }
        
        // same but for unrecorded tracks
        for track in self.unrecordedTracks.keys {
            
            let node = self.unrecordedTracks[track]!
            let trackID = node.rootTrackID
            if let startTrack = (superview as? LinkManager)?.getTrackByID(trackID) {
                
                for childTrackID in node.childrenIDs {
                    if let endTrack = (superview as! LinkManager).getTrackByID(childTrackID) {
                        // Add dashed line for seq edges from center to center.
                        seqPath.moveToPoint(CGPointMake(startTrack.center.x, startTrack.center.y))
                        seqPath.addLineToPoint(CGPointMake(endTrack.center.x, endTrack.center.y))
                        
                    }
                }
                for siblingTrackID in node.siblingIDs {
                    if let endTrack = (superview as! LinkManager).getTrackByID(siblingTrackID) {
                        // Add solid line for sim edges from center to center.
                        simPath.moveToPoint(CGPointMake(startTrack.center.x, startTrack.center.y))
                        simPath.addLineToPoint(CGPointMake(endTrack.center.x, endTrack.center.y))
                    }
                }
            }
        }

        
        simPath.stroke()
        seqPath.stroke()
        
        if self.mode != "ADD_SEQ_LINK" && self.mode != "ADD_SIMUL_LINK" {
        // after stroking edges, add blended clear rects to remove lines over tracks.
        for audioPlayer in self.trackNodeIDs.keys {
            
            let node = self.trackNodeIDs[audioPlayer]!
            let trackID = node.rootTrackID
            if let track = (superview as? LinkManager)?.getTrackByID(trackID) {
                eraseLineOnTrack(track)
            }
        }
        
        // same for unrecorded tracks.
        for track in self.unrecordedTracks.keys {
            let node = self.unrecordedTracks[track]!
            let trackID = node.rootTrackID
            if let track = (superview as? LinkManager)?.getTrackByID(trackID) {
                eraseLineOnTrack(track)
            }
        }
        }
        // if in link mode, draw the link currently being added.
        if (mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK") && curTouchedTrack != nil {
            drawCurLinkAdd()
        }

        UIGraphicsPopContext()
        drawTrackNodeOutlines()
    }
    
    func eraseLineOnTrack(track: Track) {
        // Draws clear fill over track node to erase link line from center to edge of node.
        let outLineFrame = track.frame
        let outline = UIBezierPath(roundedRect: outLineFrame, cornerRadius: 12)
        outline.fillWithBlendMode(CGBlendMode.Clear, alpha: 1)
    }
    
    func drawTrackNodeOutlines() {
        for audioPlayer in trackNodeIDs.keys {
            let node = trackNodeIDs[audioPlayer]!
            let trackID = node.rootTrackID
            if let track = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                if track != curTouchedTrack {
                    track.deselectTrack()
                }
            }
        }
        
        for track in unrecordedTracks.keys {
            let node = unrecordedTracks[track]!
            let trackID = node.rootTrackID
            if let track = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                if track != curTouchedTrack {
                    track.deselectTrack()
                }
            }
        }
    }
    
    func drawCurLinkAdd() {
        //draws line from starting track to current touch location
        if curAddingLink {
            let context = UIGraphicsGetCurrentContext()
            CGContextBeginPath(context)
            CGContextMoveToPoint(context, curTouchedTrack.center.x, curTouchedTrack.center.y)
            if queuedTrackForAdding != nil {
                CGContextAddLineToPoint(context, queuedTrackForAdding.center.x, queuedTrackForAdding.center.y)
            } else {
                CGContextAddLineToPoint(context, curTouchLoc.x, curTouchLoc.y)
            }
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().colorWithAlphaComponent(1).CGColor)
            CGContextSetLineCap(context, CGLineCap.Round)
            CGContextSetLineWidth(context, 4)
            CGContextStrokePath(context)
        }
    }
    
    func removeTrackFromLink(track: Track) {
        var node: TrackLinkNode? = nil
        if track.audioPlayer != nil {
            if let tNode = trackNodeIDs[track.audioPlayer!] {
                node = tNode
            }
        } else {
            if let tNode = unrecordedTracks[track] {
                node = tNode
            }
        }
        
        if node != nil && node!.childrenIDs.isEmpty && node!.siblingIDs.isEmpty {
            var shouldRemoveTrack = true
            // since no children, or siblings remain, check if track is child of any other node before removing from link
            for track in unrecordedTracks.keys {
                if let tNode = unrecordedTracks[track] {
                    if tNode.childrenIDs.contains(node!.rootTrackID) {
                        shouldRemoveTrack = false
                    }
                }
            }
            for audioPlayer in trackNodeIDs.keys {
                if let tNode = trackNodeIDs[audioPlayer] {
                    if tNode.childrenIDs.contains(node!.rootTrackID) {
                        shouldRemoveTrack = false
                    }
                }
            }
            if shouldRemoveTrack {
                unrecordedTracks[track] = nil
                track.deselectTrack()
                if track.audioPlayer != nil {
                    trackNodeIDs[track.audioPlayer!] = nil
                    track.audioPlayer!.delegate = track
                }
            }
        }
        
    }
    
    func removeEdgesForNode(node: TrackLinkNode) {
        // remove children of node
        node.childrenIDs.removeAll()
        
        // remove siblings of node, and node from siblings' siblingIDs.
        for siblingID in node.siblingIDs {
            if let sibling = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                var sibNode: TrackLinkNode?
                if let _ = sibling.audioPlayer {
                    sibNode = trackNodeIDs[sibling.audioPlayer!]
                } else {
                    sibNode = unrecordedTracks[sibling]
                }
                if let sibNode = sibNode {
                    for (i,sib) in sibNode.siblingIDs.enumerate().reverse() {
                        if sib == node.rootTrackID {
                            sibNode.siblingIDs.removeAtIndex(i)
                        }
                    }
                }
            }
        }
        node.siblingIDs.removeAll()
        
        // remove all parent edges to node
        for track in unrecordedTracks.keys {
            if let tNode = unrecordedTracks[track] {
                for (i,childID) in tNode.childrenIDs.enumerate().reverse() {
                    if childID == node.rootTrackID {
                        tNode.childrenIDs.removeAtIndex(i)
                    }
                }
            }
        }
        for audioPlayer in trackNodeIDs.keys {
            if let tNode = trackNodeIDs[audioPlayer] {
                for (i,childID) in tNode.childrenIDs.enumerate().reverse() {
                    if childID == node.rootTrackID {
                        tNode.childrenIDs.removeAtIndex(i)
                    }
                }
            }
        }
    }
    
    func confirmDeleteTrackAtPoint(point: CGPoint) {
        alertWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
        let actionSheetController: UIAlertController = UIAlertController(title: "Delete Track?", message: "This track will be permanently deleted.", preferredStyle: .ActionSheet)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.alertWindow?.hidden = true
            self.alertWindow = nil
        }
        actionSheetController.addAction(cancelAction)
        
        let simulAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
            self.alertWindow?.hidden = true
            self.alertWindow = nil
            self.deleteTrackAtPoint(point)
        }
        actionSheetController.addAction(simulAction)
        
        alertWindow!.makeKeyAndVisible()
        alertWindow!.rootViewController = BasicViewController()
        alertWindow!.windowLevel = UIWindowLevelAlert + 1
        alertWindow!.rootViewController!.presentViewController(actionSheetController, animated: true, completion: nil)

    }
    
    func deleteTrackAtPoint(point: CGPoint) {
        if let track = trackAtPoint(point) {
            let convertedTouch = self.convertPoint(point, toView: track.view)
            if track.trashImageView.frame.contains(convertedTouch) {
                // remove all links for this track and delete track
                let node: TrackLinkNode?
                if let player = track.audioPlayer {
                    node = trackNodeIDs[player]
                } else {
                    node = unrecordedTracks[track]
                }
                if let node = node {
                    removeEdgesForNode(node)
                }
                removeTrackFromLink(track)
                track.deleteTrack()
            }
        }
    }
    
    func deleteLinkEdge(point: CGPoint) {
        for audioPlayer in trackNodeIDs.keys {
            if let node = trackNodeIDs[audioPlayer] {
                let trackID = node.rootTrackID
                if let startTrack = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                    for (i,childTrackID) in node.childrenIDs.enumerate().reverse() {
                        if let endTrack = (self.superview as? LinkManager)?.getTrackByID(childTrackID) {
                            let edge = LinkEdge(startTrackNode: startTrack, endTrackNode: endTrack)
                            if edge.containsPoint(point) {
                                node.childrenIDs.removeAtIndex(i)
                            }
                        }
                    }
                    for (i,siblingID) in node.siblingIDs.enumerate().reverse() {
                        if let endTrack = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                            let edge = LinkEdge(startTrackNode: startTrack, endTrackNode: endTrack)
                            if edge.containsPoint(point) {
                                node.siblingIDs.removeAtIndex(i)
                            }
                        }
                    }
                    if node.childrenIDs.isEmpty && node.siblingIDs.isEmpty {
                        // remove track node. removeTrackFromLink() will check that track is not child of other node before removing.
                        removeTrackFromLink(startTrack)
                    }
                }
            } else {
                print("Point inside: no node for audioPlayer: \(audioPlayer)")
            }
        }
        // same thing for unrecorded tracks
        for track in unrecordedTracks.keys {
            if let node = unrecordedTracks[track] {
                if track.frame.contains(point) {

                }
                for (i,childTrackID) in node.childrenIDs.enumerate().reverse() {
                    if let endTrack = (self.superview as? LinkManager)?.getTrackByID(childTrackID) {
                        let edge = LinkEdge(startTrackNode: track, endTrackNode: endTrack)
                        if edge.containsPoint(point) {
                            node.childrenIDs.removeAtIndex(i)
                        }
                    }
                }
                for (i,siblingID) in node.siblingIDs.enumerate().reverse() {
                    if let endTrack = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                        let edge = LinkEdge(startTrackNode: track, endTrackNode: endTrack)
                        if edge.containsPoint(point) {
                            node.siblingIDs.removeAtIndex(i)
                        }
                    }
                }
                if node.childrenIDs.isEmpty && node.siblingIDs.isEmpty {
                    removeTrackFromLink(track)
                }
            } else {
                print("Point inside: no node for unrecorded track: \(track)")
            }
        }
        if trackNodeIDs.isEmpty && unrecordedTracks.isEmpty {
            deleteTrackLink()
        } else {
            layer.setNeedsDisplay()
            updateLinkCoreData()
        }
    }
    
    func deleteTrackLink() {
        print("deleting TRACK LINK")
        for audioPlayer in trackNodeIDs.keys {
            let trackID = trackNodeIDs[audioPlayer]!.rootTrackID
            if let track = (self.superview as! LinkManager).getTrackByID(trackID) {
                if track.audioPlayer != nil {
                    track.audioPlayer!.delegate = track
                }
                track.deselectTrack()
            }
        }
        for track in unrecordedTracks.keys {
            if track.audioPlayer != nil {
                track.audioPlayer!.delegate = track
            }
            track.deselectTrack()
        }
        self.removeFromSuperview()
        deleteLinkFromCoreData()
        
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for audioPlayer in trackNodeIDs.keys {
            if let node = trackNodeIDs[audioPlayer] {
                let trackID = node.rootTrackID
                if let startTrack = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                    if startTrack.frame.contains(point) {
                        return true
                    }
                    for childTrackID in node.childrenIDs {
                        if let endTrack = (self.superview as? LinkManager)?.getTrackByID(childTrackID) {
                            let edge = LinkEdge(startTrackNode: startTrack, endTrackNode: endTrack)
                            if edge.containsPoint(point) {
                                return true
                            }
                        }
                    }
                    for siblingID in node.siblingIDs {
                        if let endTrack = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                            let edge = LinkEdge(startTrackNode: startTrack, endTrackNode: endTrack)
                            if edge.containsPoint(point) {
                                return true
                            }
                        }
                    }
                }
            } else {
                print("Point inside: no node for audioPlayer: \(audioPlayer)")
            }
        }
        
        for track in unrecordedTracks.keys {
            if let node = unrecordedTracks[track] {
                if track.frame.contains(point) {
                    return true
                }
                for childTrackID in node.childrenIDs {
                    if let endTrack = (self.superview as? LinkManager)?.getTrackByID(childTrackID) {
                        let edge = LinkEdge(startTrackNode: track, endTrackNode: endTrack)
                        if edge.containsPoint(point) {
                            return true
                        }
                    }
                }
                for siblingID in node.siblingIDs {
                    if let endTrack = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                        let edge = LinkEdge(startTrackNode: track, endTrackNode: endTrack)
                        if edge.containsPoint(point) {
                            return true
                        }
                    }
                }
            } else {
                print("Point inside: no node for unrecorded track: \(track)")
            }
        }
        
        return false
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        for audioPlayer in trackNodeIDs.keys {
            if let node = trackNodeIDs[audioPlayer] {
                let trackID = node.rootTrackID
                if let startTrack = (self.superview as? LinkManager)?.getTrackByID(trackID) {
                    if startTrack.frame.contains(point) {
                        return self
                    }
                    for childTrackID in node.childrenIDs {
                        if let endTrack = (self.superview as? LinkManager)?.getTrackByID(childTrackID) {
                            let edge = LinkEdge(startTrackNode: startTrack, endTrackNode: endTrack)
                            if edge.containsPoint(point) {
                                return self
                            }
                        }
                    }
                    for siblingID in node.siblingIDs {
                        if let endTrack = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                            let edge = LinkEdge(startTrackNode: startTrack, endTrackNode: endTrack)
                            if edge.containsPoint(point) {
                                return self
                            }
                        }
                    }
                }
            } else {
                print("Point inside: no node for audioPlayer: \(audioPlayer)")
            }
        }
        
        for track in unrecordedTracks.keys {
            if let node = unrecordedTracks[track] {
                if track.frame.contains(point) {
                    return self
                }
                for childTrackID in node.childrenIDs {
                    if let endTrack = (self.superview as? LinkManager)?.getTrackByID(childTrackID) {
                        let edge = LinkEdge(startTrackNode: track, endTrackNode: endTrack)
                        if edge.containsPoint(point) {
                            return self
                        }
                    }
                }
                for siblingID in node.siblingIDs {
                    if let endTrack = (self.superview as? LinkManager)?.getTrackByID(siblingID) {
                        let edge = LinkEdge(startTrackNode: track, endTrackNode: endTrack)
                        if edge.containsPoint(point) {
                            return self
                        }
                    }
                }
            } else {
                print("Point inside: no node for unrecorded track: \(track)")
            }
        }
        return nil
    }

    func updateLinkCoreData() {
        print("Updating link data")
        let request = NSFetchRequest(entityName: "LinkEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "linkID = %@", argumentArray: [linkID])
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let linkEntity = results[0] as! LinkEntity
            
            //update tracklink nodes
            var nodeArray = [TrackLinkNode]()
            for node in trackNodeIDs.values {
                nodeArray.append(node)
            }
            for node in unrecordedTracks.values {
                nodeArray.append(node)
            }
            let nodeData = NSKeyedArchiver.archivedDataWithRootObject(nodeArray)
            linkEntity.linkNodes = nodeData
            linkEntity.rootTrackID = rootTrackID
        } else {
            print("MULTIPLE LINKS WITH SAME ID!")
        }
        do {
            try context.save()
        } catch _ {
        }
    }
    
    func saveLinkCoreData(projectEntity: ProjectEntity) {
        print("first save of simul link: " + linkID)
        
        //Create array of link nodes from trackNodeIDs dictionary.
        var nodeArray = [TrackLinkNode]()
        for node in trackNodeIDs.values {
            nodeArray.append(node)
        }
        for node in unrecordedTracks.values {
            nodeArray.append(node)
        }
        let nodeData = NSKeyedArchiver.archivedDataWithRootObject(nodeArray)
        
        let linkEntity = NSEntityDescription.insertNewObjectForEntityForName("LinkEntity", inManagedObjectContext: context) as! LinkEntity
        linkEntity.linkNodes = nodeData
        linkEntity.project = projectEntity
        linkEntity.rootTrackID = rootTrackID
        linkEntity.linkID = linkID
        do {
            try context.save()
        } catch _ {
        }
    }
    
    func deleteLinkFromCoreData() {
        let request = NSFetchRequest(entityName: "LinkEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "linkID = %@", argumentArray: [linkID])
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let linkToDelete = results[0] as! LinkEntity
            context.deleteObject(linkToDelete)
            do {
                try context.save()
            } catch _ {
            }
        }  else {
            print("MULTIPLE LINKS WITH SAME ID!")
        }
    }    
}




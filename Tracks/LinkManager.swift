//
//  LinkManager.swift
//  Tracks
//
//  Created by John Sloan on 5/7/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation

class LinkManager: UIView {

    var mode: String = ""
    var allSimulLink: [SimulTrackLink] = [SimulTrackLink]()
    var allSeqLink: [SeqTrackLink] = [SeqTrackLink]()
    var firstHitSubview = UIView()
    var addLinkStartLoc: CGPoint!
    var addLinkCurMovedLoc: CGPoint!
    var curSimulLinkAdd: SimulTrackLink!
    var curSeqLinkAdd: SeqTrackLink!
    var projectEntity: ProjectEntity!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        var longPressEdit = UILongPressGestureRecognizer(target: self, action: "changeTrackToEditMode:")
        longPressEdit.numberOfTapsRequired = 0
        self.addGestureRecognizer(longPressEdit)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        var location: CGPoint = touch.locationInView(touch.window)
        println("TOUCHED IN LINK MANAGER")
        //Find the subview hit by touch
        firstHitSubview = UIView()
        for var i = self.subviews.count - 1; i >= 0; i-- {
            var subview = self.subviews[i]
            if subview is LinkManager {
                continue
            } else if subview is Track {
                if subview.frame.contains(location) {
                    firstHitSubview = subview as! UIView
                    break
                }
            } else if subview is SimulTrackLink {
                if subview.pointInside(location, withEvent: event) {
                    firstHitSubview = subview as! UIView
                    break
                }
            } else if subview is SeqTrackLink {
                if subview.pointInside(location, withEvent: event) {
                    firstHitSubview = subview as! UIView
                    break
                }
            } else if subview is DrawView {
                if subview.frame.contains(location) {
                    firstHitSubview = subview as! UIView
                    break
                }
            }
        }

        print("FIRST HIT SUBVIEW: ")
        println(firstHitSubview)
    
        switch mode {
            
        case "ADD_SIMUL_LINK":
            if firstHitSubview is Track {
                var newLink = SimulTrackLink(frame: self.frame, withTrack: firstHitSubview as! Track)
                newLink.mode = "ADD_SIMUL_LINK"
                allSimulLink.append(newLink)
                curSimulLinkAdd = newLink
                self.insertSubview(firstHitSubview, atIndex: self.subviews.count - 4)
                self.insertSubview(newLink, atIndex: self.subviews.count - 4)
                newLink.touchBegan(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
                curSimulLinkAdd = (firstHitSubview as! SimulTrackLink)
                (firstHitSubview as! SimulTrackLink).touchBegan(touches, withEvent: event)
            }
            
        case "ADD_SEQ_LINK":
            if firstHitSubview is Track {
                var newLink = SeqTrackLink(frame: self.frame, withTrack: firstHitSubview as! Track)
                newLink.mode = "ADD_SEQ_LINK"
                allSeqLink.append(newLink)
                curSeqLinkAdd = newLink
                self.insertSubview(firstHitSubview, atIndex: self.subviews.count - 4)
                self.insertSubview(newLink, atIndex: self.subviews.count - 4)
                newLink.touchBegan(touches, withEvent: event)
            } else if firstHitSubview is SeqTrackLink {
                println("DELETE, MOVE, OR CHANGE TRACK LINK")
                curSeqLinkAdd = (firstHitSubview as! SeqTrackLink)
                (firstHitSubview as! SeqTrackLink).touchBegan(touches, withEvent: event)
            }
            
        case "TRASH":
            if firstHitSubview is Track {
                (firstHitSubview as! Track).deleteTrack()
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as! SimulTrackLink).deleteSimulTrackLink()
            } else if firstHitSubview is DrawView {
            
            }
            
        default:
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as! SimulTrackLink).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is SeqTrackLink {
                (firstHitSubview as! SeqTrackLink).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as! DrawView).touchBegan(touches, withEvent: event)
            } else {
                println("not important view for link manager")
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("TOUCHES MOVED LINK MANAGER")
        
        switch mode {
            
        case "ADD_SIMUL_LINK":
            let touch = touches.first as! UITouch
            var location: CGPoint = touch.locationInView(self)
            //determine the subview that is currently hit by moved touch
            var curHitSubview = UIView()
            for var i = self.subviews.count - 1; i >= 0; i-- {
                var subview = subviews[i]
                if subview is LinkManager {
                    continue
                } else if subview is Track {
                    if subview.frame.contains(location) {
                        curHitSubview = subview as! UIView
                        break
                    }
                } else if subview is SimulTrackLink {
                    if subview.pointInside(location, withEvent: event) {
                        curHitSubview = subview as! UIView
                        break
                    }
                }
            }
            
            println(curHitSubview)
            
            if curHitSubview is Track {
                curSimulLinkAdd.dequeueTrackFromAdding()
                self.insertSubview(curHitSubview, atIndex: self.subviews.count - 6)
                curSimulLinkAdd.queueTrackForAdding(curHitSubview as! Track)
            } else if curSimulLinkAdd != nil && curHitSubview == curSimulLinkAdd {
                println("WAS CURRENT ADDING LINK")
                curSimulLinkAdd.dequeueTrackFromAdding()
            } else if curHitSubview is SimulTrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
            } else {
                if curSimulLinkAdd != nil && curSimulLinkAdd.queuedTrackForAdding != nil {
                    curSimulLinkAdd.dequeueTrackFromAdding()
                }
            }
            
            //self.addLinkCurMovedLoc = location
            if self.curSimulLinkAdd != nil {
                self.curSimulLinkAdd.touchMoved(touches, withEvent: event)
            }
            
        case "ADD_SEQ_LINK":
            let touch = touches.first as! UITouch
            var location: CGPoint = touch.locationInView(self)
            //determine the subview that is currently hit by moved touch
            var curHitSubview = UIView()
            for var i = self.subviews.count - 1; i >= 0; i-- {
                var subview = subviews[i]
                if subview is LinkManager {
                    continue
                } else if subview is Track {
                    if subview.frame.contains(location) {
                        curHitSubview = subview as! UIView
                        break
                    }
                } else if subview is SeqTrackLink {
                    if subview.pointInside(location, withEvent: event) {
                        curHitSubview = subview as! UIView
                        break
                    }
                }
            }
            
            println(curHitSubview)
            
            if curHitSubview is Track {
                curSeqLinkAdd.dequeueTrackFromAdding()
                self.insertSubview(curHitSubview, atIndex: self.subviews.count - 6)
                curSeqLinkAdd.queueTrackForAdding(curHitSubview as! Track)
            } else if curSeqLinkAdd != nil && curHitSubview == curSeqLinkAdd {
                println("WAS CURRENT ADDING LINK")
                curSeqLinkAdd.dequeueTrackFromAdding()
            } else if curHitSubview is SeqTrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
            } else {
                if curSeqLinkAdd != nil && curSeqLinkAdd.queuedTrackForAdding != nil {
                    curSeqLinkAdd.dequeueTrackFromAdding()
                }
            }
            
            if self.curSeqLinkAdd != nil {
                self.curSeqLinkAdd.touchMoved(touches, withEvent: event)
            }
            
        case "TRASH":
            break //do nothing
            
        default:
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as! SimulTrackLink).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is SeqTrackLink {
                (firstHitSubview as! SeqTrackLink).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as! DrawView).touchMoved(touches, withEvent: event)
            } else {
                println("UIVIEW")
            }
        }
    }
   
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("TOUCHES ENDED LINK MANAGER")
        
        switch mode {
            
        case "ADD_SIMUL_LINK":
            println("add simul link mode")
            if curSimulLinkAdd != nil {
                if curSimulLinkAdd.queuedTrackForAdding != nil {
                    curSimulLinkAdd.commitEdgeToLink()
                    if curSimulLinkAdd.linkEdges.count > 1 {
                        curSimulLinkAdd.updateLinkCoreData()
                    } else {
                        curSimulLinkAdd.saveLinkCoreData(projectEntity)
                    }
                } else {
                    curSimulLinkAdd.deleteSimulTrackLink()
                }
                
                curSimulLinkAdd.touchEnded(touches, withEvent: event)
                curSimulLinkAdd = nil
            }

        case "ADD_SEQ_LINK":
            println("add seq link mode")
            if curSeqLinkAdd != nil {
                if curSeqLinkAdd.queuedTrackForAdding != nil {
                    curSeqLinkAdd.commitEdgeToLink()
                    /*if curSeqLinkAdd.linkEdges.count > 1 {
                        curSeqLinkAdd.updateLinkCoreData()
                    } else {
                        curSeqLinkAdd.saveLinkCoreData(projectEntity)
                    }*/
                } else {
                    curSeqLinkAdd.deleteSeqTrackLink()
                }
                
                curSeqLinkAdd.touchEnded(touches, withEvent: event)
                curSeqLinkAdd = nil
            }
        
        case "TRASH":
            println("trash mode")
            break //do nothing
            
        default:
            println("normal mode")
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as! SimulTrackLink).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is SeqTrackLink {
                (firstHitSubview as! SeqTrackLink).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as! DrawView).touchEnded(touches, withEvent: event)
            } else {
                println("OTHER UIVIEW")
            }
        }
    }
    
    func changeTrackToEditMode(gestureRecognizer: UIGestureRecognizer) {
        println("LONG PRESS RECOGNIZED")
        if mode == "" {
            var location = gestureRecognizer.locationInView(self)
            for var i = self.subviews.count - 1; i >= 0; i-- {
                var subview = subviews[i]
                if subview is LinkManager {
                    continue
                } else if subview is Track {
                    if subview.frame.contains(location) {
                        if (subview as! Track).hasStoppedRecording {
                            (subview as! Track).editMode(gestureRecognizer)
                        }
                        break
                    }
                } else if subview is SimulTrackLink {
                    if subview.pointInside(location, withEvent: nil) {
                        break
                    }
                }
            }
        }
    }
    
    func getTrackByID(trackID: String) -> Track? {
        for subview in self.subviews {
            if subview is Track && (subview as! Track).trackID == trackID {
                return (subview as! Track)
            }
        }
        return nil
    }
    
    func getTrackIndex(track: Track) -> Int {
        var trackIndex = -1
        for var i = self.subviews.count - 1; i >= 0; i-- {
            var subview = subviews[i]
            if subview is Track {
                if (subview as! Track) == track {
                    trackIndex = i
                }
            }
        }
        return trackIndex
    }
}

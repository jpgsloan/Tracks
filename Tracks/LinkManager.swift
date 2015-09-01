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
    var allTrackLinks: [TrackLink] = [TrackLink]()
    var firstHitSubview = UIView()
    var addLinkStartLoc: CGPoint!
    var addLinkCurMovedLoc: CGPoint!
    var curTrackLinkAdd: TrackLink!
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
        println("TOUCHED IN LINK MANAGER BEGAN")
        //Find the subview hit by touch
        firstHitSubview = UIView()
        println("------------------")
        for var i = self.subviews.count - 1; i >= 0; i-- {
            var subview = self.subviews[i]
            println(subview)
        }
        println("------------------")

        for var i = self.subviews.count - 1; i >= 0; i-- {
            var subview = self.subviews[i]
            if subview is LinkManager {
                continue
            } else if subview is Track || subview is DrawView {
                if subview.frame.contains(location) {
                    firstHitSubview = subview as! UIView
                    break
                }
            } else if subview is TrackLink {
                if subview.pointInside(location, withEvent: event) {
                    firstHitSubview = subview as! UIView
                    break
                }
            }
        }

        print("FIRST HIT SUBVIEW: ")
        println(firstHitSubview)
    
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            if firstHitSubview is Track {
                var newLink = TrackLink(frame: self.frame, withTrack: firstHitSubview as! Track)
                newLink.mode = mode
                allTrackLinks.append(newLink)
                curTrackLinkAdd = newLink
                self.insertSubview(firstHitSubview, atIndex: self.subviews.count - 4)
                self.insertSubview(newLink, atIndex: self.subviews.count - 4)
                newLink.saveLinkCoreData(projectEntity)
                newLink.touchBegan(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                println("DELETE, MOVE, OR CHANGE TRACK LINK")
                curTrackLinkAdd = (firstHitSubview as! TrackLink)
                curTrackLinkAdd.touchBegan(touches, withEvent: event)
            }
        } else if mode == "TRASH" {
            if firstHitSubview is Track {
                (firstHitSubview as! Track).deleteTrack()
            } else if firstHitSubview is TrackLink {
                (firstHitSubview as! TrackLink).deleteTrackLink()
            } else if firstHitSubview is DrawView {
                //Do nothing
            }
        } else {
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                (firstHitSubview as! TrackLink).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as! DrawView).touchBegan(touches, withEvent: event)
            } else {
                println("not important view for link manager")
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("TOUCHES MOVED LINK MANAGER")
        
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
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
                } else if subview is TrackLink {
                    if subview.pointInside(location, withEvent: event) {
                        curHitSubview = subview as! UIView
                        break
                    }
                }
            }
            
            println(curHitSubview)
            
            if curHitSubview is Track {
                curTrackLinkAdd.dequeueTrackFromAdding()
                self.insertSubview(curHitSubview, atIndex: self.subviews.count - 6)
                curTrackLinkAdd.queueTrackForAdding(curHitSubview as! Track)
            } else if curTrackLinkAdd != nil && curHitSubview == curTrackLinkAdd {
                println("WAS CURRENT ADDING LINK")
                curTrackLinkAdd.dequeueTrackFromAdding()
            } else if curHitSubview is TrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
            } else {
                if curTrackLinkAdd != nil && curTrackLinkAdd.queuedTrackForAdding != nil {
                    curTrackLinkAdd.dequeueTrackFromAdding()
                }
            }
            
            if curTrackLinkAdd != nil {
                curTrackLinkAdd.touchMoved(touches, withEvent: event)
            }
        } else if mode == "TRASH" {
            //Do nothing
        } else {
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                (firstHitSubview as! TrackLink).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as! DrawView).touchMoved(touches, withEvent: event)
            } else {
                println("UIVIEW")
            }
        }
    }
   
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("TOUCHES ENDED LINK MANAGER")
        
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            print("add link mode: ")
            println(mode)
            if curTrackLinkAdd != nil {
                if curTrackLinkAdd.queuedTrackForAdding != nil {
                    curTrackLinkAdd.commitEdgeToLink()
                    curTrackLinkAdd.bringTrackLinkToFront()
                } else {
                    curTrackLinkAdd.deleteTrackLink()
                }
                
                curTrackLinkAdd.touchEnded(touches, withEvent: event)
                curTrackLinkAdd = nil
            }
        } else if mode == "TRASH" {
            println("trash mode")
            //do nothing
        } else {
            println("normal mode")
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                (firstHitSubview as! TrackLink).touchEnded(touches, withEvent: event)
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
                } else if subview is TrackLink {
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

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

    var isInAddSimulLinkMode: Bool = false
    var isInAddSeqLinkMode: Bool = false
    var allSimulLink: Array<SimulTrackLink> = [SimulTrackLink]()
    var firstHitSubview = UIView()
    var addLinkStartLoc: CGPoint!
    var addLinkCurMovedLoc: CGPoint!
    var curSimulLinkAdd: SimulTrackLink!
    
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
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var touch: UITouch = event.allTouches()?.anyObject() as UITouch
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
                    firstHitSubview = subview as UIView
                    break
                }
            } else if subview is SimulTrackLink {
                if subview.pointInside(location, withEvent: event) {
                    firstHitSubview = subview as UIView
                    break
                }
            } else if subview is DrawView {
                if subview.frame.contains(location) {
                    firstHitSubview = subview as UIView
                    break
                }
            }
        }

        println(firstHitSubview)
        
        if isInAddSimulLinkMode {
            if firstHitSubview is Track {
                var newLink = SimulTrackLink(frame: self.frame, withTrack: firstHitSubview as Track)
                self.allSimulLink.append(newLink)
                self.curSimulLinkAdd = newLink
                self.addSubview(newLink)
                self.exchangeSubviewAtIndex(self.subviews.count - 1, withSubviewAtIndex: self.subviews.count - 4)
                (newLink as SimulTrackLink).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
            }
        
        } else if isInAddSeqLinkMode {
            if firstHitSubview is Track {
                print("ADD LINK WITH TRACK: ")
            } else if firstHitSubview is SeqTrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
            }
        } else {
            if firstHitSubview is Track {
                (firstHitSubview as Track).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as SimulTrackLink).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as DrawView).touchBegan(touches, withEvent: event)
            } else {
                println("UIVIEW")
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        println("TOUCHES MOVED LINK MANAGER")
        if !isInAddSimulLinkMode && !isInAddSeqLinkMode {
            if firstHitSubview is Track {
                (firstHitSubview as Track).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as SimulTrackLink).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as DrawView).touchMoved(touches, withEvent: event)
            } else {
                println("UIVIEW")
            }
        } else {
            var touch: UITouch = touches.anyObject() as UITouch
            var location: CGPoint = touch.locationInView(self)
            var curHitSubview = UIView()
            for var i = self.subviews.count - 1; i >= 0; i-- {
                var subview = subviews[i]
                if subview is LinkManager {
                    continue
                } else if subview is Track {
                    if subview.frame.contains(location) {
                        curHitSubview = subview as UIView
                        break
                    }
                } else if subview is SimulTrackLink {
                    if subview.pointInside(location, withEvent: event) {
                        curHitSubview = subview as UIView
                        break
                    }
                }
            }
            
            println(curHitSubview)
            
            if curHitSubview is Track {
                self.curSimulLinkAdd.queueTrackForAdding(curHitSubview as Track)
            } else if self.curSimulLinkAdd != nil && curHitSubview == self.curSimulLinkAdd {
                println("WAS CURRENT ADDING LINK")
            } else if curHitSubview is SimulTrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
            } else {
                if self.curSimulLinkAdd != nil && self.curSimulLinkAdd.queuedTrackForAdding != nil {
                    self.curSimulLinkAdd.dequeueTrackFromAdding()
                }
            }
            
            self.addLinkCurMovedLoc = location
            if self.curSimulLinkAdd != nil {
                self.curSimulLinkAdd.touchMoved(touches, withEvent: event)
            }
        }
    }
   
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        println("TOUCHES ENDED LINK MANAGER")
        if !isInAddSimulLinkMode && !isInAddSeqLinkMode {
            if firstHitSubview is Track {
                (firstHitSubview as Track).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is SimulTrackLink {
                (firstHitSubview as SimulTrackLink).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as DrawView).touchEnded(touches, withEvent: event)
            } else {
                println("OTHER UIVIEW")
            }
        } else {
            if self.curSimulLinkAdd != nil {
                if self.curSimulLinkAdd.queuedTrackForAdding != nil {
                    self.curSimulLinkAdd.commitEdgeToLink()
                } else {
                    self.curSimulLinkAdd.removeFromSuperview()
                    self.curSimulLinkAdd.prepareForDelete()
                }
                
                self.curSimulLinkAdd.touchEnded(touches, withEvent: event)
                self.curSimulLinkAdd = nil
            }
        }
    }
    
    func changeTrackToEditMode(gestureRecognizer: UIGestureRecognizer) {
        println("LONG PRESS RECOGNIZED")
        if !isInAddSimulLinkMode && !isInAddSeqLinkMode {
            var location = gestureRecognizer.locationInView(self)
            for var i = self.subviews.count - 1; i >= 0; i-- {
                var subview = subviews[i]
                if subview is LinkManager {
                    continue
                } else if subview is Track {
                    if subview.frame.contains(location) {
                        if (subview as Track).hasStoppedRecording {
                            (subview as Track).editMode(gestureRecognizer)
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
}

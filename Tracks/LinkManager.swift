//
//  LinkManager.swift
//  Tracks
//
//  Created by John Sloan on 5/7/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation

class LinkManager: UIView, UIGestureRecognizerDelegate {

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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        let longPressEdit = UILongPressGestureRecognizer(target: self, action: "changeTrackToEditMode:")
        longPressEdit.numberOfTapsRequired = 0
        longPressEdit.allowableMovement = CGFloat(2)
        longPressEdit.delegate = self
        self.addGestureRecognizer(longPressEdit)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first!
        let location: CGPoint = touch.locationInView(touch.window)
        print("TOUCHED IN LINK MANAGER BEGAN")
        //Find the subview hit by touch
        firstHitSubview = UIView()
        print("------------------")
        for var i = self.subviews.count - 1; i >= 0; i-- {
            print(self.subviews[i])
        }
        print("------------------")

        for var i = self.subviews.count - 1; i >= 0; i-- {
            let subview = self.subviews[i]
            if subview is LinkManager {
                continue
            } else if subview is Track || subview is DrawView {
                if subview.frame.contains(location) {
                    firstHitSubview = subview 
                    break
                }
            } else if subview is TrackLink {
                if subview.pointInside(location, withEvent: event) {
                    firstHitSubview = subview 
                    break
                }
            }
        }

        print("FIRST HIT SUBVIEW: ", terminator: "")
        print(firstHitSubview)
    
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            if firstHitSubview is Track {
                let newLink = TrackLink(frame: self.frame, withTrack: firstHitSubview as! Track)
                newLink.mode = mode
                allTrackLinks.append(newLink)
                curTrackLinkAdd = newLink
                self.insertSubview(firstHitSubview, atIndex: self.subviews.count - 4)
                self.insertSubview(newLink, atIndex: self.subviews.count - 4)
                newLink.saveLinkCoreData(projectEntity)
                newLink.touchBegan(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK")
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
        } else if mode == "NOTOUCHES" {
            //Do nothing
        } else {
            if firstHitSubview is Track {
                (firstHitSubview as! Track).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                (firstHitSubview as! TrackLink).touchBegan(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                (firstHitSubview as! DrawView).touchBegan(touches, withEvent: event)
            } else {
                print("not important view for link manager")
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TOUCHES MOVED LINK MANAGER")
        
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            let touch = touches.first!
            var location: CGPoint = touch.locationInView(self)
            //determine the subview that is currently hit by moved touch
            var curHitSubview = UIView()
            for var i = self.subviews.count - 1; i >= 0; i-- {
                var subview = subviews[i]
                if subview is LinkManager {
                    continue
                } else if subview is Track {
                    if subview.frame.contains(location) {
                        curHitSubview = subview 
                        break
                    }
                } else if subview is TrackLink {
                    if subview.pointInside(location, withEvent: event) {
                        curHitSubview = subview 
                        break
                    }
                }
            }
            
            print(curHitSubview)
            
            if curHitSubview is Track {
                curTrackLinkAdd.dequeueTrackFromAdding()
                self.insertSubview(curHitSubview, atIndex: self.subviews.count - 6)
                curTrackLinkAdd.queueTrackForAdding(curHitSubview as! Track)
            } else if curTrackLinkAdd != nil && curHitSubview == curTrackLinkAdd {
                print("WAS CURRENT ADDING LINK")
                curTrackLinkAdd.dequeueTrackFromAdding()
            } else if curHitSubview is TrackLink {
                print("DELETE, MOVE, OR CHANGE TRACK LINK", terminator: "")
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
        } else if mode == "NOTOUCHES" {
            //Do nothing
        } else {
            if firstHitSubview is Track {
                hideToolbars(true)
                (firstHitSubview as! Track).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                hideToolbars(true)
                (firstHitSubview as! TrackLink).touchMoved(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                hideToolbars(true)
                (firstHitSubview as! DrawView).touchMoved(touches, withEvent: event)
            } else {
                print("UIVIEW")
            }
        }
    }
   
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("TOUCHES ENDED LINK MANAGER")
        
        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            print("add link mode: \(mode)")
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
            print("trash mode")
            //do nothing
        } else if mode == "NOTOUCHES" {
            print("no touches mode (used for open notes, sidebar, edit mode)")
            //Do nothing
        } else {
            print("normal mode")
            if firstHitSubview is Track {
                hideToolbars(false)
                (firstHitSubview as! Track).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is TrackLink {
                hideToolbars(false)
                (firstHitSubview as! TrackLink).touchEnded(touches, withEvent: event)
            } else if firstHitSubview is DrawView {
                hideToolbars(false)
                (firstHitSubview as! DrawView).touchEnded(touches, withEvent: event)
            } else {
                print("OTHER UIVIEW")
            }
        }
    }
    
    func hideToolbars(shouldHide: Bool) {        
        var navigationBar: UINavigationBar?
        var toolbar: UIToolbar?
        var statusBarBackground: UIVisualEffectView?
        for var i = self.subviews.count - 1; i >= 0; i-- {
            let subview = subviews[i]
            if subview is UINavigationBar {
                navigationBar = subview as! UINavigationBar
            } else if subview is UIToolbar {
                toolbar = subview as! UIToolbar
            } else if subview is UIVisualEffectView {
                statusBarBackground = subview as! UIVisualEffectView
            } else {
                continue
            }
        }
        if toolbar != nil && navigationBar != nil && statusBarBackground != nil {
            // fade out toolbar and navbar            
            if shouldHide {
                UIView.beginAnimations("fade", context: nil)
                navigationBar!.alpha = 0.0
                toolbar!.alpha = 0.0
                statusBarBackground!.alpha = 0.0
                UIView.commitAnimations()
            } else {
                UIView.beginAnimations("fade", context: nil)
                navigationBar!.alpha = 1.0
                toolbar!.alpha = 1.0
                statusBarBackground!.alpha = 1.0
                UIView.commitAnimations()
            }
        }
    }
    
    func changeTrackToEditMode(gestureRecognizer: UIGestureRecognizer) {
        print("LONG PRESS RECOGNIZED")
        if mode == "" {
            hideToolbars(true)
            let location = gestureRecognizer.locationInView(self)
            for var i = self.subviews.count - 1; i >= 0; i-- {
                let subview = subviews[i]
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
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if mode == "NOTOUCHES" {
            return false
        } else {
            return true
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
            let subview = subviews[i]
            if subview is Track {
                if (subview as! Track) == track {
                    trackIndex = i
                }
            }
        }
        return trackIndex
    }
}

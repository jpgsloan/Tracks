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
                self.insertSubview(firstHitSubview, atIndex: self.subviews.count - 5)
                self.insertSubview(newLink, atIndex: self.subviews.count - 5)
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
                (firstHitSubview as! TrackLink).deleteLinkEdge(location)
            } else if firstHitSubview is DrawView {
                //Do nothing
                (firstHitSubview as! DrawView).deleteLineContainingTouch(location)
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
        let touch = touches.first!
        let location: CGPoint = touch.locationInView(self)

        if mode == "ADD_SEQ_LINK" || mode == "ADD_SIMUL_LINK" {
            //determine the subview that is currently hit by moved touch
            var curHitSubview = UIView()
            for var i = self.subviews.count - 1; i >= 0; i-- {
                let subview = subviews[i]
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
                self.insertSubview(curHitSubview, atIndex: self.subviews.count - 5)
                curTrackLinkAdd.queueTrackForAdding(curHitSubview as! Track)
            } else if curTrackLinkAdd != nil && curHitSubview == curTrackLinkAdd {
                print("WAS CURRENT ADDING LINK")
                curTrackLinkAdd.dequeueTrackFromAdding()
                if let curTrack = curTrackLinkAdd.trackAtPoint(location) {
                    print("touched track was: \(curTrack)")
                    curTrackLinkAdd.queueTrackForAdding(curTrack)
                }
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
                } else if subview is DrawView {
                    curHitSubview = subview
                }
            }
            
            if curHitSubview is Track {
                (curHitSubview as! Track).deleteTrack()
            } else if curHitSubview is TrackLink {
                (curHitSubview as! TrackLink).deleteLinkEdge(location)
            } else if curHitSubview is DrawView {
                //Do nothing
                (curHitSubview as! DrawView).deleteLineContainingTouch(location)
            }
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
                    curTrackLinkAdd.dequeueTrackFromAdding()
                    let hasNoNodes = curTrackLinkAdd.trackNodeIDs.isEmpty && curTrackLinkAdd.unrecordedTracks.isEmpty
                    let hasOneNode = (curTrackLinkAdd.trackNodeIDs.count == 1 && curTrackLinkAdd.unrecordedTracks.isEmpty) || (curTrackLinkAdd.trackNodeIDs.isEmpty && curTrackLinkAdd.unrecordedTracks.count == 1)
                    // if tracklink contains one or zero nodes, delete it.
                    if  hasNoNodes || hasOneNode {
                        curTrackLinkAdd.deleteTrackLink()
                    }
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
        var modeSegmentedControl: ModeSelectSegmentedControl?
        var statusBarBackground: UIView?
        for var i = self.subviews.count - 1; i >= 0; i-- {
            let subview = subviews[i]
            if subview is UINavigationBar {
                navigationBar = subview as! UINavigationBar
            } else if subview is ModeSelectSegmentedControl {
                modeSegmentedControl = subview as! ModeSelectSegmentedControl
            } else if subview is UIVisualEffectView {
                statusBarBackground = subview as! UIVisualEffectView
            } else {
                continue
            }
        }
        if modeSegmentedControl != nil && navigationBar != nil && statusBarBackground != nil {
            // fade out toolbar and navbar            
            if shouldHide {
                UIView.beginAnimations("fade", context: nil)
                navigationBar!.alpha = 0.0
                modeSegmentedControl!.alpha = 0.0
                statusBarBackground!.alpha = 0.0
                UIView.commitAnimations()
            } else {
                UIView.beginAnimations("fade", context: nil)
                navigationBar!.alpha = 1.0
                modeSegmentedControl!.alpha = 1.0
                statusBarBackground!.alpha = 1.0
                UIView.commitAnimations()
            }
        }
    }
    
    func showStopButton() {
        let stopButton = self.viewWithTag(5109)
        if stopButton != nil && stopButton is UIButton {
            // fade in stopButton
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            stopButton!.layer.addAnimation(animation, forKey: nil)
            stopButton!.hidden = false
        }
    }
    
    func hideStopButton() {
        let stopButton = self.viewWithTag(5109)
        let anyTracksPLaying = tracksPlaying()
        if !anyTracksPLaying && stopButton != nil && stopButton is UIButton {
            // fade out stopButton if all tracks have finished playing.
            print("stopping audio")
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            stopButton!.layer.addAnimation(animation, forKey: nil)
            stopButton!.hidden = true
        }
    }
    
    func tracksPlaying() -> Bool {
        for subview in self.subviews {
            if subview is Track {
                if (subview as! Track).audioPlayer != nil {
                    if (subview as! Track).audioPlayer!.playing {
                        return true
                    }
                } else {
                    print("audioPlayer is nil")
                }
            }
        }
        return false
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
        // Returns track for the given trackID
        for subview in self.subviews {
            if subview is Track && (subview as! Track).trackID == trackID {
                return (subview as! Track)
            }
        }
        return nil
    }
    
    func getTrackIndex(track: Track) -> Int {
        // Gets index of the track in the subviews array, used for knowing which track is on top.
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

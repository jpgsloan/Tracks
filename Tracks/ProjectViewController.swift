
//
//  ViewController.swift
//  Tracks
//
//  Created by John Sloan on 1/28/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore
import CoreData

class ProjectViewController: UIViewController, UITextFieldDelegate {
    
    var filemanager = NSFileManager.defaultManager()
    var projectDirectory: String!
    var createProjectFolder = true
    var projectID: String = ""
    var projectName: String = ""
    var projectEntity: ProjectEntity!
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var tracks: NSMutableArray = []
    var notesView: NotesView!
    var statusBarBackgroundView: UIView!
    var sideBarOpenBackgroundView: UIVisualEffectView!
    var drawView: DrawView!
    var lowerBorderTitle: CALayer!
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var navBarVertConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkManager: LinkManager!
    @IBOutlet weak var addTrackButton: UIButton!
    @IBOutlet weak var modeSegmentedControl: ModeSelectSegmentedControl!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var linkBackgroundTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add draw view
        drawView = DrawView(frame: self.view.frame)
        drawView.backgroundColor = UIColor.clearColor()
        drawView.layer.backgroundColor = UIColor(red: 75.0/255.0, green: 84.0/255.0, blue: 90.0/255.0, alpha: 1.0).CGColor
        self.view.addSubview(drawView)
        
        // Add lower border to title text
        lowerBorderTitle = CALayer()
        lowerBorderTitle.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        titleTextField.layer.addSublayer(lowerBorderTitle)
        
        // Create background view for styling status bar
        statusBarBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20 + navigationBar.frame.height))
        statusBarBackgroundView.backgroundColor = navigationBar.backgroundColor
        self.view.addSubview(statusBarBackgroundView)
        
        // remove shadow line on navigation bar
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        
        // change some background colors
        linkBackgroundTextView.backgroundColor = UIColor(red: 75.0/255.0, green: 84.0/255.0, blue: 90.0/255.0, alpha: 0.9)
        modeSegmentedControl.backgroundColor = modeSegmentedControl.backgroundColor?.colorWithAlphaComponent(0.9)
        
        // add background circle to addTrackButton and stopButton
        addTrackButton.layer.cornerRadius = addTrackButton.frame.width / 2.0
        let circleLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: addTrackButton.bounds, cornerRadius: addTrackButton.layer.cornerRadius)
        circleLayer.path = path.CGPath
        circleLayer.fillColor = modeSegmentedControl.backgroundColor?.CGColor
        circleLayer.strokeColor = modeSegmentedControl.backgroundColor?.CGColor
        circleLayer.frame = addTrackButton.layer.bounds
        addTrackButton.layer.insertSublayer(circleLayer, below: addTrackButton.imageView!.layer)
        
        stopButton.layer.cornerRadius = stopButton.frame.width / 2.0
        let circleStopLayer = CAShapeLayer()
        let stopPath = UIBezierPath(roundedRect: stopButton.bounds, cornerRadius: stopButton.layer.cornerRadius)
        circleStopLayer.path = stopPath.CGPath
        circleStopLayer.fillColor = modeSegmentedControl.backgroundColor?.CGColor
        circleStopLayer.strokeColor = modeSegmentedControl.backgroundColor?.CGColor
        circleStopLayer.frame = stopButton.layer.bounds
        stopButton.layer.insertSublayer(circleStopLayer, below: stopButton.imageView!.layer)
        
        //set some tags so it's easy to find from LinkManager
        stopButton.tag = 5109
        navigationBar.tag = 847
        modeSegmentedControl.tag = 306
        
        // Create notesView
        notesView = NotesView(frame: self.view.bounds)
        
        // Check if project folder already exists
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let allProjects = try? filemanager.contentsOfDirectoryAtPath(docDirectory)
        for project in allProjects! {
            if project as NSString == projectID {
                createProjectFolder = false
                break
            }
        }
        
        // Create new folder for project if needed. stores audio files in this location.
        if createProjectFolder {
            print("CREATING NEW PROJECT FOLDER")
            let newDirectory = NSString(string: docDirectory).stringByAppendingPathComponent(projectID)
            var error: NSError?
            do {
                try filemanager.createDirectoryAtPath(newDirectory, withIntermediateDirectories: true, attributes: nil)
                projectDirectory = newDirectory
            } catch let error1 as NSError {
                error = error1
                print("could not make new project directory: \(error!.localizedDescription) ")
            }
        } else {
            print("LOADING OLD PROJECT")
            projectDirectory = NSString(string: docDirectory).stringByAppendingPathComponent(projectID)
        }
        
        // Assign context, and its core data project entity if it exists.
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        let request = NSFetchRequest(entityName: "ProjectEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectID = %@", argumentArray: [projectID])
        let results: NSArray = try! context.executeFetchRequest(request)
      
        if results.count < 1 {
            projectEntity =  NSEntityDescription.insertNewObjectForEntityForName("ProjectEntity", inManagedObjectContext: context) as! ProjectEntity
            projectEntity.projectID = projectID
            if drawView != nil {
                drawView.saveAllPaths(projectEntity)
                notesView.saveNotes(projectEntity)
            }
        } else {
            projectEntity = results[0] as! ProjectEntity
            drawView.projectEntity = projectEntity
            drawView.loadAllPaths()
            
            notesView.projectEntity = projectEntity
            notesView.loadNotes()
        }
        
        //Pass on the project entity to give to newly-added links
        linkManager.projectEntity = projectEntity
        
        loadTracks()
        
        self.view.bringSubviewToFront(statusBarBackgroundView)
        self.view.bringSubviewToFront(navigationBar)
        self.view.bringSubviewToFront(modeSegmentedControl)
        self.view.bringSubviewToFront(addTrackButton)
        self.view.bringSubviewToFront(stopButton)
        self.view.sendSubviewToBack(drawView)
        self.view.sendSubviewToBack(linkBackgroundTextView)
    }
    
    override func viewDidAppear(animated: Bool) {
        loadLinks()
    }
    
    override func viewDidLayoutSubviews() {
        titleTextField.text = projectName
        titleTextField.textAlignment = NSTextAlignment.Center
        titleTextField.delegate = self

        // realigns frame for drawview after all subviews were laid out.
        drawView.frame = self.view.frame
        
        // realign titleText lower border layer.
        lowerBorderTitle.frame = CGRectMake(titleTextField.frame.width / 6.0, titleTextField.frame.height - 0.5, titleTextField.frame.width * 4.0 / 6.0, 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addTrack(sender: UIButton) {
        //Create new Track and set project directory where sound files will be stored.
        let newTrack = Track(frame: CGRect(x: self.view.center.x,y: self.view.center.y,width: 100.0,height: 100.0), projectDir: projectDirectory)
        
        //Center and add the new track node.
        newTrack.center = self.view.center
        newTrack.setLabelNameText("untitled")
        newTrack.saveTrackCoreData(projectEntity)

        tracks.addObject(newTrack)
        
        if (linkManager.mode == "ADD_SIMUL_LINK" || linkManager.mode == "ADD_SIMUL_LINK") && tracks.count < 2 {
            // there are not enough tracks to use links so display message to guide user
            showLinkBackgroundText()
            self.view.insertSubview(newTrack, belowSubview: linkBackgroundTextView)
            newTrack.setNeedsLayout()
            newTrack.layoutIfNeeded()
            newTrack.linkMode()
        } else {
            hideLinkBackgroundText()

            self.view.insertSubview(newTrack, atIndex: self.view.subviews.count - 5)// +1 - 6 since you are adding a new subview not yet counted in subviews.count*/
            
            if (linkManager.mode == "ADD_SIMUL_LINK" || linkManager.mode == "ADD_SIMUL_LINK") {
                newTrack.setNeedsLayout()
                newTrack.layoutIfNeeded()
                newTrack.linkMode()
            }
        }
        
    }
    
    @IBAction func openSideBarVC(sender: UIBarButtonItem) {
        if titleTextField.isFirstResponder() {
            titleTextField.resignFirstResponder()
            if let projectName = titleTextField.text {
                (parentViewController as! ProjectManagerViewController).updateProjectName(projectID, projectName: projectName)
                self.projectName = projectName
            }
        }
        
        let effect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        sideBarOpenBackgroundView = UIVisualEffectView(frame: self.view.frame)
        sideBarOpenBackgroundView.effect = effect
        sideBarOpenBackgroundView.alpha = 0.0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "closeSideBarVC:")
        tapGesture.numberOfTapsRequired = 1
        sideBarOpenBackgroundView.addGestureRecognizer(tapGesture)
        (self.view as! LinkManager).mode = "NOTOUCHES"
        self.view.addSubview(sideBarOpenBackgroundView)
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.sideBarOpenBackgroundView.alpha = 1.0
            }, completion: { (bool:Bool) -> Void in
        })
        
        (parentViewController as! ProjectManagerViewController).openSideBarVC()
    }
        
    func closeSideBarVC(gestureRecognizer:UIGestureRecognizer) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.sideBarOpenBackgroundView.alpha = 0.0
            }, completion: { (bool:Bool) -> Void in
                self.sideBarOpenBackgroundView.removeFromSuperview()
        })
        
        (parentViewController as! ProjectManagerViewController).closeSideBarVC()
        (self.view as! LinkManager).mode = ""
    }
    
    func sideBarOpened() {
        // called when project is opened in background with side bar already open.
        let effect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        sideBarOpenBackgroundView = UIVisualEffectView(frame: self.view.frame)
        sideBarOpenBackgroundView.effect = effect
        sideBarOpenBackgroundView.alpha = 1.0
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "closeSideBarVC:")
        tapGesture.numberOfTapsRequired = 1
        sideBarOpenBackgroundView.addGestureRecognizer(tapGesture)
        (self.view as! LinkManager).mode = "NOTOUCHES"
        self.view.addSubview(sideBarOpenBackgroundView)
    }
    
    func sideBarClosed() {
        if sideBarOpenBackgroundView != nil {
            sideBarOpenBackgroundView.removeFromSuperview()
        }
    }
    
    @IBAction func changeMode(sender: ModeSelectSegmentedControl) {        
        // for fading out/in buttons particular to each mode
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.2
        
        switch sender.selectedIndex {
        case 0:
            print("normal mode")
            addTrackButton.layer.addAnimation(animation, forKey: nil)
            addTrackButton.hidden = false
            enterMoveMode()
        case 1:
            print("link mode")
            addTrackButton.layer.addAnimation(animation, forKey: nil)
            addTrackButton.hidden = false
            addLinkMode()
        case 2:
            print("trash mode")
            addTrackButton.layer.addAnimation(animation, forKey: nil)
            addTrackButton.hidden = true
            enterTrashMode()
        default:
            print("mode index out of range")
        }
    }
    
    func enterMoveMode() {
        hideLinkBackgroundText()
        
        if linkManager.mode != "" {
            linkManager.mode = ""
            for link in linkManager.allTrackLinks {
                link.mode = ""
            }
        }
        
        for var i = tracks.count - 1; i >= 0; i-- {
            if let track = tracks.objectAtIndex(i) as? Track {
                if !track.hasBeenDeleted {
                    track.moveMode()
                } else {
                    // remove track from array
                    tracks.removeObjectAtIndex(i)
                }
            }
        }
    }
    
    func addLinkMode() {
        // show/hide link background text
        if tracks.count < 2 {
            showLinkBackgroundText()
        } else {
            hideLinkBackgroundText()
        }
        
        // inform link manager of mode change
        if linkManager.mode != "ADD_SIMUL_LINK" && linkManager.mode != "ADD_SEQ_LINK" {
            linkManager.mode = "ADD_SIMUL_LINK"
            for link in linkManager.allTrackLinks {
                link.mode = "ADD_SIMUL_LINK"
            }
        }
        
        for var i = tracks.count - 1; i >= 0; i-- {
            if let track = tracks.objectAtIndex(i) as? Track {
                if !track.hasBeenDeleted {
                    track.linkMode()
                } else {
                    // remove track from array
                    tracks.removeObjectAtIndex(i)
                }
            }
        }
    }
    
    func enterTrashMode() {
        hideLinkBackgroundText()
        
        if linkManager.mode != "TRASH" {
            linkManager.mode = "TRASH"
            for link in linkManager.allTrackLinks {
                link.mode = "TRASH"
            }
        }
        
        for var i = tracks.count - 1; i >= 0; i-- {
            if let track = tracks.objectAtIndex(i) as? Track {
                if !track.hasBeenDeleted {
                    track.trashMode()
                } else {
                    // remove track from array
                    tracks.removeObjectAtIndex(i)
                }
            }
        }

    }
   
    @IBAction func toggleNotes(sender: UIBarButtonItem) {
        // add notes view
        notesView.frame = self.view.frame
        self.view.addSubview(notesView)
        
        var tmpFrame: CGRect = notesView.frame
        tmpFrame.origin.x = 4
        tmpFrame.origin.y = 50
        tmpFrame.size.width = self.view.frame.width - 8
        tmpFrame.size.height = self.view.frame.height - 100

        notesView.openNotes(tmpFrame)
    }
    
    func hideLinkBackgroundText() {
        // hides link background text if currently displayed
        if !linkBackgroundTextView.hidden {
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            animation.delegate = self
            linkBackgroundTextView.layer.addAnimation(animation, forKey: nil)
            linkBackgroundTextView.hidden = true
        }
    }
    
    func showLinkBackgroundText() {
        // there are not enough tracks so display message to guide user
        if linkBackgroundTextView.hidden {
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            linkBackgroundTextView.layer.addAnimation(animation, forKey: nil)
            self.view.insertSubview(linkBackgroundTextView, atIndex: self.view.subviews.count - 6)
            linkBackgroundTextView.hidden = false
        }
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        self.view.sendSubviewToBack(linkBackgroundTextView)
    }
    
    @IBAction func stopAudio(sender: UIButton) {
        for track in tracks {
            (track as! Track).stopAudio()
        }
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.2
        stopButton.layer.addAnimation(animation, forKey: nil)
        stopButton.hidden = true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        if let projectName = titleTextField.text {
            (parentViewController as! ProjectManagerViewController).updateProjectName(projectID, projectName: projectName)
            self.projectName = projectName
        }
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func loadTracks() {
        let request = NSFetchRequest(entityName: "ProjectEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectID = %@", argumentArray: [projectID])
        let results: NSArray = try! context.executeFetchRequest(request)

        if (results.count > 0) {
            let res = results[0] as! ProjectEntity
            for track in res.track {
                let trackEntity = track as! TrackEntity
                let trackToAdd = NSKeyedUnarchiver.unarchiveObjectWithData(trackEntity.track) as! Track
                tracks.addObject(trackToAdd)
                self.view.addSubview(trackToAdd)
            }
        }
    }
    
    func loadLinks() {
        let request = NSFetchRequest(entityName: "ProjectEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectID = %@", argumentArray: [projectID])
        let results: NSArray = try! context.executeFetchRequest(request)
        if (results.count > 0) {
            let res = results[0] as! ProjectEntity
            for link in res.link {
                let linkEntity = link as! LinkEntity
                print("Loading link")
                //Get stored array of tracklink nodes and create new link
                let linkNodes = NSKeyedUnarchiver.unarchiveObjectWithData(linkEntity.linkNodes) as! [TrackLinkNode]
                
                //Create audioplayer dictionary from linkNodes
                var trackNodeIDs = [AVAudioPlayer:TrackLinkNode]()
                var unrecordedTracks = [Track: TrackLinkNode]()
                for node in linkNodes {
                    if let track = (self.view as! LinkManager).getTrackByID(node.rootTrackID) {
                        if track.audioPlayer != nil {
                            trackNodeIDs[track.audioPlayer!] = node
                        } else {
                            unrecordedTracks[track] = node
                        }
                    }
                }
                
                let linkToAdd = TrackLink(frame: self.view.frame, withTrackNodeIDs: trackNodeIDs, unrecordedTracks: unrecordedTracks, rootTrackID: linkEntity.rootTrackID, linkID: linkEntity.linkID)
                linkManager.allTrackLinks.append(linkToAdd)
                self.view.insertSubview(linkToAdd, atIndex: self.view.subviews.count - 6)
            }
        }
    }

}

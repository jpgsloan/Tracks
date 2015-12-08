
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
    var sideBarOpenBackgroundView: UIView!
    var notesOpenBackgroundView: UIView!
    var drawView: DrawView!
    var lowerBorderTitle: CALayer!
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var navBarVertConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkManager: LinkManager!
    @IBOutlet weak var addTrackButton: UIButton!
    @IBOutlet weak var modeSegmentedControl: ModeSelectSegmentedControl!
    @IBOutlet weak var seqLinkButton: UIButton!
    @IBOutlet weak var simulLinkButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add draw view
        drawView = DrawView(frame: self.view.frame)
        drawView.backgroundColor = UIColor.clearColor()
        drawView.layer.backgroundColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0).CGColor
        self.view.addSubview(drawView)
        
        // Add lower border to title text
        lowerBorderTitle = CALayer()
        lowerBorderTitle.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        titleTextField.layer.addSublayer(lowerBorderTitle)
        
        // Create background view for styling status bar
        statusBarBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20 + navigationBar.frame.height))
        statusBarBackgroundView.backgroundColor = navigationBar.backgroundColor
        // Add bottom border of slightly darker color
        let lowerBorder = CALayer()
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if let bool = statusBarBackgroundView.backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a) {
            lowerBorder.backgroundColor = UIColor(red: max(r - 0.1, 0.0), green: max(g - 0.1, 0.0), blue: max(b - 0.1, 0.0), alpha: a).CGColor
        }
        lowerBorder.frame = CGRectMake(0, statusBarBackgroundView.frame.height - 1.0, statusBarBackgroundView.frame.width, 1.0)
        statusBarBackgroundView.layer.addSublayer(lowerBorder)
        self.view.addSubview(statusBarBackgroundView)
        
        // remove shadow line on navigation bar
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        // add border to addTrackButton
        addTrackButton.layer.borderWidth = 1.0
        addTrackButton.layer.borderColor = UIColor(red: max(240.0/255.0 - 0.1, 0.0), green: max(240.0/255.0 - 0.1, 0.0), blue: max(240.0/255.0 - 0.1, 0.0), alpha: 1.0).CGColor
        
        // add border to simul/seq link and stop buttons (initially hidden)
        simulLinkButton.layer.borderWidth = 1.0
        simulLinkButton.layer.borderColor = UIColor(red: max(240.0/255.0 - 0.1, 0.0), green: max(240.0/255.0 - 0.1, 0.0), blue: max(240.0/255.0 - 0.1, 0.0), alpha: 1.0).CGColor
        
        seqLinkButton.layer.borderWidth = 1.0
        seqLinkButton.layer.borderColor = UIColor(red: max(240.0/255.0 - 0.1, 0.0), green: max(240.0/255.0 - 0.1, 0.0), blue: max(240.0/255.0 - 0.1, 0.0), alpha: 1.0).CGColor
        
        stopButton.layer.borderWidth = 1.0
        stopButton.layer.borderColor = UIColor(red: max(240.0/255.0 - 0.1, 0.0), green: max(240.0/255.0 - 0.1, 0.0), blue: max(240.0/255.0 - 0.1, 0.0), alpha: 1.0).CGColor
        
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
        loadLinks()
        self.view.bringSubviewToFront(statusBarBackgroundView)
        self.view.bringSubviewToFront(navigationBar)
        self.view.bringSubviewToFront(modeSegmentedControl)
        self.view.bringSubviewToFront(addTrackButton)
        self.view.sendSubviewToBack(drawView)
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
        self.view.insertSubview(newTrack, atIndex: self.view.subviews.count - 4) //+1 - 5 since you are adding a new subview not yet counted in subviews.count
    }
        
    @IBAction func openSideBarVC(sender: UIBarButtonItem) {
        sideBarOpenBackgroundView = UIView(frame: self.view.frame)
        sideBarOpenBackgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.0)
        let tapGesture = UITapGestureRecognizer(target: self, action: "closeSideBarVC:")
        tapGesture.numberOfTapsRequired = 1
        sideBarOpenBackgroundView.addGestureRecognizer(tapGesture)
        (self.view as! LinkManager).mode = "NOTOUCHES"
        self.view.addSubview(sideBarOpenBackgroundView)
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.sideBarOpenBackgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.5)
            }, completion: { (bool:Bool) -> Void in
        })
        
        (parentViewController as! ProjectManagerViewController).openSideBarVC()
    }
        
    func closeSideBarVC(gestureRecognizer:UIGestureRecognizer) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.sideBarOpenBackgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.0)
            }, completion: { (bool:Bool) -> Void in
                self.sideBarOpenBackgroundView.removeFromSuperview()
        })
        
        (parentViewController as! ProjectManagerViewController).closeSideBarVC()
        (self.view as! LinkManager).mode = ""
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
            simulLinkButton.layer.addAnimation(animation, forKey: nil)
            simulLinkButton.hidden = true
            seqLinkButton.layer.addAnimation(animation, forKey: nil)
            seqLinkButton.hidden = true
            addTrackButton.layer.addAnimation(animation, forKey: nil)
            addTrackButton.hidden = false
            enterMoveMode()
        case 1:
            print("link mode")
            simulLinkButton.layer.addAnimation(animation, forKey: nil)
            simulLinkButton.hidden = false
            seqLinkButton.layer.addAnimation(animation, forKey: nil)
            seqLinkButton.hidden = false
            addTrackButton.layer.addAnimation(animation, forKey: nil)
            addTrackButton.hidden = false
            addLinkMode()
        case 2:
            print("trash mode")
            simulLinkButton.layer.addAnimation(animation, forKey: nil)
            simulLinkButton.hidden = true
            seqLinkButton.layer.addAnimation(animation, forKey: nil)
            seqLinkButton.hidden = true
            addTrackButton.layer.addAnimation(animation, forKey: nil)
            addTrackButton.hidden = true
            enterTrashMode()
        default:
            print("mode index out of range")
        }
    }
    
    func enterMoveMode() {
        if linkManager.mode != "" {
            linkManager.mode = ""
            for link in linkManager.allTrackLinks {
                link.mode = ""
            }
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.drawView.layer.backgroundColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0).CGColor
                }) { (bool:Bool) -> Void in
            }
        }
    }
    
    func addLinkMode() {
        if linkManager.mode != "ADD_SIMUL_LINK" && linkManager.mode != "ADD_SEQ_LINK" {
            linkManager.mode = "ADD_SIMUL_LINK"
            for link in linkManager.allTrackLinks {
                link.mode = "ADD_SIMUL_LINK"
            }
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                // animate change background color to emphasize current mode
                self.drawView.layer.backgroundColor = UIColor.darkGrayColor().CGColor
                }) { (bool:Bool) -> Void in
            }
            seqLinkButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
            simulLinkButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        }
    }
    
    @IBAction func changeToSeqLinkMode(sender: UIButton) {
        print("changing to seq link mode")
        linkManager.mode = "ADD_SEQ_LINK"
        for link in linkManager.allTrackLinks {
            link.mode = "ADD_SEQ_LINK"
        }
        seqLinkButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
        simulLinkButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
    }
    
    @IBAction func changeToSimLinkMode(sender: UIButton) {
        print("changing to simul link mode")
        linkManager.mode = "ADD_SIMUL_LINK"
        for link in linkManager.allTrackLinks {
            link.mode = "ADD_SIMUL_LINK"
        }
        seqLinkButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
        simulLinkButton.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)
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
    
    @IBAction func undoDraw(sender: UIBarButtonItem) {
        print("UNDODRAW")
        drawView.undoDraw()
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
    
    func enterTrashMode() {
        if linkManager.mode != "TRASH" {
            linkManager.mode = "TRASH"
            for link in linkManager.allTrackLinks {
                link.mode = "TRASH"
            }
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                    self.drawView.layer.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.5).CGColor
                }) { (bool:Bool) -> Void in
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        let projectName = titleTextField.text
        (parentViewController as! ProjectManagerViewController).updateProjectName(projectID, projectName: projectName!)
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
        //for result in results {
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
                self.view.addSubview(linkToAdd)
            }
        }
    }

}

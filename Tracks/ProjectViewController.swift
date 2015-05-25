
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

class ProjectViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    var filemanager = NSFileManager.defaultManager()
    var projectDirectory: String!
    var createProjectFolder = true
    var projectID: String = ""
    var projectName: String = ""
    var projectEntity: ProjectEntity!
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var notesView: UITextView!
    var notesExpanded: Bool!
    var statusBarBackgroundView: UIView!
    var sideBarOpenBackgroundView: UIView!
    var drawView: DrawView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var navBarVertConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkManager: LinkManager!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var toolBarVertConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.drawView = DrawView(frame: self.view.frame)
        self.drawView.backgroundColor = UIColor.clearColor()
        self.drawView.layer.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0).CGColor
        self.view.addSubview(self.drawView)
        
        self.statusBarBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 20))
        self.statusBarBackgroundView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
        self.view.addSubview(self.statusBarBackgroundView)
        
        //Create notesView
        notesView = NotesTextView(frame: CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 0.0))
        notesExpanded = false
        
        //Check if project folder already exists
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let allProjects = filemanager.contentsOfDirectoryAtPath(docDirectory, error: nil)
        for project in allProjects! {
            if project as NSString == self.projectID {
                createProjectFolder = false
                break
            }
        }
        
        //Create new folder for project if needed. stores audio files in this location.
        if createProjectFolder {
            println("CREATING NEW PROJECT FOLDER")
            let newDirectory = docDirectory.stringByAppendingPathComponent(projectID)
            var error: NSError?
            if filemanager.createDirectoryAtPath(newDirectory, withIntermediateDirectories: true, attributes: nil, error: &error) {
                projectDirectory = newDirectory
            } else {
                println("could not make new project directory: \(error!.localizedDescription) ")
            }
        } else {
            println("LOADING OLD PROJECT")
            projectDirectory = docDirectory.stringByAppendingPathComponent(projectID)
        }
        
        //Assign context, and its core data project entity if it exists.
        self.appDel = UIApplication.sharedApplication().delegate as AppDelegate
        self.context = appDel.managedObjectContext!
        
        var request = NSFetchRequest(entityName: "ProjectEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectID = %@", argumentArray: [self.projectID])
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
      
        if results.count < 1 {
            self.projectEntity =  NSEntityDescription.insertNewObjectForEntityForName("ProjectEntity", inManagedObjectContext: self.context) as ProjectEntity
            self.projectEntity.projectID = self.projectID
            if self.drawView != nil {
                self.drawView.saveAllPaths(self.projectEntity)
            }
        } else {
            self.projectEntity = results[0] as ProjectEntity
            self.drawView.projectEntity = self.projectEntity
            self.drawView.loadAllPaths()
        }
        
        self.loadTracks()
        self.view.addSubview(notesView)
        
        self.view.bringSubviewToFront(self.statusBarBackgroundView)
        self.view.bringSubviewToFront(self.navigationBar)
        self.view.bringSubviewToFront(self.toolbar)
    }
    
    override func viewDidLayoutSubviews() {
        self.titleTextField.text = self.projectName
        self.titleTextField.textAlignment = NSTextAlignment.Center
        self.titleTextField.delegate = self
        self.toolbar.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        self.drawView.frame = self.view.frame
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addTrack(sender: UIBarButtonItem) {
        //Create new Track and set project directory where sound files will be stored.
        var newTrack = Track(frame: CGRect(x: self.view.center.x,y: self.view.center.y,width: 100.0,height: 100.0))
        newTrack.projectDirectory = self.projectDirectory
        
        //Center and add the new track node.
        newTrack.center = self.view.center
        newTrack.setLabelNameText("untitled")
        newTrack.saveTrackCoreData(self.projectEntity)
        self.view.addSubview(newTrack)
    }
        
    @IBAction func openSideBarVC(sender: UIBarButtonItem) {
        self.sideBarOpenBackgroundView = UIView(frame: self.view.frame)
        self.sideBarOpenBackgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.0)
        var tapGesture = UITapGestureRecognizer(target: self, action: "closeSideBarVC:")
        tapGesture.numberOfTapsRequired = 1
        self.sideBarOpenBackgroundView.addGestureRecognizer(tapGesture)
        self.drawView.sideBarOpenLock = true
        self.view.addSubview(self.sideBarOpenBackgroundView)
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.sideBarOpenBackgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.5)
            }, completion: { (bool:Bool) -> Void in
        })
        
        (self.parentViewController as ProjectManagerViewController).openSideBarVC()
    }
        
    func closeSideBarVC(gestureRecognizer:UIGestureRecognizer) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.sideBarOpenBackgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.0)
            }, completion: { (bool:Bool) -> Void in
                self.sideBarOpenBackgroundView.removeFromSuperview()
        })
        (self.parentViewController as ProjectManagerViewController).closeSideBarVC()
    
        self.drawView.sideBarOpenLock = false
    }
    
    func sideBarClosed() {
        if self.sideBarOpenBackgroundView != nil {
            self.sideBarOpenBackgroundView.removeFromSuperview()
        }
    }
    
    @IBAction func addLinkMode(sender: UIBarButtonItem) {
        if !self.linkManager.isInAddSimulLinkMode {
            self.linkManager.isInAddSimulLinkMode = true
            for link in self.linkManager.allSimulLink {
                link.isInAddLinkMode = true
            }
            UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.drawView.layer.backgroundColor = UIColor.darkGrayColor().CGColor
                self.navBarVertConstraint.constant -= self.navigationBar.frame.height + self.statusBarBackgroundView.frame.height
                self.toolBarVertConstraint.constant -= self.toolbar.frame.height
                self.view.layoutIfNeeded()
                }) { (bool:Bool) -> Void in
            }
        }
        var exitTrashModeButton = UIButton(frame: CGRect(x: 20, y: self.view.frame.height - 40, width: 20, height: 20))
        var image = UIImage(named: "close-button")
        exitTrashModeButton.setImage(image, forState: UIControlState.Normal)
        exitTrashModeButton.addTarget(self, action: "exitAddLinkMode:", forControlEvents: UIControlEvents.TouchUpInside)
        exitTrashModeButton.adjustsImageWhenHighlighted = true
        self.view.addSubview(exitTrashModeButton)
        self.view.exchangeSubviewAtIndex(self.view.subviews.count - 1, withSubviewAtIndex: self.view.subviews.count - 4)
    }
    
    func exitAddLinkMode(sender: UIButton) {
        if self.linkManager.isInAddSimulLinkMode {
            self.linkManager.isInAddSimulLinkMode = false
            for link in self.linkManager.allSimulLink {
                link.isInAddLinkMode = false
            }
            UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.drawView.layer.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0).CGColor
                self.navBarVertConstraint.constant += self.navigationBar.frame.height + self.statusBarBackgroundView.frame.height
                self.toolBarVertConstraint.constant += self.toolbar.frame.height
                self.view.layoutIfNeeded()
                }) { (bool:Bool) -> Void in
            }
            sender.removeFromSuperview()
        }
    }
    
    @IBAction func toggleNotes(sender: UIBarButtonItem) {
        self.view.bringSubviewToFront(notesView)
        self.view.exchangeSubviewAtIndex(self.view.subviews.count - 1, withSubviewAtIndex: self.view.subviews.count - 4)
        if notesExpanded! {
            var tmpFrame: CGRect = notesView.frame
            tmpFrame.size.height = 0
            tmpFrame.origin.y = self.view.frame.height
            UIView.beginAnimations("", context: nil)
            UIView.setAnimationDuration(0.2)
            notesView.frame = tmpFrame
            UIView.commitAnimations()
            notesExpanded = false
        } else {
            var tmpFrame: CGRect = notesView.frame
            tmpFrame.size.height = 460 - self.toolbar.frame.height
            tmpFrame.size.width = self.view.frame.width
            tmpFrame.origin.y = self.view.frame.height - 460
            UIView.beginAnimations("", context: nil)
            UIView.setAnimationDuration(0.2)
            notesView.frame = tmpFrame
            UIView.commitAnimations()
            notesExpanded = true
        }

    }
    
    @IBAction func undoDraw(sender: UIBarButtonItem) {
        println("UNDODRAW")
        self.drawView.undoDraw()
    }
    
    
    @IBAction func trashMode(sender: UIBarButtonItem) {
        if !self.linkManager.isInTrashMode {
            self.linkManager.isInTrashMode = true
            UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                    self.drawView.layer.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.5).CGColor
                    self.navBarVertConstraint.constant -= self.navigationBar.frame.height + self.statusBarBackgroundView.frame.height
                    self.toolBarVertConstraint.constant -= self.toolbar.frame.height
                    self.view.layoutIfNeeded()
                }) { (bool:Bool) -> Void in
            }
            var exitTrashModeButton = UIButton(frame: CGRect(x: self.view.frame.width - 40, y: self.view.frame.height - 40, width: 20, height: 20))
            var image = UIImage(named: "close-button")
            exitTrashModeButton.setImage(image, forState: UIControlState.Normal)
            exitTrashModeButton.addTarget(self, action: "exitTrashMode:", forControlEvents: UIControlEvents.TouchUpInside)
            exitTrashModeButton.adjustsImageWhenHighlighted = true
            self.view.addSubview(exitTrashModeButton)
            self.view.exchangeSubviewAtIndex(self.view.subviews.count - 1, withSubviewAtIndex: self.view.subviews.count - 4)
        }
    }
    
    func exitTrashMode(sender: UIButton) {
        if self.linkManager.isInTrashMode {
            self.linkManager.isInTrashMode = false
            UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.drawView.layer.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0).CGColor
                self.navBarVertConstraint.constant += self.navigationBar.frame.height + self.statusBarBackgroundView.frame.height
                self.toolBarVertConstraint.constant += self.toolbar.frame.height
                self.view.layoutIfNeeded()
                }) { (bool:Bool) -> Void in
            }
            sender.removeFromSuperview()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.titleTextField.resignFirstResponder()
        var projectName = self.titleTextField.text
        (self.parentViewController as ProjectManagerViewController).updateProjectName(self.projectID, projectName: projectName)
        return true
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer {
            return true
        } else {
            return false
        }
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    func loadTracks() {
        var request = NSFetchRequest(entityName: "ProjectEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectID = %@", argumentArray: [self.projectID])
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        //for result in results {
        if (results.count > 0) {
            var res = results[0] as ProjectEntity
            for track in res.track {
                var trackEntity = track as TrackEntity
                var trackToAdd = NSKeyedUnarchiver.unarchiveObjectWithData(trackEntity.track) as Track
                self.view.addSubview(trackToAdd)
            }
        }
    }
}

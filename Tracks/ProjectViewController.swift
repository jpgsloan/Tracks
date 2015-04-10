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

class ProjectViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var labelCounter = 0
    var filemanager = NSFileManager.defaultManager()
    var projectDirectory: String!
    var createProjectFolder = true
    var projectID: String = ""
    var projectEntity: ProjectEntity!
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    var notesView: UITextView!
    var notesExpanded: Bool!
    
    var exitEditModeButton: UIButton!
    var trackInEditMode: Track!
    var trackToEditInProgress: Bool = false
    
    @IBOutlet weak var drawView: DrawView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.interactivePopGestureRecognizer.delegate = self
        
        self.view.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0)
        
        //Create notesView
        notesView = NotesTextView(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 0.0))
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
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func wasDragged(button: UIButton, event:UIEvent) {
        var touch: UITouch = event.touchesForView(button)?.anyObject() as UITouch
        
        var previousLoc: CGPoint = touch.previousLocationInView(button)
        var loc: CGPoint = touch.locationInView(button)
        var delta_x: CGFloat = loc.x - previousLoc.x;
        var delta_y: CGFloat = loc.y - previousLoc.y;
        
        button.center = CGPointMake(button.center.x + delta_x,
            button.center.y + delta_y);
    }
    
    @IBAction func addTrack(sender: UIBarButtonItem) {
        //Create new Track and set project directory where sound files will be stored.
        var newTrack = Track(frame: CGRect(x: self.view.center.x,y: self.view.center.y,width: 100.0,height: 100.0))
        newTrack.projectDirectory = self.projectDirectory
        newTrack.projectViewController = self
        
        //Center and add the new track node.
        newTrack.center = self.view.center
        newTrack.setLabelNameText("untitled " + labelCounter.description)
        labelCounter++
        newTrack.saveTrackCoreData(self.projectEntity)
        
        //Add long press gesture for selecting track edit mode
        var longPressEdit = UILongPressGestureRecognizer(target: self, action: "changeTrackToEditMode:")
        longPressEdit.numberOfTapsRequired = 0
        newTrack.addGestureRecognizer(longPressEdit)
        
        self.view.addSubview(newTrack)
    }
    
    func changeTrackToEditMode(gestureRecognizer:UIGestureRecognizer) {
        if !trackToEditInProgress {
            trackToEditInProgress = true
            println("CHANGING TO EDIT ")
            self.navigationController?.setToolbarHidden(true, animated: true)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            var track = gestureRecognizer.view as Track
            self.trackInEditMode = track
            exitEditModeButton = UIButton(frame: CGRect(x: self.view.bounds.origin.x + self.view.bounds.width / 16.5, y: self.view.bounds.origin.y + self.view.bounds.height / 30.0 + (self.view.bounds.height / 9.0 * 0.25), width: 20, height: 20))
            
            var image = UIImage(named: "close-button")
            exitEditModeButton.setImage(image, forState: UIControlState.Normal)
            exitEditModeButton.addTarget(self, action: "exitTrackFromEditMode:", forControlEvents: UIControlEvents.TouchUpInside)
            exitEditModeButton.adjustsImageWhenHighlighted = true;
            exitEditModeButton.bounds.size.height = 20.0
            exitEditModeButton.bounds.size.width = 20.0

            track.addSubview(exitEditModeButton)
            track.editMode()
        }
    }
    
    func exitTrackFromEditMode(sender: UIButton) {
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.trackInEditMode.exitEditMode()
        sender.removeFromSuperview()
        trackToEditInProgress = false
    }
    
    @IBAction func undoDraw(sender: UIBarButtonItem) {
        drawView.undoDraw()
    }
    
    @IBAction func toggleNotes(sender: UIBarButtonItem) {
        self.view.bringSubviewToFront(notesView)
        if notesExpanded! {
            var tmpFrame: CGRect = notesView.frame
            tmpFrame.size.height = 0
            tmpFrame.origin.y = self.view.bounds.height
            UIView.beginAnimations("", context: nil)
            UIView.setAnimationDuration(0.2)
            notesView.frame = tmpFrame
            UIView.commitAnimations()
            notesExpanded = false
        } else {
            var tmpFrame: CGRect = notesView.frame
            tmpFrame.size.height = 400
            tmpFrame.origin.y = self.view.bounds.height - 400
            UIView.beginAnimations("", context: nil)
            UIView.setAnimationDuration(0.2)
            notesView.frame = tmpFrame
            UIView.commitAnimations()
            notesExpanded = true
        }

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
                trackToAdd.projectViewController = self
                //Add long press gesture for selecting track edit mode
                var longPressEdit = UILongPressGestureRecognizer(target: self, action: "changeTrackToEditMode:")
                longPressEdit.numberOfTapsRequired = 0
                trackToAdd.addGestureRecognizer(longPressEdit)
                self.view.addSubview(trackToAdd)
            }
        }
    }
    
    func deleteTrack(track: Track) {
        
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer {
            return true
        } else {
            return false
        }
    }
    
}

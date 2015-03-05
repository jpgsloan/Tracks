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

class ProjectViewController: UIViewController {
    
    var labelCounter = 0
    var filemanager = NSFileManager.defaultManager()
    var projectDirectory: String!
    var createProjectFolder = true
    var projectID: String!
    var projectEntity: ProjectEntity!
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    //@IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var drawView: DrawView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0)
        
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
            self.drawView.saveAllPaths(self.projectEntity)
        } else {
            self.projectEntity = results[0] as ProjectEntity
            self.drawView.projectEntity = self.projectEntity
            self.drawView.loadAllPaths()
        }
        
        self.loadTracks()
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
    
    @IBAction func addTrack(sender: UIButton) {
        //Create new Track and set project directory where sound files will be stored.
        var newTrack = Track(frame: CGRect(x: self.view.center.x,y: self.view.center.y,width: 100.0,height: 100.0))
        newTrack.projectDirectory = self.projectDirectory
        
        //Center and add the new track node.
        newTrack.center = self.view.center
        newTrack.setLabelNameText("untitled " + labelCounter.description)
        labelCounter++
        newTrack.saveTrackCoreData(self.projectEntity)
        self.view.addSubview(newTrack)
    }

    @IBAction func undoDraw(sender: UIButton) {
        println("UNDOING")
        drawView.undoDraw()
        
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

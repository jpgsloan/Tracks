//
//  ProjectManagerViewController.swift
//  Tracks
//
//  Created by John Sloan on 4/10/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import CoreData

class ProjectManagerViewController: UIViewController {

    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    var projVC: ProjectViewController!
    var sideBarVC: SelectProjectTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDel = UIApplication.sharedApplication().delegate as AppDelegate
        self.context = appDel.managedObjectContext!
        
        sideBarVC = SelectProjectTableViewController(nibName: "SelectProjectViewController",bundle: nil)
        var frame = self.view.frame
        frame.origin.x = self.view.frame.origin.x - self.view.frame.width
        frame.size.width = self.view.frame.width - (self.view.frame.width / 4.5)
        sideBarVC.view.frame = frame
        self.addChildViewController(sideBarVC)
        self.view.addSubview(sideBarVC.view)
        sideBarVC.didMoveToParentViewController(self)
        
        var project = self.requestLastOpenProject()
        var projectID = ""
        var projectName = ""
        if (project.count < 1) {
            projectID = self.createNewProject()
            projectName = "Untitled Project"
            sideBarVC.addProject(projectID,projectName: projectName)
        } else {
            projectID = project.valueForKey("ProjectID") as String
            projectName = project.valueForKey("ProjectName") as String
        }
        
        projVC = ProjectViewController(nibName: "ProjectViewController",bundle: nil)
        projVC.projectID = projectID
        projVC.projectName = projectName
        projVC.view.frame = self.view.frame
        self.addChildViewController(projVC)
        self.view.addSubview(projVC.view)
        self.view.sendSubviewToBack(projVC.view)
        projVC.didMoveToParentViewController(self)
        self.updateLastOpenProjectCoreData(projectID,projectName: projectName)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openSideBarVC() {
        println("OPEN SIDEBAR")
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.sideBarVC.view.frame.origin.x = self.view.frame.origin.x
            }, completion: { (bool:Bool) -> Void in
        })  
        
    }
    
    func closeSideBarVC() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.sideBarVC.view.frame.origin.x = self.view.frame.origin.x - self.view.frame.width
            }, completion: { (bool:Bool) -> Void in
                self.projVC.sideBarClosed()
        })
    }
    
    func openProject(projectID: String, projectName: String) {
        println("opening project")
        closeSideBarVC()
        var newProjVC = ProjectViewController(nibName: "ProjectViewController",bundle: nil)
        newProjVC.projectID = projectID
        newProjVC.projectName = projectName
        
        newProjVC.view.frame = self.view.frame
        self.addChildViewController(newProjVC)
        self.view.addSubview(newProjVC.view)
        newProjVC.didMoveToParentViewController(self)
        self.updateLastOpenProjectCoreData(projectID,projectName: projectName)
        
        self.projVC.view.removeFromSuperview()
        self.projVC.removeFromParentViewController()
        self.projVC = newProjVC
        self.view.sendSubviewToBack(self.projVC.view)
    }

    func updateProjectName(projectID: String, projectName: String) {
        self.sideBarVC.updateProjectName(projectID,projectName: projectName)
        self.updateLastOpenProjectCoreData(projectID, projectName: projectName)
    }
    
    func createNewProject() -> String {
        var todaysDate:NSDate = NSDate()
        var dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMddyy-HHmmss-SSS"
        var dateInFormat = dateFormatter.stringFromDate(todaysDate)
        
        var lastOpenProjectEntity = NSEntityDescription.insertNewObjectForEntityForName("LastOpenProjectEntity", inManagedObjectContext: context) as LastOpenProjectEntity
        
        lastOpenProjectEntity.projectID = dateInFormat
        lastOpenProjectEntity.projectName = "Untitled Project"
        self.context.save(nil)
        return dateInFormat
    }
    
    func requestLastOpenProject() -> NSMutableDictionary {
        var request = NSFetchRequest(entityName: "LastOpenProjectEntity")
        request.returnsObjectsAsFaults = false
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if (results.count >= 1) {
            var res = results[0] as LastOpenProjectEntity
            var projectInfo = NSMutableDictionary()
            projectInfo.setValue(res.projectID, forKey: "ProjectID")
            projectInfo.setValue(res.projectName, forKey: "ProjectName")
            return projectInfo
        } else {
            return NSMutableDictionary()
        }
    }
    
    func updateLastOpenProjectCoreData(projectID: String, projectName: String) {
        var request = NSFetchRequest(entityName: "LastOpenProjectEntity")
        request.returnsObjectsAsFaults = false
        
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        print("HERE: ")
        println(results.count)
        if (results.count == 1) {
            var res = results[0] as LastOpenProjectEntity
            res.projectID = projectID
            res.projectName = projectName
        }
        self.context.save(nil)
    }
    
}
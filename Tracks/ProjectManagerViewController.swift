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
        self.appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        self.context = appDel.managedObjectContext!
        
        sideBarVC = SelectProjectTableViewController(nibName: "SelectProjectViewController",bundle: nil)
        var frame = self.view.frame
        frame.origin.x = self.view.frame.origin.x - self.view.frame.width
        frame.size.width = self.view.frame.width - (self.view.frame.width / 3.3)
        sideBarVC.view.frame = frame
        self.addChildViewController(sideBarVC)
        self.view.addSubview(sideBarVC.view)
        sideBarVC.didMoveToParentViewController(self)
        
        let project = self.requestLastOpenProject()
        var projectID = ""
        var projectName = ""
        if (project.count < 1) {
            projectID = self.createNewProject()
            projectName = "Untitled Project"
            sideBarVC.addProject(projectID,projectName: projectName)
        } else {
            projectID = project.valueForKey("ProjectID") as! String
            projectName = project.valueForKey("ProjectName") as! String
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
        print("OPEN SIDEBAR")
        // add bottom border to settings button
        let lowerBorder = CALayer()
        lowerBorder.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
        lowerBorder.frame = CGRectMake(15, sideBarVC.settingsButton.frame.height - 0.5, sideBarVC.settingsButton.frame.width - 15, 0.5)
        sideBarVC.settingsButton.layer.addSublayer(lowerBorder)

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
    
    func openNewProject() {
        print("opening new project")
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMddyy-HHmmss-SSS"
        let projectID = dateFormatter.stringFromDate(todaysDate)
        let projectName = "Untitled Project"
        sideBarVC.addProject(projectID, projectName: projectName)
        openProject(projectID, projectName: projectName)
    }
    
    func openProject(projectID: String, projectName: String) {
        print("opening project")
        projVC.stopAudio(UIButton())
        let newProjVC = ProjectViewController(nibName: "ProjectViewController",bundle: nil)
        newProjVC.projectID = projectID
        newProjVC.projectName = projectName
        
        newProjVC.view.frame = self.view.frame
        
        self.updateLastOpenProjectCoreData(projectID,projectName: projectName)
        self.projVC.view.removeFromSuperview()
        self.projVC.removeFromParentViewController()
        self.projVC = newProjVC
        
        self.addChildViewController(self.projVC)
        self.view.addSubview(self.projVC.view)
        self.projVC.didMoveToParentViewController(self)
        self.view.sendSubviewToBack(self.projVC.view)
        
        // inform new project view controller that sidebar is currently open, then close it (for animation purposes).
        self.projVC.sideBarOpened()
        self.projVC.closeSideBarVC(UIGestureRecognizer())
    }
    
    func openProjectInBackground(projectID: String, projectName: String) {
        print("opening project in background")
        let newProjVC = ProjectViewController(nibName: "ProjectViewController",bundle: nil)
        newProjVC.projectID = projectID
        newProjVC.projectName = projectName
        
        newProjVC.view.frame = self.view.frame
        
        self.updateLastOpenProjectCoreData(projectID,projectName: projectName)
        self.projVC.view.removeFromSuperview()
        self.projVC.removeFromParentViewController()
        self.projVC = newProjVC
        
        self.addChildViewController(self.projVC)
        self.view.addSubview(self.projVC.view)
        self.projVC.didMoveToParentViewController(self)
        self.view.sendSubviewToBack(self.projVC.view)
        
        self.projVC.sideBarOpened()
    }

    func updateProjectName(projectID: String, projectName: String) {
        self.sideBarVC.updateProjectName(projectID,projectName: projectName)
        self.updateLastOpenProjectCoreData(projectID, projectName: projectName)
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func createNewProject() -> String {
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMddyy-HHmmss-SSS"
        let dateInFormat = dateFormatter.stringFromDate(todaysDate)
        
        let lastOpenProjectEntity = NSEntityDescription.insertNewObjectForEntityForName("LastOpenProjectEntity", inManagedObjectContext: context) as! LastOpenProjectEntity
        
        lastOpenProjectEntity.projectID = dateInFormat
        lastOpenProjectEntity.projectName = "Untitled Project"
        do {
            try self.context.save()
        } catch _ {
        }
        return dateInFormat
    }
    
    func requestLastOpenProject() -> NSMutableDictionary {
        let request = NSFetchRequest(entityName: "LastOpenProjectEntity")
        request.returnsObjectsAsFaults = false
        let results: NSArray = try! context.executeFetchRequest(request)
        if (results.count >= 1) {
            let res = results[0] as! LastOpenProjectEntity
            let projectInfo = NSMutableDictionary()
            projectInfo.setValue(res.projectID, forKey: "ProjectID")
            projectInfo.setValue(res.projectName, forKey: "ProjectName")
            return projectInfo
        } else {
            return NSMutableDictionary()
        }
    }
    
    func updateLastOpenProjectCoreData(projectID: String, projectName: String) {
        let request = NSFetchRequest(entityName: "LastOpenProjectEntity")
        request.returnsObjectsAsFaults = false
        
        let results: NSArray = try! context.executeFetchRequest(request)
        print("HERE: ", terminator: "")
        print(results.count)
        if (results.count == 1) {
            let res = results[0] as! LastOpenProjectEntity
            res.projectID = projectID
            res.projectName = projectName
        } else {
            print("MANY LAST OPEN PROJECT ENTITIES")
        }
        do {
            try self.context.save()
        } catch _ {
        }
    }
    
    func deleteProjectFromCoreData(projectID: String) {
        // deleting project from core data
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        if let context = appDel.managedObjectContext {
            let request = NSFetchRequest(entityName: "ProjectEntity")
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "projectID = %@", argumentArray: [projectID])
            let results: NSArray = try! context.executeFetchRequest(request)
            if results.count == 1 {
                let projectToDelete = results[0] as! ProjectEntity
                context.deleteObject(projectToDelete)
                do {
                    try context.save()
                } catch _ {
                }
            }
        }
    }

    
}

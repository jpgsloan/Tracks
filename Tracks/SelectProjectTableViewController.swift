//
//  SelectProjectTableViewController.swift
//  
//
//  Created by John Sloan on 2/27/15.
//
//

import UIKit
import CoreData

class SelectProjectTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableData: Array<NSMutableDictionary> = []
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    var indexPathToDelete: NSIndexPath?
        
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var generalBar: UIView!
    @IBOutlet weak var projectsBar: UIView!
    @IBOutlet weak var settingsButton: UIView!
    @IBOutlet weak var aboutButton: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("initializing table view")
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        // make views slightly transparent
        self.view.backgroundColor = view.backgroundColor!.colorWithAlphaComponent(0.9)
        projectsBar.backgroundColor = projectsBar.backgroundColor?.colorWithAlphaComponent(0.9)
        generalBar.backgroundColor = generalBar.backgroundColor?.colorWithAlphaComponent(0.9)
        
        
        tableView.registerNib(UINib(nibName: "ProjectTableViewCell", bundle: nil), forCellReuseIdentifier: "selectProjectCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 75
        tableView.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 0.0).colorWithAlphaComponent(0.0)
        
        //Checkif stored tableData exists in CoreData
        let request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        let results: NSArray = try! context.executeFetchRequest(request)
        
        if results.count == 1 {
            print("loading previous table data")
            loadTableData()
        } else if results.count > 1 {
            print("MEGAPROBLEM: More than 1 tableData objects")
        } else {
            //Save tableData to CoreData for first time
            let tableDataAsNSData: NSData = NSKeyedArchiver.archivedDataWithRootObject(tableData)
            let tableViewDataEntity = NSEntityDescription.insertNewObjectForEntityForName("TableViewDataEntity", inManagedObjectContext: context) as! TableViewDataEntity
            tableViewDataEntity.tableData = tableDataAsNSData
            do {
                try context.save()
            } catch _ {
            }
        }
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let data = self.tableData[indexPath.row]
        let projectID = data.valueForKey("projectID") as! String
        let projectName = data.valueForKey("projectName") as! String
        (self.parentViewController as! ProjectManagerViewController).openProject(projectID, projectName: projectName)
        didSelectRow(indexPath)
    }
    
    func didSelectRow(indexPath: NSIndexPath) {
        print("row selected")
        // set cell as selected.
        for (var i = 0; i < tableData.count; i++) {
            tableData[i].setValue(false, forKey: "selected")
        }
        tableData[indexPath.row].setValue(true, forKey: "selected")
        self.tableView.reloadData()
        self.updateTableData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return tableData.count
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ProjectTableViewCell = tableView.dequeueReusableCellWithIdentifier("selectProjectCell") as! ProjectTableViewCell
        
        let data: NSMutableDictionary = self.tableData[indexPath.row] as NSMutableDictionary

        cell.projectName.text = (data.valueForKey("projectName") as! String)
        cell.projectName.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
        
        cell.projectDate.text = (data.valueForKey("projectDate") as! String)
        var bgColorView = UIView()
        bgColorView.backgroundColor = self.view.backgroundColor
        cell.selectedBackgroundView = bgColorView
        
        if let bool = data.valueForKey("selected") {
            if bool is Bool && (bool as! Bool) {
                cell.selectionImage.image = UIImage(named: "selected-project")
                print("selected image set")
            } else {
                cell.selectionImage.image = UIImage(named: "unselected-project")
            }
        } else {
            cell.selectionImage.image = UIImage(named: "unselected-project")
        }
        
        return cell
    }

    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            if let projectName = self.tableData[indexPath.row].valueForKey("projectName") {
                indexPathToDelete = indexPath
                confirmDelete(projectName as! String)
            }
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    func confirmDelete(projectName: String) {
        
        let alert = UIAlertController(title: "Delete Project", message: "Are you sure you want to permanently delete \(projectName)?", preferredStyle: .ActionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDeleteProject)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: cancelDeleteProject)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func handleDeleteProject(alertAction: UIAlertAction!) {
        if let indexPathToDelete = indexPathToDelete {
            let selectedBool = self.tableData[indexPathToDelete.row].valueForKey("selected")
            let projectID = self.tableData[indexPathToDelete.row].valueForKey("projectID") as! String
            self.tableData.removeAtIndex(indexPathToDelete.row)
            tableView.deleteRowsAtIndexPaths([indexPathToDelete], withRowAnimation: .Fade)
            
            // delete project files
            let filemgr = NSFileManager.defaultManager()
            let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                .UserDomainMask, true)
            let docsDir = dirPaths[0] as! String
            let projDir = NSString(string: docsDir).stringByAppendingPathComponent(projectID)
            
            var error: NSError?
            
            do {
                try filemgr.removeItemAtPath(projDir)
            } catch {
                print("Failed to delete directory: \(projDir)")
            }
            
            if self.tableData.count == 0 {
                if let parent = self.parentViewController as? ProjectManagerViewController {
                        // since all project were deleted, create empty new project and open it. 
                        parent.openNewProject()
                }
    
            } else if selectedBool is Bool {
                if selectedBool as! Bool {
                    // since there are other projects, and current selected one was deleted, open next project in table (or previous).
                    if indexPathToDelete.row < self.tableData.count {
                        // open next project in background.
                        let data = self.tableData[indexPathToDelete.row]
                        let projectID = data.valueForKey("projectID") as! String
                        let projectName = data.valueForKey("projectName") as! String
                        (self.parentViewController as! ProjectManagerViewController).openProjectInBackground(projectID, projectName: projectName)
                        
                        // select next project in tableview.
                        self.didSelectRow(indexPathToDelete)
                    } else if indexPathToDelete.row - 1 < self.tableData.count {
                        let newIndex = NSIndexPath(forRow: indexPathToDelete.row - 1, inSection: indexPathToDelete.section)
                        // open previous project in background.
                        let data = self.tableData[newIndex.row]
                        let projectID = data.valueForKey("projectID") as! String
                        let projectName = data.valueForKey("projectName") as! String
                        (self.parentViewController as! ProjectManagerViewController).openProjectInBackground(projectID, projectName: projectName)
                        
                        // select previous project in tableview.

                        self.didSelectRow(newIndex)
                    }
                }
            } else {
                self.updateTableData()
            }
        }
        indexPathToDelete = nil
    }
    
    func cancelDeleteProject(alertAction: UIAlertAction!) {
        indexPathToDelete = nil
    }
    
    @IBAction func addProject(sender: UIButton) {
        print("adding new project")
        let data = NSMutableDictionary()
        data.setValue("Untitled Project", forKey: "projectName")
        
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM.dd.yy"
        var dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectDate")
        
        dateFormatter.dateFormat = "MMddyy-HHmmss-SSS"
        dateInFormat = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectID")
        
        if self.tableData.count == 0 {
            // if only project, mark as selected.
            data.setValue(true, forKey: "selected")
        } else {
            data.setValue(false, forKey: "selected")
        }
        self.tableData.insert(data, atIndex: 0)
        //self.tableData.append(data)
        self.tableView.reloadData()
        self.updateTableData()
    }

    func addProject(projectID: String, projectName:String) {
        print("adding new project from ID and name")
        let data = NSMutableDictionary()
        
        data.setValue(projectName, forKey: "projectName")
        data.setValue(projectID, forKey: "projectID")
        
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM.dd.yy"
        let dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectDate")
        
        if self.tableData.count == 0 {
            // if only project, mark as selected.
            data.setValue(true, forKey: "selected")
        } else {
            data.setValue(false, forKey: "selected")
        }
        
        self.tableData.append(data)
        self.tableView.reloadData()
        self.updateTableData()
    }
    
    func updateProjectName(projectID: String, projectName: String) {
        for dataEntry in self.tableData {
            if (dataEntry.valueForKey("projectID") as! String) == projectID {
                dataEntry.setValue(projectName, forKey: "projectName")
                break
            }
        }
        self.tableView.reloadData()
        self.updateTableData()
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
    
    func loadTableData() {
        let request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        let results: NSArray = try! context.executeFetchRequest(request)
        let tableViewDataEntity = results[0] as! TableViewDataEntity
        let tableDataAsNSData = tableViewDataEntity.tableData as NSData
        self.tableData = NSKeyedUnarchiver.unarchiveObjectWithData(tableDataAsNSData) as! Array<NSMutableDictionary>
        self.tableView.reloadData()
    }
    
    func updateTableData() {
        /*for (var i = 0; i < self.tableData.count; i++) {
            if let cell: ProjectTableViewCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! ProjectTableViewCell {
                self.tableData[i].setValue(cell.projectName.text, forKey: "projectName")
            }
        }*/
    
        let request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let tableViewDataEntity = results[0] as! TableViewDataEntity
            let newTableDataAsNSData = NSKeyedArchiver.archivedDataWithRootObject(self.tableData)
            tableViewDataEntity.tableData = newTableDataAsNSData
            do {
                try self.context.save()
            } catch _ {
            }
        } else {
            print("Problem with updating tableData")
        }
    }
}

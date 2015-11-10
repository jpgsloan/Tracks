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
        
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("initializing table view")
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        self.view.backgroundColor = UIColor.clearColor().colorWithAlphaComponent(0.0)
        
        tableView.registerNib(UINib(nibName: "ProjectTableViewCell", bundle: nil), forCellReuseIdentifier: "selectProjectCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = 55
        tableView.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 0.0)
        
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
        print("row selected")
        let data = self.tableData[indexPath.row]
        let projectID = data.valueForKey("projectID") as! String
        let projectName = data.valueForKey("projectName") as! String
        (self.parentViewController as! ProjectManagerViewController).openProject(projectID, projectName: projectName)
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
        
        cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.3)

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
            self.tableData.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self.updateTableData()
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    @IBAction func addProject(sender: UIButton) {
        print("adding new project")
        let data = NSMutableDictionary()
        data.setValue("Untitled Project", forKey: "projectName")
        
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        var dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectDate")
        
        dateFormatter.dateFormat = "MMddyy-HHmmss-SSS"
        dateInFormat = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectID")
        
        self.tableData.append(data)
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
        dateFormatter.dateFormat = "MM/dd/yy"
        let dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectDate")
        
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
        for (var i = 0; i < self.tableData.count; i++) {
            let cell: ProjectTableViewCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! ProjectTableViewCell
                
            self.tableData[i].setValue(cell.projectName.text, forKey: "projectName")
            print("inforloop:", terminator: "")
            print(i)
        }
    
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

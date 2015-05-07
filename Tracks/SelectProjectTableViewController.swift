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
        println("initializing table view")
        self.appDel = UIApplication.sharedApplication().delegate as AppDelegate
        self.context = appDel.managedObjectContext!
        
        self.tableView.registerNib(UINib(nibName: "ProjectTableViewCell", bundle: nil), forCellReuseIdentifier: "selectProjectCell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.rowHeight = 55
        self.tableView.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0)
        
        //Checkif stored tableData exists in CoreData
        var request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        
        if results.count == 1 {
            println("loading previous table data")
            self.loadTableData()
        } else if results.count > 1 {
            println("MEGAPROBLEM: More than 1 tableData objects")
        } else {
            //Save tableData to CoreData for first time
            var tableDataAsNSData: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.tableData)
            var tableViewDataEntity = NSEntityDescription.insertNewObjectForEntityForName("TableViewDataEntity", inManagedObjectContext: self.context) as TableViewDataEntity
            tableViewDataEntity.tableData = tableDataAsNSData
            self.context.save(nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("row selected")
        var data = self.tableData[indexPath.row]
        var projectID = data.valueForKey("projectID") as String
        var projectName = data.valueForKey("projectName") as String
        (self.parentViewController as ProjectManagerViewController).openProject(projectID, projectName: projectName)
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
        let cell: ProjectTableViewCell = tableView.dequeueReusableCellWithIdentifier("selectProjectCell") as ProjectTableViewCell
        
        var data: NSMutableDictionary = self.tableData[indexPath.row] as NSMutableDictionary

        cell.projectName.text = (data.valueForKey("projectName") as String)
        cell.projectName.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
        
        cell.projectDate.text = (data.valueForKey("projectDate") as String)
        
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
        println("adding new project")
        var data = NSMutableDictionary()
        data.setValue("Untitled Project", forKey: "projectName")
        
        var todaysDate:NSDate = NSDate()
        var dateFormatter:NSDateFormatter = NSDateFormatter()
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
        println("adding new project from ID and name")
        var data = NSMutableDictionary()
        
        data.setValue(projectName, forKey: "projectName")
        data.setValue(projectID, forKey: "projectID")
        
        var todaysDate:NSDate = NSDate()
        var dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        var dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        data.setValue(dateInFormat, forKey: "projectDate")
        
        self.tableData.append(data)
        self.tableView.reloadData()
        self.updateTableData()
    }
    
    func updateProjectName(projectID: String, projectName: String) {
        for dataEntry in self.tableData {
            if (dataEntry.valueForKey("projectID") as String) == projectID {
                dataEntry.setValue(projectName, forKey: "projectName")
                break
            }
        }
        self.tableView.reloadData()
        self.updateTableData()
    }
   
    /*override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "passInfo" {
            var secondViewController : ProjectViewController = segue.destinationViewController as ProjectViewController
            var indexPath: NSIndexPath = self.tableView.indexPathForSelectedRow()!
            secondViewController.projectID = self.tableData[indexPath.row].valueForKey("projectID") as String
            var projectTitle = self.tableData[indexPath.row].valueForKey("projectName") as? String
            secondViewController.title = projectTitle
            
        }
    }*/
    
    func loadTableData() {
        var request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        var tableViewDataEntity = results[0] as TableViewDataEntity
        var tableDataAsNSData = tableViewDataEntity.tableData as NSData
        self.tableData = NSKeyedUnarchiver.unarchiveObjectWithData(tableDataAsNSData) as Array<NSMutableDictionary>
        self.tableView.reloadData()
    }
    
    func updateTableData() {
        for (var i = 0; i < self.tableData.count; i++) {
            var cell: ProjectTableViewCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as ProjectTableViewCell
                
            self.tableData[i].setValue(cell.projectName.text, forKey: "projectName")
            print("inforloop:")
            println(i)
        }
    
        var request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var tableViewDataEntity = results[0] as TableViewDataEntity
            var newTableDataAsNSData = NSKeyedArchiver.archivedDataWithRootObject(self.tableData)
            tableViewDataEntity.tableData = newTableDataAsNSData
            self.context.save(nil)
        } else {
            println("Problem with updating tableData")
        }
    }
}

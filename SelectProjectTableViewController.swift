//
//  SelectProjectTableViewController.swift
//  
//
//  Created by John Sloan on 2/27/15.
//
//

import UIKit
import CoreData

class SelectProjectTableViewController: UITableViewController {

    var tableData: Array<AnyObject> = []
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDel = UIApplication.sharedApplication().delegate as AppDelegate
        self.context = appDel.managedObjectContext!
        
        self.tableView.rowHeight = 55
        self.tableView.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0)
        
        //Checkif stored tableData exists in CoreData
        var request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        
        if results.count == 1 {
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

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return tableData.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ProjectCellTableViewCell = tableView.dequeueReusableCellWithIdentifier("projectCell", forIndexPath: indexPath) as ProjectCellTableViewCell
        
        var data: NSMutableDictionary = tableData[indexPath.row] as NSMutableDictionary
        
        cell.projectName.text = data.valueForKey("projectName") as String
        cell.projectName.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.0)
        
        cell.projectDate.text = (data.valueForKey("projectDate") as String)
        
        cell.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)

        return cell
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            self.tableData.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    @IBAction func addProject(sender: UIBarButtonItem) {
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

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "passInfo" {
            var secondViewController : ProjectViewController = segue.destinationViewController as ProjectViewController
            var indexPath: NSIndexPath = self.tableView.indexPathForSelectedRow()!
            secondViewController.projectID = self.tableData[indexPath.row].valueForKey("projectID") as String
        }
    }
    
    func loadTableData() {
        var request = NSFetchRequest(entityName: "TableViewDataEntity")
        request.returnsObjectsAsFaults = false
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        var tableViewDataEntity = results[0] as TableViewDataEntity
        var tableDataAsNSData = tableViewDataEntity.tableData as NSData
        self.tableData = NSKeyedUnarchiver.unarchiveObjectWithData(tableDataAsNSData) as Array<AnyObject>
        self.tableView.reloadData()
    }
    
    func updateTableData() {
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

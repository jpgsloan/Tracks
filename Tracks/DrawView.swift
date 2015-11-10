//
//  DrawView.swift
//  Tracks
//
//  Created by John Sloan on 2/10/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import CoreData

class DrawView: UIView {

    var allPaths: [[Line]] = []
    var curPath: [Line] = []
    var lastPoint: CGPoint!
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var projectEntity: ProjectEntity!
    
    override init (frame: CGRect){
        super.init(frame: frame)
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    func touchBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        lastPoint = touches.first!.locationInView(self)
    }
    
    func touchMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let newPoint = touches.first!.locationInView(self)
        curPath.append(Line(start: lastPoint, end: newPoint))
        lastPoint = newPoint
        self.setNeedsDisplay()
    }
    
    func touchEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (!curPath.isEmpty) {
            self.allPaths.append(curPath)
            self.updateAllPaths()
        }
        curPath = []
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        for path in allPaths {
            for line in path {
                CGContextMoveToPoint(context, line.start.x, line.start.y)
                CGContextAddLineToPoint(context, line.end.x, line.end.y)
            }
        }
        for line in curPath {
            CGContextMoveToPoint(context, line.start.x, line.start.y)
            CGContextAddLineToPoint(context, line.end.x, line.end.y)
        }
        CGContextSetRGBStrokeColor(context, 0.341, 0.341, 0.341, 1)
        CGContextSetLineWidth(context, 5)
        CGContextStrokePath(context)
    }
    
    func undoDraw() {
        if !allPaths.isEmpty {
            allPaths.removeLast()
            self.updateAllPaths()
            self.setNeedsDisplay()
        }
    }
    
    func updateAllPaths() {
        let request = NSFetchRequest(entityName: "DrawViewEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectEntity = %@", argumentArray: [self.projectEntity])
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let drawViewEntity = results[0] as! DrawViewEntity
            let allPathsAsNSData = NSKeyedArchiver.archivedDataWithRootObject(self.allPaths)
            drawViewEntity.allLines = allPathsAsNSData
            do {
                try self.context.save()
            } catch _ {
            }
        } else {
            print("Problem with updating drawView data")
        }

    }
    
    func loadAllPaths() {
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        let request = NSFetchRequest(entityName: "DrawViewEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectEntity = %@", argumentArray: [self.projectEntity])
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let drawViewEntity = results[0] as! DrawViewEntity
            let allPathsAsNSData = drawViewEntity.allLines as NSData
            self.allPaths = NSKeyedUnarchiver.unarchiveObjectWithData(allPathsAsNSData) as! [[Line]]
            self.setNeedsDisplay()
        }
    }
    
    func saveAllPaths(projectEntity: ProjectEntity) {
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        self.projectEntity = projectEntity
        let drawViewEntity = NSEntityDescription.insertNewObjectForEntityForName("DrawViewEntity", inManagedObjectContext: self.context) as! DrawViewEntity
        let allPathsAsNSData = NSKeyedArchiver.archivedDataWithRootObject(self.allPaths)
        drawViewEntity.projectEntity = projectEntity
        drawViewEntity.allLines = allPathsAsNSData
        do {
            try self.context.save()
        } catch _ {
        }
    }
}

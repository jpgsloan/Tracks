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
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        lastPoint = touches.anyObject()?.locationInView(self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        var newPoint = touches.anyObject()?.locationInView(self)
        curPath.append(Line(start: lastPoint, end: newPoint!))
        lastPoint = newPoint
        
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if (!curPath.isEmpty) {
            self.allPaths.append(curPath)
            self.updateAllPaths()
        }
        curPath = []
    }

    override func drawRect(rect: CGRect) {
        var context = UIGraphicsGetCurrentContext()
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
        allPaths.removeLast()
        self.setNeedsDisplay()
    }
    
    func updateAllPaths() {
        var request = NSFetchRequest(entityName: "DrawViewEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectEntity = %@", argumentArray: [self.projectEntity])
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var drawViewEntity = results[0] as DrawViewEntity
            var allPathsAsNSData = NSKeyedArchiver.archivedDataWithRootObject(self.allPaths)
            drawViewEntity.allLines = allPathsAsNSData
            self.context.save(nil)
        } else {
            println("Problem with updating drawView data")
        }

    }
    
    func loadAllPaths() {
        appDel = UIApplication.sharedApplication().delegate as AppDelegate
        context = appDel.managedObjectContext!
        var request = NSFetchRequest(entityName: "DrawViewEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "projectEntity = %@", argumentArray: [self.projectEntity])
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var drawViewEntity = results[0] as DrawViewEntity
            var allPathsAsNSData = drawViewEntity.allLines as NSData
            self.allPaths = NSKeyedUnarchiver.unarchiveObjectWithData(allPathsAsNSData) as [[Line]]
            self.setNeedsDisplay()
        }
    }
    
    func saveAllPaths(projectEntity: ProjectEntity) {
        appDel = UIApplication.sharedApplication().delegate as AppDelegate
        context = appDel.managedObjectContext!
        self.projectEntity = projectEntity
        var drawViewEntity = NSEntityDescription.insertNewObjectForEntityForName("DrawViewEntity", inManagedObjectContext: self.context) as DrawViewEntity
        var allPathsAsNSData = NSKeyedArchiver.archivedDataWithRootObject(self.allPaths)
        drawViewEntity.projectEntity = projectEntity
        drawViewEntity.allLines = allPathsAsNSData
        self.context.save(nil)
    }
}

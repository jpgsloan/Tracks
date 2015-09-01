//
//  ProjectEntity.swift
//  
//
//  Created by John Sloan on 8/12/15.
//
//

import Foundation
import CoreData

@objc (ProjectEntity)
class ProjectEntity: NSManagedObject {

    @NSManaged var projectID: String
    @NSManaged var drawView: DrawViewEntity
    @NSManaged var track: NSSet
    @NSManaged var link: NSSet

}

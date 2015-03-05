//
//  ProjectEntity.swift
//  Tracks
//
//  Created by John Sloan on 3/3/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import Foundation
import CoreData

@objc (ProjectEntity)
class ProjectEntity: NSManagedObject {

    @NSManaged var projectID: String
    @NSManaged var track: NSSet

}

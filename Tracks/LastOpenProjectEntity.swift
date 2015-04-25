//
//  LastOpenProjectEntity.swift
//  Tracks
//
//  Created by John Sloan on 4/20/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import Foundation
import CoreData

@objc (LastOpenProjectEntity)
class LastOpenProjectEntity: NSManagedObject {

    @NSManaged var projectID: String
    @NSManaged var projectName: String

}

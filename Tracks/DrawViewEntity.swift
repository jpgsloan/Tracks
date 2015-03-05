//
//  DrawViewEntity.swift
//  Tracks
//
//  Created by John Sloan on 3/5/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import Foundation
import CoreData

@objc (DrawViewEntity)
class DrawViewEntity: NSManagedObject {

    @NSManaged var allLines: NSData
    @NSManaged var projectEntity: ProjectEntity

}

//
//  TrackEntity.swift
//  Tracks
//
//  Created by John Sloan on 3/3/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import Foundation
import CoreData

@objc (TrackEntity)
class TrackEntity: NSManagedObject {

    @NSManaged var track: NSData
    @NSManaged var trackID: String
    @NSManaged var project: ProjectEntity

}

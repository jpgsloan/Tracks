//
//  SimulLinkEntity.swift
//  
//
//  Created by John Sloan on 7/23/15.
//
//

import Foundation
import CoreData

@objc (SimulLinkEntity)
class SimulLinkEntity: NSManagedObject {

    @NSManaged var simulLinkID: String
    @NSManaged var tracks: NSData
    @NSManaged var edges: NSData
    @NSManaged var project: ProjectEntity

}

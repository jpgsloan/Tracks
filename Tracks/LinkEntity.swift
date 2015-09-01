//
//  LinkEntity.swift
//  
//
//  Created by John Sloan on 8/12/15.
//
//

import Foundation
import CoreData

@objc (LinkEntity)
class LinkEntity: NSManagedObject {

    @NSManaged var linkNodes: NSData
    @NSManaged var linkID: String
    @NSManaged var rootTrackID: String
    @NSManaged var project: ProjectEntity

}

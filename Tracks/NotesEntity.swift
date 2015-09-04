//
//  NotesEntity.swift
//  
//
//  Created by John Sloan on 9/3/15.
//
//

import Foundation
import CoreData

@objc (NotesEntity)
class NotesEntity: NSManagedObject {

    @NSManaged var text: String
    @NSManaged var project: ProjectEntity

}

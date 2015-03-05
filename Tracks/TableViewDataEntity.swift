//
//  TableViewDataEntity.swift
//  Tracks
//
//  Created by John Sloan on 3/4/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import Foundation
import CoreData

@objc (TableViewDataEntity)
class TableViewDataEntity: NSManagedObject {

    @NSManaged var tableData: NSData

}

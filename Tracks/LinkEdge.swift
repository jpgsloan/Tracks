//
//  LinkEdge.swift
//  Tracks
//
//  Created by John Sloan on 5/8/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class LinkEdge: NSObject {
   
    var startTrackNode: Track!
    var endTrackNode: Track!
    
    init (startTrackNode: Track, endTrackNode: Track) {
        self.startTrackNode = startTrackNode
        self.endTrackNode = endTrackNode
    }
}

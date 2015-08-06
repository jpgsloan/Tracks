//
//  SeqTrackNode.swift
//  Tracks
//
//  Created by John Sloan on 8/5/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class SeqTrackNode: NSObject {
   
    var rootTrackID: String
    var childrenIDs: [String] = [String]()
    
    init (track: Track) {
        rootTrackID = track.trackID
    }
    
    func addChild(track: Track) {
        childrenIDs.append(track.trackID)
    }
}

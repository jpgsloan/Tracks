//
//  TrackLinkNode.swift
//  Tracks
//
//  Created by John Sloan on 8/6/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class TrackLinkNode: NSObject {
   
    var rootTrackID: String
    var childrenIDs: [String] = [String]()
    var siblingIDs: [String] = [String]()
    
    init (track: Track) {
        rootTrackID = track.trackID
    }
    
    init(coder aDecoder: NSCoder) {
        rootTrackID = aDecoder.decodeObjectForKey("rootTrackID") as! String
        childrenIDs = aDecoder.decodeObjectForKey("children") as! [String]
        siblingIDs = aDecoder.decodeObjectForKey("siblings") as! [String]
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(rootTrackID, forKey: "rootTrackID")
        aCoder.encodeObject(childrenIDs, forKey: "children")
        aCoder.encodeObject(siblingIDs, forKey: "siblings")
    }
    
    func addChild(track: Track) {
        childrenIDs.append(track.trackID)
    }

    func addSibling(track: Track) {
        siblingIDs.append(track.trackID)
    }
    
}

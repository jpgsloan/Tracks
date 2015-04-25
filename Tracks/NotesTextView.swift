//
//  NotesTextView.swift
//  Tracks
//
//  Created by John Sloan on 3/15/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore

class NotesTextView: UITextView {

    override init(frame: CGRect) {
        super.init(frame: frame)
    
        var imageLayer: CALayer = self.layer
        imageLayer.cornerRadius = 10
        imageLayer.borderWidth = 1
        imageLayer.borderColor = UIColor.lightGrayColor().CGColor
        
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    
}

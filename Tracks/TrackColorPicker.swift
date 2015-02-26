//
//  TrackColorPicker.swift
//  Tracks
//
//  Created by John Sloan on 2/21/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

var teal:UIColor = UIColor(red: 0.169, green: 0.643, blue: 0.675, alpha: 1)
var orange:UIColor = UIColor(red: 0.961, green: 0.682, blue: 0.318, alpha: 1)
var pink:UIColor = UIColor(red: 0.851, green: 0.341, blue: 0.408, alpha: 1)

var allColors: [UIColor] = [teal,orange,pink]
var colorCounter = 0

func pickColor() -> UIColor {
    
    var colorIndex = colorCounter % allColors.count
    colorCounter++
    return allColors[colorIndex]
    
}
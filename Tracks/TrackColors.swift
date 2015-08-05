//
//  TrackColors.swift
//  Tracks
//
//  Created by John Sloan on 2/21/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

var teal:UIColor = UIColor(red: 0.169, green: 0.643, blue: 0.675, alpha: 1).colorWithAlphaComponent(0.9)
var orange:UIColor = UIColor(red: 0.961, green: 0.682, blue: 0.318, alpha: 1).colorWithAlphaComponent(0.9)
var pink:UIColor = UIColor(red: 0.851, green: 0.341, blue: 0.408, alpha: 1).colorWithAlphaComponent(0.9)
var green:UIColor = UIColor(red: 0.482, green: 0.780, blue: 0.592, alpha: 1).colorWithAlphaComponent(0.9)
var purple:UIColor = UIColor(red: 0.678, green: 0.561, blue: 0.769, alpha: 1).colorWithAlphaComponent(0.9)

var allColors: [UIColor] = [teal,orange,pink,green,purple]

func colors() -> [UIColor] {
    return allColors
}

func tealColor() -> UIColor {
    return teal
}
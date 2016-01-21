//
//  LineRuledTextView.swift
//  Tracks
//
//  Created by John Sloan on 1/21/16.
//  Copyright © 2016 JPGS inc. All rights reserved.
//

import UIKit

class LineRuledTextView: UITextView {

   /* override func drawRect(rect: CGRect) {
        
        //Get the current drawing context
        let context = UIGraphicsGetCurrentContext()
        //Set the line color and width
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().colorWithAlphaComponent(0.7).CGColor)
        CGContextSetLineWidth(context, 1.0)
        //Start a new Path
        CGContextBeginPath(context)
        
        //Find the number of lines in our textView + add a bit more height to draw lines in the empty part of the view
        let numberOfLines = Int(floor((self.contentSize.height) / self.font!.lineHeight))
        
        //Set the line offset from the baseline. (I'm sure there's a concrete way to calculate this.)
        let baselineOffset = CGFloat(6.0)
        
        //iterate over numberOfLines and draw each line
        for var x = 0; x < numberOfLines; x++ {
            //0.5f offset lines up line with pixel boundary
            CGContextMoveToPoint(context, self.bounds.origin.x, self.font!.lineHeight * CGFloat(x) + 0.5 + baselineOffset)
            CGContextAddLineToPoint(context, self.bounds.size.width, self.font!.lineHeight * CGFloat(x) + 0.5 + baselineOffset)
        }
        
        //Close our Path and Stroke (draw) it
        CGContextClosePath(context)
        CGContextStrokePath(context)
    }
*/
}

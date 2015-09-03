//
//  NotesView.swift
//  Tracks
//
//  Created by John Sloan on 9/3/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class NotesView: UIView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var notesTextView: UITextView!
    // custom view from the XIB file
    var view: UIView!
    
    override init (frame: CGRect){
        super.init(frame: frame)
        xibSetup()
        
        var imageLayer: CALayer = self.layer
        imageLayer.cornerRadius = 10
        imageLayer.borderWidth = 2
        imageLayer.borderColor = UIColor.lightGrayColor().CGColor
      
        blurView.layer.cornerRadius = 10
        blurView.clipsToBounds = true
        
        var tapGesture = UITapGestureRecognizer(target: self, action: "exitNotes:")
        tapGesture.numberOfTapsRequired = 1
        backgroundView.addGestureRecognizer(tapGesture)
        
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        view.frame = self.bounds
        
        // Make the view stretch with containing view
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "NotesView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    func openNotes(frame: CGRect) {
        
        (self.superview as! LinkManager).mode = "NOTOUCHES"
        (self.superview as! LinkManager).hideToolbars(true)
        
        // animate backgroundView color and notesTextView/blurView frames
        backgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.0)
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.backgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.5)
            self.notesTextView.frame = frame
            self.blurView.frame = frame
            }, completion: { (bool:Bool) -> Void in
        })
        
        //animate notes text view frame
        UIView.beginAnimations("", context: nil)
        UIView.setAnimationDuration(0.2)
        
        UIView.commitAnimations()
    }
    
    func exitNotes(gestureRecognizer:UIGestureRecognizer) {
        (self.superview as! LinkManager).mode = ""
        (self.superview as! LinkManager).hideToolbars(false)
        
        // animate removal of background view and notes view
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.backgroundView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.0)
            var tmpFrame: CGRect = self.frame
            tmpFrame.size.height = 0
            tmpFrame.origin.y = self.frame.height
            self.notesTextView.frame = tmpFrame
            self.blurView.frame = tmpFrame
            }, completion: { (bool:Bool) -> Void in
                self.removeFromSuperview()
        })
    }
    
    @IBAction func doneTyping(sender: UIButton) {
        
        notesTextView.resignFirstResponder()
    }
}

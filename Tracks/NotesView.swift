//
//  NotesView.swift
//  Tracks
//
//  Created by John Sloan on 9/3/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import CoreData

class NotesView: UIView, UITextViewDelegate {
    
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var projectEntity: ProjectEntity!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var notesTextView: UITextView!
    // custom view from the XIB file
    var view: UIView!
    
    @IBOutlet weak var notesTextViewBottomContstraint: NSLayoutConstraint!
    
    
    override init (frame: CGRect){
        super.init(frame: frame)
        xibSetup()
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        notesTextView.delegate = self
        
        var imageLayer: CALayer = blurView.layer
        imageLayer.cornerRadius = 10
        imageLayer.borderWidth = 2
        imageLayer.borderColor = UIColor.darkGrayColor().CGColor
        blurView.clipsToBounds = true
        
        var tapGesture = UITapGestureRecognizer(target: self, action: "exitNotes:")
        tapGesture.numberOfTapsRequired = 1
        backgroundView.addGestureRecognizer(tapGesture)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        self.addSubview(view)
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
    
    func keyboardWillShow(notification: NSNotification) {
        var info = notification.userInfo!
        var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.notesTextViewBottomContstraint.constant = keyboardFrame.size.height - 50
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.notesTextViewBottomContstraint.constant = 0
        })
    }
    
    func textViewDidChange(textView: UITextView) {
        updateNotes()
    }
    
    func updateNotes() {
        println("UPDATING NOTES")
        var request = NSFetchRequest(entityName: "NotesEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "project = %@", argumentArray: [projectEntity])
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var notesEntity = results[0] as! NotesEntity
            notesEntity.text = notesTextView.text
            self.context.save(nil)
        } else {
            println("Problem with updating drawView data")
        }
    }
    
    func loadNotes() {
        var request = NSFetchRequest(entityName: "NotesEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "project = %@", argumentArray: [projectEntity])
        var results: NSArray = context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var notesEntity = results[0] as! NotesEntity
            notesTextView.text = notesEntity.text
            self.setNeedsDisplay()
        }
    }
    
    func saveNotes(projectEntity: ProjectEntity) {
        self.projectEntity = projectEntity
        var notesEntity = NSEntityDescription.insertNewObjectForEntityForName("NotesEntity", inManagedObjectContext: context) as! NotesEntity
        notesEntity.project = projectEntity
        notesEntity.text = notesTextView.text
        self.context.save(nil)
    }
}

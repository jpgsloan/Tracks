//
//  NotesView.swift
//  Tracks
//
//  Created by John Sloan on 9/3/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore

class NotesView: UIView, UITextViewDelegate {
    
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var projectEntity: ProjectEntity!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var notesTextView: UITextView!
    
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var notesTextViewBottomContstraint: NSLayoutConstraint!
    @IBOutlet weak var dateEditedLabel: UILabel!
    @IBOutlet weak var topBarBackgroundView: UIView!
    
    // custom view from the XIB file
    var view: UIView!
    
    override init (frame: CGRect){
        super.init(frame: frame)
        xibSetup()
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        notesTextView.delegate = self
        
        // add bottom border, very faint
        let topBarBorder = CALayer()
        topBarBorder.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.02).CGColor
        topBarBorder.frame = CGRectMake(0, topBarBackgroundView.frame.height - 0.5, topBarBackgroundView.frame.width, 0.5)
        topBarBackgroundView.layer.addSublayer(topBarBorder)
        
        // add shadow to top bar
        topBarBackgroundView.layer.masksToBounds = false
        topBarBackgroundView.layer.shadowOffset = CGSizeMake(0, 2)
        topBarBackgroundView.layer.shadowRadius = 5
        topBarBackgroundView.layer.shadowOpacity = 0.3
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "NotesView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    func openNotes(frame: CGRect) {
       
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        (self.superview as! LinkManager).mode = "NOTOUCHES"
        (self.superview as! LinkManager).hideToolbars(true)
        
        // animate notesTextView/blurView frames
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.view.frame = frame
            }, completion: { (bool:Bool) -> Void in
        })
        
        //animate notes text view frame
        UIView.beginAnimations("", context: nil)
        UIView.setAnimationDuration(0.2)
        
        UIView.commitAnimations()
    }
    
    @IBAction func exitNotes(sender: AnyObject) {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        (self.superview as! LinkManager).mode = ""
        (self.superview as! LinkManager).hideToolbars(false)
        
        // animate removal notes view
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            var tmpFrame: CGRect = self.view.frame
            tmpFrame.origin.y = self.frame.height
            self.view.frame = tmpFrame
            }, completion: { (bool:Bool) -> Void in
                self.removeFromSuperview()
        })

    }
    
    @IBAction func doneTyping(sender: UIButton) {
        notesTextView.resignFirstResponder()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.notesTextViewBottomContstraint.constant = keyboardFrame.size.height
        })
        
        doneButton.hidden = false
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.notesTextViewBottomContstraint.constant = 0
        })
        doneButton.hidden = true
    }
    
    func textViewDidChange(textView: UITextView) {
        // set last edited date to now.
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d, yyyy, h:mm a"
        let currentDate = NSDate()
        dateEditedLabel.text = formatter.stringFromDate(currentDate)
        
        updateNotes()
    }
    
    func updateNotes() {
        print("UPDATING NOTES")
        let request = NSFetchRequest(entityName: "NotesEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "project = %@", argumentArray: [projectEntity])
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let notesEntity = results[0] as! NotesEntity
            notesEntity.text = dateEditedLabel.text! + ":~~//~~:" + notesTextView.text
            do {
                try self.context.save()
            } catch _ {
            }
        } else {
            print("Problem with updating drawView data")
        }
    }
    
    func loadNotes() {
        let request = NSFetchRequest(entityName: "NotesEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "project = %@", argumentArray: [projectEntity])
        let results: NSArray = try! context.executeFetchRequest(request)
        if results.count == 1 {
            let notesEntity = results[0] as! NotesEntity
            
            // split saved text into date label text and notes text
            let splitText = notesEntity.text.componentsSeparatedByString(":~~//~~:")
            if splitText.count < 2 {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "MMMM d, yyyy, h:mm a"
                let currentDate = NSDate()
                dateEditedLabel.text = formatter.stringFromDate(currentDate)
                notesTextView.text = splitText[0]
            } else if splitText.count > 2 {
                dateEditedLabel.text = splitText[0]
                var notes = ""
                for var i = 1; i < splitText.count; i++ {
                    if i > 1 {
                        notes += ":~~//~~:"
                    }
                    notes += splitText[i]
                }
                notesTextView.text = notes
            } else {
                dateEditedLabel.text = splitText[0]
                notesTextView.text = splitText[1]
            }
            self.setNeedsDisplay()
        }
    }
    
    func saveNotes(projectEntity: ProjectEntity) {
        // set last edited date
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM d, yyyy, h:mm a"
        let currentDate = NSDate()
        dateEditedLabel.text = formatter.stringFromDate(currentDate)
        
        self.projectEntity = projectEntity
        let notesEntity = NSEntityDescription.insertNewObjectForEntityForName("NotesEntity", inManagedObjectContext: context) as! NotesEntity
        notesEntity.project = projectEntity
        notesEntity.text = dateEditedLabel.text! + ":~~//~~:" + notesTextView.text
        do {
            try self.context.save()
        } catch _ {
        }
    }
}

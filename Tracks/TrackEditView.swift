//
//  TrackEditView.swift
//  Tracks
//
//  Created by John Sloan on 9/11/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class TrackEditView: UIView {
    // contains code for all edit elements.
    var view: UIView!
    var track: Track!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var waveformEditView: WaveformEditView!
    
    convenience init(frame: CGRect, track: Track) {
        self.init(frame: frame)
        self.track = track
        self.backgroundColor = track.backgroundColor?.colorWithAlphaComponent(0.97)
        self.view.backgroundColor = UIColor.clearColor()
        titleTextField.text = track.labelName.text
        waveformEditView.layoutIfNeeded()
        waveformEditView.setAudio(track.recordedAudio.filePathUrl)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
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
        let nib = UINib(nibName: "TrackEditView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    func animateOpen() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            var newFrame = self.superview!.frame
            self.frame = newFrame
            self.layoutIfNeeded()
            self.waveformEditView.setAudio(self.track.recordedAudio.filePathUrl)
        }, completion: { (bool:Bool) -> Void in
        })
    }
    
    func animateClose() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            var newFrame = self.track.frame
            self.frame = newFrame
            self.backgroundColor = self.track.backgroundColor?.colorWithAlphaComponent(0.0)
        }, completion: { (bool:Bool) -> Void in
            self.removeFromSuperview()
        })

    }
    
    func setAudio() {
        waveformEditView.setAudio(track.recordedAudio.filePathUrl)
    }

    @IBAction func exitEditMode(sender: UIButton) {
        //TODO: animate close, update track with any new info if not done already
        (self.superview as! LinkManager).hideToolbars(false)
        animateClose()
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        track.isInEditMode = false
        (self.superview as! LinkManager).mode = ""
    }
}

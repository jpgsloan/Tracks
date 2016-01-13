//
//  TrackEditView.swift
//  Tracks
//
//  Created by John Sloan on 9/11/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class TrackEditView: UIView, UITextFieldDelegate {
    // contains code for all edit elements.
    var view: UIView!
    var track: Track!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var waveformEditView: WaveformEditView!
    @IBOutlet weak var volSlider: UISlider!
    @IBOutlet weak var panSlider: UISlider!
   
    convenience init(frame: CGRect, track: Track) {
        self.init(frame: frame)
        self.track = track
        self.view.backgroundColor = track.view.backgroundColor?.colorWithAlphaComponent(0.97)
        self.backgroundColor = UIColor.clearColor()
        
        // set title text and delegate
        titleTextField.text = track.labelName.text
        titleTextField.delegate = self
        
        // init waveform view with audio
        waveformEditView.layoutIfNeeded()
        waveformEditView.setTrackRef(track)
        if let url = track.recordedAudio.filePathUrl {
            waveformEditView.setAudio(url)
        }
        // set volume
        volSlider.value = track.volume
        waveformEditView.adjustVolume(track.volume)
        
        // set pan
        let mappedPanValue = (track.pan + 1.0) / 2.0
        panSlider.value = mappedPanValue
        waveformEditView.adjustPan(track.pan)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
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
        let nib = UINib(nibName: "TrackEditView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    func animateOpen() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let newFrame = self.superview!.frame
            self.frame = newFrame
            self.layoutIfNeeded()
            if let url = self.track.recordedAudio.filePathUrl {
                self.waveformEditView.setAudio(url)
            }
        }, completion: { (bool:Bool) -> Void in
        })
    }
    
    func animateClose() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let newFrame = self.track.frame
            self.frame = newFrame
            self.backgroundColor = self.track.backgroundColor?.colorWithAlphaComponent(0.0)
        }, completion: { (bool:Bool) -> Void in
            self.removeFromSuperview()
        })

    }
    
    func setAudio() {
        if let url = track.recordedAudio.filePathUrl {
            waveformEditView.setAudio(url)
        }
    }
    
    @IBAction func adjustAudio(sender: UISlider) {
        waveformEditView.adjustVolume(sender.value)
    }
    
    @IBAction func adjustPan(sender: UISlider) {
        let mappedValue = -1 + (sender.value * 2)
        waveformEditView.adjustPan(mappedValue)
    }
    
    @IBAction func changeColor(sender: UIButton) {
        self.view.backgroundColor = sender.backgroundColor?.colorWithAlphaComponent(0.97)
    }
    
    @IBAction func exitEditMode(sender: UIButton) {
        // animates closing of edit view, updates edited info to track
        (self.superview as! LinkManager).hideToolbars(false)
        track.exitEditMode(volSlider.value, pan: -1 + (panSlider.value * 2), color: self.view.backgroundColor!.colorWithAlphaComponent(0.85), titleText: titleTextField.text!)
        animateClose()
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        track.isInEditMode = false
        (self.superview as! LinkManager).mode = ""
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        return true
    }
    
}

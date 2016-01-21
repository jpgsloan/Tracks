//
//  TrackEditView.swift
//  Tracks
//
//  Created by John Sloan on 9/11/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore

class TrackEditView: UIView, UITextFieldDelegate {
    // contains code for all edit elements.
    var view: UIView!
    var track: Track!
    var trackLink: TrackLink?
    var oldAudioPlayer: AVAudioPlayer?
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var waveformEditView: WaveformEditView!
    @IBOutlet weak var volSlider: UISlider!
    @IBOutlet weak var panSlider: UISlider!
    @IBOutlet weak var topBarBackGroundView: UIView!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var navyButton: UIButton!
    @IBOutlet weak var redButton: UIButton!
    
    convenience init(frame: CGRect, track: Track) {
        self.init(frame: frame)
        self.track = track
        self.view.backgroundColor = track.view.backgroundColor?.colorWithAlphaComponent(0.97)
        self.backgroundColor = UIColor.clearColor()
        
        // store old audioPlayer, incase new one is created from trimming. (used to access old track node in track links)
        oldAudioPlayer = track.audioPlayer
        
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
        
        // add shadow to top bar
        topBarBackGroundView.layer.masksToBounds = false
        topBarBackGroundView.layer.shadowOffset = CGSizeMake(0, 2)
        topBarBackGroundView.layer.shadowRadius = 5
        topBarBackGroundView.layer.shadowOpacity = 0.3
        
        // add outlines to buttons
        greenButton.layer.borderColor = UIColor.whiteColor().CGColor
        greenButton.layer.borderWidth = 1
        blueButton.layer.borderColor = UIColor.whiteColor().CGColor
        blueButton.layer.borderWidth = 1
        navyButton.layer.borderColor = UIColor.whiteColor().CGColor
        navyButton.layer.borderWidth = 1
        redButton.layer.borderColor = UIColor.whiteColor().CGColor
        redButton.layer.borderWidth = 1
        
        if let backgroundColor = track.view.backgroundColor?.colorWithAlphaComponent(1.0) {
            switch backgroundColor {
            case greenButton.backgroundColor!:
                greenButton.layer.borderWidth = 2
            case blueButton.backgroundColor!:
                blueButton.layer.borderWidth = 2
            case navyButton.backgroundColor!:
                navyButton.layer.borderWidth = 2
            case redButton.backgroundColor!:
                redButton.layer.borderWidth = 2
            default:
                greenButton.layer.borderWidth = 1
                blueButton.layer.borderWidth = 1
                navyButton.layer.borderWidth = 1
                redButton.layer.borderWidth = 1
            }
        }
        
        setColors(track.view.backgroundColor)
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
    
    func setColors(baseColor: UIColor?) {
        if let backgroundColor = baseColor {
            print("IN HERE NOI")
            let color = CoreImage.CIColor(color: backgroundColor)
            print(color)
            topBarBackGroundView.backgroundColor = UIColor(red: max(color.red - (20 / 255.0), 0), green: max(color.green - (20 / 255.0), 0), blue: max(color.blue - (20 / 255.0), 0), alpha: 1.0)
            self.view.backgroundColor = UIColor(red: min(color.red + (20 / 255.0), 255), green: min(color.green + (20 / 255.0), 255), blue: min(color.blue + (20 / 255.0), 255), alpha: 0.97)
            
            waveformEditView.backgroundView.backgroundColor = backgroundColor.colorWithAlphaComponent(1.0)
            
            waveformEditView.audioPlot.backgroundColor = backgroundColor.colorWithAlphaComponent(1.0)

            
        }
    }
    
    func animateOpen() {
        self.view.backgroundColor = self.track.backgroundColor?.colorWithAlphaComponent(0.0)
        waveformEditView.view.backgroundColor = UIColor.clearColor()
        topBarBackGroundView.backgroundColor = UIColor.clearColor()
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let newFrame = self.superview!.frame
            self.frame = newFrame
            self.layoutIfNeeded()
            if let url = self.track.recordedAudio.filePathUrl {
                self.waveformEditView.setAudio(url)
            }
            self.setColors(self.track.view.backgroundColor)
        }, completion: { (bool:Bool) -> Void in
        })
        
        // change color buttons to circles
        greenButton.layer.cornerRadius = greenButton.bounds.width / 2.0
        blueButton.layer.cornerRadius = blueButton.bounds.width / 2.0
        navyButton.layer.cornerRadius = navyButton.bounds.width / 2.0
        redButton.layer.cornerRadius = redButton.bounds.width / 2.0
    }
    
    func animateClose() {
        for subview in self.view.subviews {
            if subview != self.view {
                print("REMOVING SUBVIEW")
                subview.removeFromSuperview()
            }
        }
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let newFrame = self.track.frame
            self.frame = newFrame
            self.view.layer.cornerRadius = 12
            self.view.backgroundColor = self.track.view.backgroundColor?.colorWithAlphaComponent(0.0)
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
        setColors(sender.backgroundColor)
        greenButton.layer.borderWidth = 1
        blueButton.layer.borderWidth = 1
        navyButton.layer.borderWidth = 1
        redButton.layer.borderWidth = 1
        sender.layer.borderWidth = 2
    }
    
    @IBAction func exitEditMode(sender: UIButton) {
        // animates closing of edit view, updates edited info to track
        //(self.superview as! LinkManager).hideToolbars(false)
        track.exitEditMode(volSlider.value, pan: -1 + (panSlider.value * 2), color: waveformEditView.backgroundView.backgroundColor!.colorWithAlphaComponent(0.85), titleText: titleTextField.text!)
        animateClose()
        track.isInEditMode = false
        if let trackLink = trackLink, player = oldAudioPlayer {
            if waveformEditView.wasTrimmed {
                trackLink.updateTrackWithNewAudioPlayer(player, track: track)
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        titleTextField.resignFirstResponder()
        return true
    }
    
}

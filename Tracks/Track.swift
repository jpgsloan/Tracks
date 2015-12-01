//
//  Track.swift
//  Tracks
//
//  Created by John Sloan on 2/4/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class Track: UIView, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITextFieldDelegate {

    var recordedAudio: RecordedAudio = RecordedAudio()
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    var wasDragged = false
    var startLoc: CGPoint!
    var hasStartedRecording = false
    var hasStoppedRecording = false
    var readyToPlay = false
    var labelName: UILabel!
    var labelDate: UILabel!
    var labelDuration: UILabel!
    var textFieldName: UITextField!
    var progressView: UIView!
    var isInEditMode: Bool = false
    var savedBoundsDuringEdit: CGRect!
    var exitEditModeButton: UIButton!
    var recordButton: UIView!
    var audioPlot: EZAudioPlot!
    var audioFile: EZAudioFile!
    var projectDirectory: String!
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    var longPressLock: Bool = false
    var trackID: String = ""

    required convenience init?(coder aDecoder: NSCoder) {
        let bounds = aDecoder.decodeCGRectForKey("bounds")
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let projectName = aDecoder.decodeObjectForKey("projectName") as! String
        let projectDirectory = NSString(string: docDirectory).stringByAppendingPathComponent(projectName)
        let trackName = aDecoder.decodeObjectForKey("trackName") as! String
        if trackName == "" {
            self.init(frame:bounds)
        } else {
            let audioFileUrl = NSString(string: projectDirectory).stringByAppendingPathComponent(trackName)
            self.init(frame: bounds)
            
            recordButton.removeFromSuperview()
            
            recordedAudio.filePathUrl = NSURL(fileURLWithPath: audioFileUrl)
            recordedAudio.title = recordedAudio.filePathUrl.lastPathComponent
            hasStartedRecording = true
            hasStoppedRecording = true
        
            audioPlayer = try? AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl)
            audioPlayer.prepareToPlay()
            
            audioFile = EZAudioFile(URL: recordedAudio.filePathUrl)
        
            drawWaveform()
        
            readyToPlay = true
    
            labelDate.text = aDecoder.decodeObjectForKey("labelDate") as! String
            labelDuration.text = aDecoder.decodeObjectForKey("labelDuration") as! String
        }
        
        self.backgroundColor = (aDecoder.decodeObjectForKey("color") as! UIColor)
        
        labelName.text = aDecoder.decodeObjectForKey("labelName") as! String?
        self.projectDirectory = projectDirectory
        self.center = aDecoder.decodeCGPointForKey("center")
        trackID = aDecoder.decodeObjectForKey("trackID") as! String
        //self.isInEditMode = aDecoder.decodeBoolForKey("isInEditMode")

        self.addSubview(audioPlot)
        self.addSubview(labelName)
        self.addSubview(labelDate)
        self.addSubview(labelDuration)
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeCGRect(self.bounds, forKey: "bounds")
        if recordedAudio.title == nil {
            aCoder.encodeObject("", forKey: "trackName")
        } else {
            aCoder.encodeObject(recordedAudio.title, forKey: "trackName")
        }
        aCoder.encodeObject(NSString(string: projectDirectory).lastPathComponent, forKey: "projectName")
        aCoder.encodeObject(labelName.text, forKey: "labelName")
        aCoder.encodeObject(labelDate.text, forKey: "labelDate")
        aCoder.encodeObject(labelDuration.text, forKey: "labelDuration")
        aCoder.encodeCGPoint(self.center, forKey: "center")
        aCoder.encodeObject(self.backgroundColor, forKey: "color")
        aCoder.encodeObject(trackID, forKey: "trackID")
        //aCoder.encodeBool(self.isInEditMode, forKey: "isInEditMode")
        //if (self.savedBoundsDuringEdit != nil) {
          //  aCoder.encodeCGRect(self.savedBoundsDuringEdit, forKey: "savedBoundsDuringEdit")
        //}
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        if self.backgroundColor == nil {
            print("picking color")
            self.backgroundColor = tealColor()
        }
        
        //set progressView 
        progressView = UIView(frame: CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 1, height: self.bounds.height))
        progressView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        progressView.layer.cornerRadius = 2
        
        //Set the track id
        if trackID.isEmpty {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
            trackID = formatter.stringFromDate(currentDateTime)
        }
        
        //Frequently reused bounds values
        let originX = self.bounds.origin.x
        let originY = self.bounds.origin.y
        let trackHeight = self.bounds.height
        let trackWidth = self.bounds.width
        
        //using EZAudio for now
        audioPlot = EZAudioPlot(frame: CGRect(x: originX, y: originY + trackHeight/4.2, width: trackWidth, height: trackHeight - trackHeight/4.2 - (trackHeight * 1.4 / 7.0)))
        audioPlot.plotType = EZPlotType.Buffer
        audioPlot.backgroundColor = UIColor.clearColor()
        audioPlot.opaque = false
        audioPlot.color = UIColor.whiteColor()
        audioPlot.shouldFill   = false
        audioPlot.shouldMirror = true
        
        //Add label for file name
        labelName = UILabel(frame: CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2))
        labelName.textAlignment = NSTextAlignment.Center
        labelName.textColor = UIColor.whiteColor()
        labelName.userInteractionEnabled = true
        
        //Add label for date
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        let dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        labelDate = UILabel(frame: CGRect(x: originX + (trackWidth / 12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth, height: trackHeight * 1.4 / 7.0))
        labelDate.textAlignment = NSTextAlignment.Left
        labelDate.textColor = UIColor.whiteColor()
        labelDate.text = dateInFormat
        labelDate.font = UIFont(name: labelDate.font.fontName, size: 10)
        
        
        //Add label for duration (0:00:00 until audio is recorded)
        labelDuration = UILabel(frame: CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth - (trackWidth * 2.0 / 12.0) , height: trackHeight * 1.4 / 7.0))
        labelDuration.textAlignment = NSTextAlignment.Right
        labelDuration.textColor = UIColor.whiteColor()
        labelDuration.text = "0:00:00"
        labelDuration.font = UIFont(name: labelDuration.font.fontName, size: 10)
    
        //Add record button (as UIView)
        recordButton = UIView(frame: CGRect(x: originX + trackWidth / 4, y:     originY + trackHeight / 4, width: trackWidth / 2, height: trackHeight / 2))
        recordButton.layer.cornerRadius = recordButton.bounds.width / 2
        recordButton.layer.borderWidth = 3
        recordButton.layer.borderColor = UIColor.whiteColor().CGColor
        recordButton.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(recordButton)
    }
    
    //Removes text field when user completes file name edit.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        setLabelNameText(textField.text!)
        updateTrackCoreData()
        return true;
    }
    
    func setLabelNameText(name: String) {
        labelName.text = name
    }
    
    func setTextFieldNameText(name: String) {
        textFieldName.text = name
    }
    
    func setLabelDurationText(duration: String) {
        labelDuration.text = duration
    }
    
    func bringTrackToFront() {
        let supervw = self.superview!
        supervw.insertSubview(self, atIndex: supervw.subviews.count - 4)
    }
    
    func touchBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("track touched began")
        let touch: UITouch = touches.first!
        startLoc = touch.locationInView(self)
        if !isInEditMode {
            bringTrackToFront()
        }
    }
    
    func touchMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("track touched moved")
        if !isInEditMode {
            wasDragged = true
            let touch: UITouch = touches.first!
            let touchLoc: CGPoint = touch.locationInView(self)
        
            //move the track node relative to the starting location.
            let newCenterX = self.center.x + touchLoc.x - startLoc.x
            let newCenterY = self.center.y + touchLoc.y - startLoc.y
            if newCenterX < self.superview?.frame.width && newCenterX > 0 {
                self.center.x = newCenterX
            }
            if newCenterY < self.superview?.frame.height && newCenterY > 30 {
                self.center.y = newCenterY
            }
        }
    }
    
    func touchEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("track touched ended")
        if (!wasDragged) {
            if (!hasStartedRecording) {
                print("started recording")
                
                var originX = self.bounds.origin.x
                var originY = self.bounds.origin.y
                var trackHeight = self.bounds.height
                var trackWidth = self.bounds.width
                
                var animation = CABasicAnimation(keyPath: "cornerRadius")
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.fromValue = recordButton.bounds.width / 2
                animation.toValue = 6.0
                animation.duration = 0.5
                recordButton.layer.cornerRadius = 6
                recordButton.layer.addAnimation(animation, forKey: "cornerRadius")
                
                Track.animateWithDuration(0.4, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.recordButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
                    }, completion: nil )
                
                let currentDateTime = NSDate()
                let formatter = NSDateFormatter()
                formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
                let recordingName = formatter.stringFromDate(currentDateTime) + ".wav"
                let pathArray = [projectDirectory!, recordingName]
                let filePath = NSURL.fileURLWithPathComponents(pathArray)
                
                var session = AVAudioSession.sharedInstance()
                do {
                    try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
                } catch _ {
                }
                do {
                    try session.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
                } catch _ {
                }
                
                audioRecorder = try? AVAudioRecorder(URL: filePath!, settings: [String : AnyObject]())
                audioRecorder.delegate = self
                audioRecorder.meteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                
                hasStartedRecording = true
                hasStoppedRecording = false
            } else if (!hasStoppedRecording) {
                print("stopping recording")
                Track.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.recordButton.transform = CGAffineTransformMakeScale(0.01, 0.01)
                    }, completion: { (Bool) -> Void in
                        self.recordButton.removeFromSuperview()
                        self.addSubview(self.audioPlot)
                        self.addSubview(self.labelName)
                        self.addSubview(self.labelDate)
                        self.addSubview(self.labelDuration)
                })
                
                audioRecorder.stop()
                var audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setActive(false)
                } catch _ {
                }
                hasStoppedRecording = true
            } else if (readyToPlay) {
                playAudio()
            }
            
        } else {
            updateTrackCoreData()
            wasDragged = false
        }
    }
    
    func playAudio() {
        if !isInEditMode {
            print("playing")
            (superview as! LinkManager).showStopButton()
            stopAudio()
            audioPlayer.play()
            //reset the progress view to beginning
            UIView.animateWithDuration(0.001, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveLinear], animations: { () -> Void in
                self.progressView.frame = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 0, height: self.bounds.height)
            }, completion: nil)
        
            progressView = UIView(frame: CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 1, height: self.bounds.height))
            progressView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
            progressView.layer.cornerRadius = 2
        
            self.addSubview(progressView)
            self.bringSubviewToFront(labelName)
            self.bringSubviewToFront(labelDuration)
            self.bringSubviewToFront(labelDate)
        
            //play progress view
            UIView.animateWithDuration(audioPlayer.duration, delay: 0.1, options:[UIViewAnimationOptions.CurveLinear, UIViewAnimationOptions.BeginFromCurrentState], animations: { () -> Void in
                var tmpFrame: CGRect = self.progressView.frame
                tmpFrame.origin.x += self.bounds.width + 1
                self.progressView.frame = tmpFrame
            }, completion: nil)
        }
    }
    
    func stopAudio() {
        audioPlayer.stop()
        audioPlayer.currentTime = 0.0
        UIView.animateWithDuration(0.001, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveLinear], animations: { () -> Void in
            self.progressView.frame = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 0, height: self.bounds.height)
            }, completion: nil)
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if superview is LinkManager {
            print("attempting to stop")
            (superview as! LinkManager).hideStopButton()
        }
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if ( flag ) {
            recordedAudio.filePathUrl = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
            audioPlayer = try? AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl)
            audioPlayer.prepareToPlay()
            audioPlayer.delegate = self
            readyToPlay = true
            print("recording ready for playback!")
            
            audioFile = EZAudioFile(URL: recordedAudio.filePathUrl)
            drawWaveform()
            
            //Set the duration label text
            let durationSec = audioFile.duration
            let format = NSDateFormatter()
            format.dateFormat = "H:mm:ss"
            let durationDate = NSDate(timeIntervalSinceReferenceDate: durationSec)
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            let text = format.stringFromDate(durationDate)
            setLabelDurationText(text)
            updateTrackCoreData()
        } else {
            print("did not record successfully")
        }
    }

    func drawWaveform() {
        let waveformData = self.audioFile.getWaveformData()
        self.audioPlot.updateBuffer(waveformData.buffers[0], withBufferSize: waveformData.bufferSize)
    }
    
    func editMode(gestureRecognizer: UIGestureRecognizer) {
        if !self.isInEditMode {
            self.isInEditMode = true
            let editView = TrackEditView(frame: self.frame, track: self)
            (self.superview as! LinkManager).mode = "NOTOUCHES"
            self.superview?.addSubview(editView)
            editView.animateOpen()
        }
        
        //self.frame = CGRectMake(frame.origin.x - 15, frame.origin.y - 15, frame.width + 30, frame.height + 30)
        
        if !self.isInEditMode && false {
        self.isInEditMode = true
        self.savedBoundsDuringEdit = self.frame
        let supervw = self.superview!
        supervw.bringSubviewToFront(self)
            
        //Add text field for allowing track name edits (masks name label)
        self.textFieldName = UITextField(frame: self.labelName.frame)
        self.textFieldName.textAlignment = NSTextAlignment.Center
        self.textFieldName.textColor = UIColor.whiteColor()
        self.textFieldName.borderStyle = UITextBorderStyle.None
        self.textFieldName.layer.cornerRadius = 12
        self.textFieldName.delegate = self
        self.textFieldName.text = self.labelName.text
        self.addSubview(self.textFieldName)
        self.labelName.removeFromSuperview()
        
        //Add button for exiting edit mode
        exitEditModeButton = UIButton(frame: CGRect(x: self.bounds.origin.x + 15, y: self.bounds.origin.y + 26, width: 20, height: 20))
        let image = UIImage(named: "close-button")
        exitEditModeButton.setImage(image, forState: UIControlState.Normal)
        exitEditModeButton.addTarget(self, action: "exitEditMode:", forControlEvents: UIControlEvents.TouchUpInside)
        exitEditModeButton.adjustsImageWhenHighlighted = true;
        self.addSubview(exitEditModeButton)
        
        //Add button for exiting edit mode
        let cropButton = UIButton(frame: CGRect(x: self.bounds.origin.x + 45, y: self.bounds.origin.y + 26, width: 20, height: 20))
        cropButton.setImage(image, forState: UIControlState.Normal)
        cropButton.addTarget(self, action: "trimAudio:", forControlEvents: UIControlEvents.TouchUpInside)
        cropButton.adjustsImageWhenHighlighted = true;
        self.addSubview(cropButton)
        
        self.audioPlot.removeFromSuperview()
        let filePath = recordedAudio.filePathUrl
        let waveformEditView = WaveformEditView(frame: CGRect(x: 0, y: self.bounds.height / 9.6, width: self.bounds.width, height: self.bounds.height / 2.4))
        waveformEditView.setAudio(filePath)
        self.addSubview(waveformEditView)
            
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let newFrame = self.superview!.frame
            self.frame = newFrame
           
            //Frequently reused bounds values
            let originX = self.bounds.origin.x
            let originY = self.bounds.origin.y
            let trackHeight = self.bounds.height
            let trackWidth = self.bounds.width
            
            //Resize waveform plot
            /*self.audioPlot.frame = CGRect(x: originX - 1, y: originY + trackHeight / 9.6, width: trackWidth + 2, height: trackHeight / 2.4)
            self.drawWaveform()
            self.audioPlot.layer.borderWidth = 1
            self.audioPlot.layer.borderColor = UIColor.whiteColor().CGColor
            */
            waveformEditView.frame = CGRect(x: 0, y: trackHeight / 9.6, width: trackWidth, height: trackHeight / 2.4)
            waveformEditView.layer.borderWidth = 1
            waveformEditView.layer.borderColor = UIColor.whiteColor().CGColor
            
            //Resize label for file name
            self.textFieldName.frame = CGRect(x: originX + trackWidth / 4.0, y: originY + 25, width: trackWidth / 2.0, height: 26.0)
            self.textFieldName.font = UIFont(name: "ArialMT", size: 25)
            self.textFieldName.textAlignment = NSTextAlignment.Center
            
            //Resize label for duration
            self.labelDuration.frame = CGRect(x: originX + (trackWidth * 2.0 / 3.0), y: originY + trackHeight / 10.6 + trackHeight / 2.4 + 5, width: trackWidth / 3.0 - 5, height: 26.0)
            self.labelDuration.font = UIFont(name: "ArialMT", size: 25)
            
            //Hide date label
            self.labelDate.hidden = true
            
            //Resize progress bar
            self.progressView.frame = CGRect(x: self.bounds.width + 1, y: self.bounds.origin.y, width: 1, height: self.bounds.height)
        
            }, completion: { (bool:Bool) -> Void in
                let animation = CABasicAnimation(keyPath: "cornerRadius")
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.fromValue = 12.0
                animation.toValue = 0.0
                animation.duration = 0.3
                self.layer.cornerRadius = 0
                self.layer.addAnimation(animation, forKey: "cornerRadius")
        })
        
        //Add volume slider and label
        let volumeSlider = UISlider(frame: CGRect(x: 0, y: self.bounds.origin.y + self.bounds.height - self.bounds.height * 3.0 / 9.0 - 4 , width: self.frame.width, height: self.bounds.height / 9.0))
        volumeSlider.backgroundColor = UIColor.clearColor()
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 1.0
        volumeSlider.continuous = true
        volumeSlider.value = 0.5
        self.addSubview(volumeSlider)
            
        let volumeLabel = UILabel(frame: CGRect(x: self.bounds.origin.x + 5, y: self.bounds.origin.y + self.bounds.height - self.bounds.height * 3.5 / 9.0 - 4, width: self.frame.width, height: self.bounds.height / 9.0))
        volumeLabel.text = "Track Volume"
        volumeLabel.textAlignment = NSTextAlignment.Left
        volumeLabel.textColor = UIColor.whiteColor()
        volumeLabel.font = UIFont(name: volumeLabel.font.fontName, size: 18)
        self.addSubview(volumeLabel)

        //Add color buttons to change track color
        let colorList = colors()
        var i = 0.0
        for color in colorList {
            let colorButton = UIButton(frame: CGRect(x: self.bounds.origin.x + (self.bounds.width - 4.0) * CGFloat(i) / 5.0 + 2, y: self.bounds.origin.y + self.bounds.height - self.bounds.height * 2.0 / 9.0 - 4, width: (self.bounds.width - 4.0) / 5.0, height: self.bounds.height / 9.0))
            colorButton.backgroundColor = color
            colorButton.layer.borderColor = UIColor.whiteColor().CGColor
            colorButton.layer.borderWidth = 1.0
            colorButton.layer.cornerRadius = 10.0
            colorButton.addTarget(self, action: "changeColor:", forControlEvents: UIControlEvents.TouchUpInside)
            self.addSubview(colorButton)
            i++
        }
        }
    }
    
    func exitEditMode(sender: UIButton) {
        isInEditMode = false
        (self.superview as! LinkManager).hideToolbars(false)
        bringTrackToFront()
        
        labelName.frame = textFieldName.frame
        labelName.text = textFieldName.text
        self.addSubview(labelName)
        textFieldName.removeFromSuperview()
        exitEditModeButton.removeFromSuperview()
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            
            self.frame = self.savedBoundsDuringEdit
            self.layer.cornerRadius = 12
            //Frequently reused bounds values
            let originX = self.bounds.origin.x
            let originY = self.bounds.origin.y
            let trackHeight = self.bounds.height
            let trackWidth = self.bounds.width
            
            //Resize label for file name
            self.labelDuration.font = UIFont(name: "ArialMT", size: 10)
            self.labelName.frame = CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2)

            //unhide date label
            self.labelDate.hidden = false
            
            //Resize label for duration
            self.labelDuration.frame = CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth - (trackWidth * 2.0 / 12.0) , height: trackHeight * 1.4 / 7.0)
            
            //Resize waveform plot
            self.audioPlot.frame = CGRect(x: originX, y: originY + trackHeight/4.2, width: trackWidth, height: trackHeight - trackHeight/4.2 - (trackHeight * 1.4 / 7.0))
            self.drawWaveform()
            self.audioPlot.layer.borderWidth = 0
            
            //Resize progress bar
            self.progressView.frame = CGRect(x: self.bounds.width + 1, y: self.bounds.origin.y, width: 1, height: self.bounds.height)
            }, completion: { (bool:Bool) -> Void in
                self.updateTrackCoreData()
        })
    }
    
    func updateTrackSubviews(newTrackUrl newTrackUrl: String) {
        let pathArray = [projectDirectory!, NSString(string: newTrackUrl).lastPathComponent]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        
        recordedAudio.filePathUrl = filePath
        recordedAudio.title = filePath!.lastPathComponent
        audioPlayer = try? AVAudioPlayer(contentsOfURL: filePath!)
        audioPlayer.prepareToPlay()
        
        audioFile = EZAudioFile(URL: filePath)
        drawWaveform()
        
        //Set the duration label text
        var durationSec = audioFile.duration
        var format = NSDateFormatter()
        format.dateFormat = "H:mm:ss"
        var durationDate = NSDate(timeIntervalSinceReferenceDate: durationSec)
        format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        var text = format.stringFromDate(durationDate)
        setLabelDurationText(text)
        updateTrackCoreData()
    }
    
    func changeColor(sender: UIButton) {
        self.backgroundColor = sender.backgroundColor
        audioPlot.backgroundColor = UIColor.clearColor()
        updateTrackCoreData()
    }
    
    func deleteTrack() {
        print("DELETE TRACK")
        deleteTrackFromCoreData()
        stopAudio()
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let curCenter = self.center
            self.frame = CGRect(x: curCenter.x, y: curCenter.y, width: 0.0, height: 0.0)
            self.layer.cornerRadius = 12
            //Frequently reused bounds values
            let originX = self.bounds.origin.x
            let originY = self.bounds.origin.y
            let trackHeight = self.bounds.height
            let trackWidth = self.bounds.width
            
            //Resize label for file name
            self.labelDuration.font = UIFont(name: "ArialMT", size: 10)
            self.labelName.frame = CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2)
            
            //unhide date label
            self.labelDate.hidden = false
            
            //Resize label for duration
            self.labelDuration.frame = CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth - (trackWidth * 2.0 / 12.0) , height: trackHeight * 1.4 / 7.0)
            
            //Resize waveform plot
            self.audioPlot.frame = CGRect(x: originX, y: originY + trackHeight/4.2, width: trackWidth, height: trackHeight - trackHeight/4.2 - (trackHeight * 1.4 / 7.0))
            self.drawWaveform()
            self.audioPlot.layer.borderWidth = 0

            //Resize progress bar
            self.progressView.frame = CGRect(x: self.bounds.width + 1, y: self.bounds.origin.y, width: 1, height: self.bounds.height)
            }, completion: { (bool:Bool) -> Void in
                self.removeFromSuperview()
        })

    }
    
    func updateTrackCoreData() {
        print("Updating track data")
        let request = NSFetchRequest(entityName: "TrackEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "trackID = %@", argumentArray: [self.trackID])
        let results: NSArray = try! self.context.executeFetchRequest(request)
        if results.count == 1 {
            let trackEntity = results[0] as! TrackEntity
            let trackData = NSKeyedArchiver.archivedDataWithRootObject(self)
            trackEntity.track = trackData
        }
        do {
            try self.context.save()
        } catch _ {
        }
    }
    
    func saveTrackCoreData(projectEntity: ProjectEntity) {
        let trackData: NSData = NSKeyedArchiver.archivedDataWithRootObject(self)
        let trackEntity = NSEntityDescription.insertNewObjectForEntityForName("TrackEntity", inManagedObjectContext: context) as! TrackEntity
        trackEntity.track = trackData
        trackEntity.project = projectEntity
        trackEntity.trackID = self.trackID
        do {
            try self.context.save()
        } catch _ {
        }
    }
    
    func deleteTrackFromCoreData() {
        let request = NSFetchRequest(entityName: "TrackEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "trackID = %@", argumentArray: [self.trackID])
        let results: NSArray = try! self.context.executeFetchRequest(request)
        if results.count == 1 {
            let trackToDelete = results[0] as! TrackEntity
            self.context.deleteObject(trackToDelete)
        }
    }
}

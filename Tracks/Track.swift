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

class Track: UIView, AVAudioRecorderDelegate, UITextFieldDelegate {

    var recordedAudio: RecordedAudio = RecordedAudio()
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var wasDragged = false
    var startLoc: CGPoint!
    var hasStartedRecording = false
    var hasStoppedRecording = true
    var readyToPlay = false
    var labelName: UILabel!
    var labelDate: UILabel!
    var labelDuration: UILabel!
    var textFieldName: UITextField!
    var progressView: UIView!
    var isInEditMode: Bool = false

    var recordButton: UIView!
    
    var audioPlot: EZAudioPlot!
    var audioFile: EZAudioFile!
    
    var projectDirectory: String!
    
    var appDel: AppDelegate!
    var context: NSManagedObjectContext!
    
    var longPressLock: Bool = false
    
    var trackID: String = ""
    
    required convenience init(coder aDecoder: NSCoder) {
        var bounds = aDecoder.decodeCGRectForKey("bounds")
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        var projectName = aDecoder.decodeObjectForKey("projectName") as String
        var projectDirectory = docDirectory.stringByAppendingPathComponent(projectName)
        var trackName = aDecoder.decodeObjectForKey("trackName") as String
        if trackName == "" {
            self.init(frame:bounds)
        } else {
            var audioFileUrl = projectDirectory.stringByAppendingPathComponent(trackName)
            self.init(frame: bounds)
            
            recordButton.removeFromSuperview()
            
            recordedAudio.filePathUrl = NSURL(fileURLWithPath: audioFileUrl)
            recordedAudio.title = recordedAudio.filePathUrl.lastPathComponent
            hasStartedRecording = true
            hasStoppedRecording = true
        
            audioPlayer = AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl, error: nil)
            println("recording ready for playback!")
        
            audioFile = EZAudioFile(URL: recordedAudio.filePathUrl)
        
            self.drawWaveform()
        
            readyToPlay = true
    
            self.labelDate.text = aDecoder.decodeObjectForKey("labelDate") as String?
            self.labelDuration.text = aDecoder.decodeObjectForKey("labelDuration") as String?
        }
        
        self.backgroundColor = (aDecoder.decodeObjectForKey("color") as UIColor)
        self.audioPlot.backgroundColor = self.backgroundColor
        self.labelName.text = aDecoder.decodeObjectForKey("labelName") as String?
        self.projectDirectory = projectDirectory
        self.center = aDecoder.decodeCGPointForKey("center")
        self.trackID = aDecoder.decodeObjectForKey("trackID") as String

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
        aCoder.encodeObject(projectDirectory.lastPathComponent, forKey: "projectName")
        aCoder.encodeObject(labelName.text, forKey: "labelName")
        aCoder.encodeObject(labelDate.text, forKey: "labelDate")
        aCoder.encodeObject(labelDuration.text, forKey: "labelDuration")
        aCoder.encodeCGPoint(self.center, forKey: "center")
        aCoder.encodeObject(self.backgroundColor, forKey: "color")
        aCoder.encodeObject(self.trackID, forKey: "trackID")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.appDel = UIApplication.sharedApplication().delegate as AppDelegate
        self.context = appDel.managedObjectContext!
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        if self.backgroundColor == nil {
            println("picking color")
            self.backgroundColor = pickColor()
        }
        
        //set progressView 
        progressView = UIView(frame: CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 1, height: self.bounds.height))
        progressView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        progressView.layer.cornerRadius = 2
        
        //Set the track id
        if self.trackID.isEmpty {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
            self.trackID = formatter.stringFromDate(currentDateTime)
        }
        
        //Frequently reused bounds values
        var originX = self.bounds.origin.x
        var originY = self.bounds.origin.y
        var trackHeight = self.bounds.height
        var trackWidth = self.bounds.width
        
        //using EZAudio for now
        audioPlot = EZAudioPlot(frame: CGRect(x: originX, y: originY + trackHeight/4.2, width: trackWidth, height: trackHeight - trackHeight/4.2 - (trackHeight * 1.4 / 7.0)))
        audioPlot.plotType = EZPlotType.Buffer
        audioPlot.backgroundColor = self.backgroundColor
        audioPlot.color = UIColor.whiteColor()
        audioPlot.shouldFill   = false
        audioPlot.shouldMirror = true
        
        //Add label for file name
        labelName = UILabel(frame: CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2))
        labelName.textAlignment = NSTextAlignment.Center
        labelName.textColor = UIColor.whiteColor()
        labelName.userInteractionEnabled = true
        
        //Add long press gesture recognizer to allow user to change file name
        var longPress = UILongPressGestureRecognizer(target: self, action: "labelFileNameLongPressed:")
        longPress.minimumPressDuration = 0.75;  // Seconds
        longPress.numberOfTapsRequired = 0;
        labelName.addGestureRecognizer(longPress)
        
        
        //Create text field that will accept input on long press
        textFieldName = UITextField(frame: CGRect(x: originX, y: originY + 1, width: trackWidth, height: trackHeight/4.2))
        textFieldName.textAlignment = NSTextAlignment.Center
        textFieldName.textColor = UIColor.whiteColor()
        textFieldName.borderStyle = UITextBorderStyle.None
        textFieldName.layer.cornerRadius = 12
        textFieldName.delegate = self
        
        //Add label for date
        var todaysDate:NSDate = NSDate()
        var dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        var dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
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
    
    //Activated when file name label is longpressed. Adds input textView.
    func labelFileNameLongPressed(gestureRecognizer:UIGestureRecognizer) {
        if (!longPressLock) {
            longPressLock = true
            textFieldName.text = labelName.text
            setLabelNameText("")
            self.addSubview(textFieldName)
            textFieldName.becomeFirstResponder()
        } else {
            longPressLock = false
        }
        
    }
    
    //Removes text field when user completes file name edit.
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        setLabelNameText(textField.text)
        textField.removeFromSuperview()
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
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var touch: UITouch = touches.anyObject() as UITouch
        startLoc = touch.locationInView(self)
        if !isInEditMode {
            self.superview?.bringSubviewToFront(self)
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if (!wasDragged) {
            if (!hasStartedRecording) {
                println("started recording")
                
                var originX = self.bounds.origin.x
                var originY = self.bounds.origin.y
                var trackHeight = self.bounds.height
                var trackWidth = self.bounds.width
                
                var animation = CABasicAnimation(keyPath: "cornerRadius")
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.fromValue = recordButton.bounds.width / 2
                animation.toValue = 6.0
                animation.duration = 0.5
                self.recordButton.layer.cornerRadius = 6
                self.recordButton.layer.addAnimation(animation, forKey: "cornerRadius")
                
                Track.animateWithDuration(0.4, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.recordButton.transform = CGAffineTransformMakeScale(0.9, 0.9)
                 }, completion: nil )
                
                let currentDateTime = NSDate()
                let formatter = NSDateFormatter()
                formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
                let recordingName = formatter.stringFromDate(currentDateTime) + ".wav"
                let pathArray = [projectDirectory, recordingName]
                let filePath = NSURL.fileURLWithPathComponents(pathArray)
            
                var session = AVAudioSession.sharedInstance()
                session.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
                session.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker,
                     error:nil)
                
                audioRecorder = AVAudioRecorder(URL: filePath, settings: nil, error: nil)
                audioRecorder.delegate = self
                audioRecorder.meteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                
                hasStartedRecording = true
                hasStoppedRecording = false
            } else if (!hasStoppedRecording) {
                println("stopped recording")
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
                audioSession.setActive(false, error: nil)
                self.hasStoppedRecording = true
            } else if (readyToPlay) {
                self.playAudio()
            }

        } else {
            self.updateTrackCoreData()
            self.wasDragged = false
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if !isInEditMode {
            wasDragged = true
            var touch: UITouch = touches.anyObject() as UITouch
            var touchLoc: CGPoint = touch.locationInView(self)
        
            //move the track node relative to the starting location.
            Track.animateWithDuration(0.01, delay: 0.01, options: UIViewAnimationOptions.BeginFromCurrentState|UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.frame.origin.x += touchLoc.x - self.startLoc.x;
                    self.frame.origin.y += touchLoc.y - self.startLoc.y;
                }, completion: nil )
        }
    }
    
    func playAudio() {
        println("playing")
        
        self.audioPlayer.stop()
        self.audioPlayer.currentTime = 0.0
        self.audioPlayer.play()
        
        UIView.animateWithDuration(0.001, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState|UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                self.progressView.frame = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 0, height: self.bounds.height)
            }, completion: nil)
        
        self.progressView = UIView(frame: CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: 1, height: self.bounds.height))
        self.progressView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        self.progressView.layer.cornerRadius = 2
        
        self.addSubview(self.progressView)
        self.bringSubviewToFront(self.labelName)
        self.bringSubviewToFront(self.labelDuration)
        self.bringSubviewToFront(self.labelDate)
        
        UIView.animateWithDuration(self.audioPlayer.duration, delay: 0.1, options:UIViewAnimationOptions.CurveLinear|UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
                var tmpFrame: CGRect = self.progressView.frame
                tmpFrame.origin.x += self.bounds.width + 1
                self.progressView.frame = tmpFrame
            }, completion: nil)
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if ( flag ) {
            recordedAudio.filePathUrl = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
            audioPlayer = AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl, error: nil)
            readyToPlay = true
            println("recording ready for playback!")
            
            audioFile = EZAudioFile(URL: recordedAudio.filePathUrl)
            self.drawWaveform()
            
            //Set the duration label text
            var durationSec = Float64(audioFile.totalFrames()) / audioFile.fileFormat().mSampleRate
            var format = NSDateFormatter()
            format.dateFormat = "H:mm:ss"
            var durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(durationSec))
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            var text = format.stringFromDate(durationDate)
            self.setLabelDurationText(text)
            self.updateTrackCoreData()
        } else {
            println("did not record successfully")
        }
    }

    func drawWaveform () {
        audioFile.getWaveformDataWithCompletionBlock(
            { (waveformData: UnsafeMutablePointer<Float>, length: UInt32) in
                self.audioPlot.updateBuffer(waveformData, withBufferSize:length);
        })
    }
    
    func editMode() {
        println("SHOW Edit Mode")
        self.isInEditMode = true
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            var newFrame = self.superview!.frame
            self.frame = newFrame
           
            //Frequently reused bounds values
            var originX = self.bounds.origin.x
            var originY = self.bounds.origin.y
            var trackHeight = self.bounds.height
            var trackWidth = self.bounds.width
            
            //Resize label for file name
            self.labelName.frame = CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2)
            
            //Resize label for date
            self.labelDate.frame = CGRect(x: originX + (trackWidth / 12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth, height: trackHeight * 1.4 / 7.0)
            
            //Resize label for duration
            self.labelDuration.frame = CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth - (trackWidth * 2.0 / 12.0) , height: trackHeight * 1.4 / 7.0)
            
            //Resize waveform plot
            self.audioPlot.frame = CGRect(x: originX - 1, y: originY + trackHeight/4.2, width: trackWidth + 2, height: trackHeight - trackHeight/4.2 - (trackHeight * 1.4 / 7.0))
            self.drawWaveform()
            self.audioPlot.layer.borderWidth = 1
            self.audioPlot.layer.borderColor = UIColor.whiteColor().CGColor
            
            //Resize progress bar
            self.progressView.frame = CGRect(x: self.bounds.width + 1, y: self.bounds.origin.y, width: 1, height: self.bounds.height)
        
            }, completion: { (bool:Bool) -> Void in
                var animation = CABasicAnimation(keyPath: "cornerRadius")
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
                animation.fromValue = 12.0
                animation.toValue = 0.0
                animation.duration = 0.3
                self.layer.cornerRadius = 0
                self.layer.addAnimation(animation, forKey: "cornerRadius")
        })
        
        
    }
    
    func exitEditMode(frame: CGRect) {
        self.isInEditMode = false
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            
            self.frame = frame
            self.layer.cornerRadius = 12
            //Frequently reused bounds values
            var originX = self.bounds.origin.x
            var originY = self.bounds.origin.y
            var trackHeight = self.bounds.height
            var trackWidth = self.bounds.width
            
            //Resize label for file name
            self.labelName.frame = CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2)
            
            //Resize label for date
            self.labelDate.frame = CGRect(x: originX + (trackWidth / 12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth, height: trackHeight * 1.4 / 7.0)
            
            //Resize label for duration
            self.labelDuration.frame = CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth - (trackWidth * 2.0 / 12.0) , height: trackHeight * 1.4 / 7.0)
            
            //Resize waveform plot
            self.audioPlot.frame = CGRect(x: originX, y: originY + trackHeight/4.2, width: trackWidth, height: trackHeight - trackHeight/4.2 - (trackHeight * 1.4 / 7.0))
            self.drawWaveform()
            self.audioPlot.layer.borderWidth = 0
            
            //Resize progress bar
            self.progressView.frame = CGRect(x: self.bounds.width + 1, y: self.bounds.origin.y, width: 1, height: self.bounds.height)
            }, completion: { (bool:Bool) -> Void in
                
        })
    }
    
    func updateTrackCoreData() {
        println("Updating track data")
        var request = NSFetchRequest(entityName: "TrackEntity")
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "trackID = %@", argumentArray: [self.trackID])
        var results: NSArray = self.context.executeFetchRequest(request, error: nil)!
        if results.count == 1 {
            var trackEntity = results[0] as TrackEntity
            var trackData = NSKeyedArchiver.archivedDataWithRootObject(self)
            trackEntity.track = trackData
        }
        self.context.save(nil)
    }
    
    func saveTrackCoreData(projectEntity: ProjectEntity) {
        var trackData: NSData = NSKeyedArchiver.archivedDataWithRootObject(self)
        var trackEntity = NSEntityDescription.insertNewObjectForEntityForName("TrackEntity", inManagedObjectContext: context) as TrackEntity
        trackEntity.track = trackData
        trackEntity.project = projectEntity
        trackEntity.trackID = self.trackID
        self.context.save(nil)
    }
}

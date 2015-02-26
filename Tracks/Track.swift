//
//  Track.swift
//  Tracks
//
//  Created by John Sloan on 2/4/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation

class Track: UIView, AVAudioRecorderDelegate, UITextFieldDelegate {

    var recordedAudio: RecordedAudio!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    
    var wasDragged = false
    var startLoc: CGPoint!
    var hasRecorded = false
    var hasStoppedRecording = true
    var readyToPlay = false
    var labelName: UILabel!
    var labelDate: UILabel!
    var labelDuration: UILabel!
    var textFieldName: UITextField!
    
    var audioPlot: EZAudioPlot!
    var audioFile: EZAudioFile!
    
    var longPressLock: Bool = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 12
        self.backgroundColor = pickColor()
        
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
        self.addSubview(audioPlot)
        
        //Add labels for file name / date / duration(0:00:00 for now)
        //file name
        labelName = UILabel(frame: CGRect(x: originX + 5, y: originY, width: trackWidth - 10, height: trackHeight/4.2))
        labelName.textAlignment = NSTextAlignment.Center
        labelName.textColor = UIColor.whiteColor()
        labelName.userInteractionEnabled = true
        //add long press gesture recognizer to allow user to change file name
        var longPress = UILongPressGestureRecognizer(target: self, action: "labelFileNameLongPressed:")
        longPress.minimumPressDuration = 0.75;  // Seconds
        longPress.numberOfTapsRequired = 0;
        labelName.addGestureRecognizer(longPress)
        self.addSubview(labelName)
        //create text field that will be used to accept input on long press
        textFieldName = UITextField(frame: CGRect(x: originX, y: originY + 1, width: trackWidth, height: trackHeight/4.2))
        textFieldName.textAlignment = NSTextAlignment.Center
        textFieldName.textColor = UIColor.whiteColor()
        textFieldName.borderStyle = UITextBorderStyle.None
        textFieldName.layer.cornerRadius = 12
        textFieldName.delegate = self
        
        //date
        var todaysDate:NSDate = NSDate()
        var dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        var dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        labelDate = UILabel(frame: CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth, height: trackHeight * 1.4 / 7.0))
        labelDate.textAlignment = NSTextAlignment.Left
        labelDate.textColor = UIColor.whiteColor()
        labelDate.text = dateInFormat
        labelDate.font = UIFont(name: labelDate.font.fontName, size: 10)
        self.addSubview(labelDate)
        
        //duration
        labelDuration = UILabel(frame: CGRect(x: originX + (trackWidth/12.0), y: originY + (trackHeight * 5.6 / 7.0), width: trackWidth - (trackWidth * 2.0 / 12.0) , height: trackHeight * 1.4 / 7.0))
        labelDuration.textAlignment = NSTextAlignment.Right
        labelDuration.textColor = UIColor.whiteColor()
        labelDuration.text = "0:00:00"
        labelDuration.font = UIFont(name: labelDuration.font.fontName, size: 10)
        self.addSubview(labelDuration)

        /* USE WHEN RECORD IMAGE IS READY */
        /*var image = UIImage(named: "record")
        var imageView = UIImageView(image: image)
        imageView.frame = self.bounds
        self.addSubview(imageView)
        */
    }
    
    func labelFileNameLongPressed(gestureRecognizer:UIGestureRecognizer) {
        println("GONNA CHANGE THIS NAME BITCH")
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
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        setLabelNameText(textField.text)
        textField.removeFromSuperview()
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
        println("touch began!")
        var touch: UITouch = touches.anyObject() as UITouch
        startLoc = touch.locationInView(self)
        self.superview?.bringSubviewToFront(self)
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        println("touch ended!")
        if (!wasDragged) {
            println("tapped!")
            if (!hasRecorded) {
                
                /*for view in self.subviews {
                    view.removeFromSuperview()
                }
                
                var image = UIImage(named: "stop")
                var imageView = UIImageView(image: image)
                imageView.frame = self.bounds
                //imageView.center = self.center
                self.addSubview(imageView)*/
                
                
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            
                let currentDateTime = NSDate()
                let formatter = NSDateFormatter()
                formatter.dateFormat = "ddMMyyyy-HHmmss"
                let recordingName = formatter.stringFromDate(currentDateTime)+".wav"
                let pathArray = [dirPath, recordingName]
                let filePath = NSURL.fileURLWithPathComponents(pathArray)
                println(filePath)
            
                var session = AVAudioSession.sharedInstance()
                session.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
            
                audioRecorder = AVAudioRecorder(URL: filePath, settings: nil, error: nil)
                audioRecorder.delegate = self
                audioRecorder.meteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                
                hasRecorded = true
                hasStoppedRecording = false
            } else if (!hasStoppedRecording) {
                println("stopped recording")
                //TODO: store file recorded.
                /*for view in self.subviews {
                    view.removeFromSuperview()
                }
                
                var image = UIImage(named: "cassette-yellow")
                var imageView = UIImageView(image: image)
                imageView.frame = self.bounds
                self.addSubview(imageView)*/
                
                audioRecorder.stop()
                var audioSession = AVAudioSession.sharedInstance()
                audioSession.setActive(false, error: nil)
                hasStoppedRecording = true
            } else if (readyToPlay) {
                println("playing")
                audioPlayer.stop()
                audioPlayer.currentTime = 0.0
                audioPlayer.play()
            }

        } else {
            println("tap canceled")
            wasDragged = false
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        wasDragged = true
        var touch: UITouch = touches.anyObject() as UITouch
        var touchLoc: CGPoint = touch.locationInView(self)
        
        //move the track node relative to the starting location.
        Track.animateWithDuration(0.01, delay: 0.01, options: UIViewAnimationOptions.BeginFromCurrentState|UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.frame.origin.x += touchLoc.x - self.startLoc.x;
            self.frame.origin.y += touchLoc.y - self.startLoc.y;
            }, completion: nil )
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        if ( flag ) {
            recordedAudio = RecordedAudio()
            recordedAudio.filePathUrl = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
            audioPlayer = AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl, error: nil)
            readyToPlay = true
            println("recording ready for playback!")
            
            //var waveform = WaveFormView.init(recordedAudio: recordedAudio)
            //self.addSubview(label)
            
            audioFile = EZAudioFile(URL: recordedAudio.filePathUrl)
            
            audioFile.getWaveformDataWithCompletionBlock(
                { (waveformData: UnsafeMutablePointer<Float>, length: UInt32) in
                    self.audioPlot.updateBuffer(waveformData, withBufferSize:length);
                })
            
            //Set the duration label text
            var durationSec = Float64(audioFile.totalFrames()) / audioFile.fileFormat().mSampleRate
            var format = NSDateFormatter()
            format.dateFormat = "H:mm:ss"
            var durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(durationSec))
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            var text = format.stringFromDate(durationDate)
            setLabelDurationText(text)
            
            
            
        } else {
            println("did not record successfully")
        }
    }

    
    
}

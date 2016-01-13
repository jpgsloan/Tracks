//
//  Track.swift
//  Tracks
//
//  Created by John Sloan on 1/8/16.
//  Copyright © 2016 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import QuartzCore

class Track: UIView, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var projectDirectory: String!
    var trackID: String = ""
    var recordedAudio: RecordedAudio = RecordedAudio()
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer?
     
    var wasDragged = false
    var startLoc: CGPoint!
    
    var recordButton: UIView!
    var audioFile: EZAudioFile!
    var hasStartedRecording = false
    var hasStoppedRecording = false
    var readyToPlay = false
    var isInEditMode: Bool = false
    
    var volume: Float = 1.0
    var pan: Float = 0.0
    
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDuration: UILabel!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewConstraint: NSLayoutConstraint!
    
    // view for loading xib
    var view: UIView!
    
    override init (frame: CGRect){
        super.init(frame: frame)
        xibSetup()
        
        // assign shape of track
        self.view.layer.cornerRadius = 12
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clearColor()
        
        // create border outline
        self.layer.borderColor = UIColor(red: 204.0 / 255.0, green: 204.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0).CGColor
        self.layer.borderWidth = 1
        
        // using EZAudio for waveform plot
        audioPlot.plotType = EZPlotType.Buffer
        audioPlot.clipsToBounds = true
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "Track", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    convenience init(frame: CGRect, projectDir: String) {
        self.init(frame: frame)
        self.projectDirectory = projectDir
        initUnrecordedTrack()
    }
    
    func initUnrecordedTrack() {
        self.view.backgroundColor = tealColor()
        
        // set the track id and file path
        if trackID.isEmpty {
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmss-SSS"
            trackID = formatter.stringFromDate(currentDateTime)
        }
        
        // initialize audio recorder with trackID as filepath
        let recordingName = trackID + ".wav"
        let pathArray = [projectDirectory!, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        audioRecorder = try? AVAudioRecorder(URL: filePath!, settings: [String : AnyObject]())
        audioRecorder.delegate = self
        
        // add date to label and hide
        let todaysDate:NSDate = NSDate()
        let dateFormatter:NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        let dateInFormat:String = dateFormatter.stringFromDate(todaysDate)
        labelDate.text = dateInFormat
        labelDate.hidden = true
        
        // add duration to label and hide (0:00:00 until audio is recorded)
        labelDuration.text = "0:00:00"
        labelDuration.hidden = true
        
        // initially hide name label, progress view, and audio plot
        labelName.hidden = true
        progressView.hidden = true
        audioPlot.hidden = true
        
        // add record button (as UIView)
        recordButton = UIView(frame: CGRect(x: bounds.origin.x + bounds.width / 4, y: bounds.origin.y + bounds.height / 4, width: bounds.width / 2, height: bounds.height / 2))
        recordButton.layer.cornerRadius = recordButton.bounds.width / 2
        recordButton.layer.borderWidth = 3
        recordButton.layer.borderColor = UIColor.whiteColor().CGColor
        recordButton.backgroundColor = UIColor.lightGrayColor()
        self.addSubview(recordButton)
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        print("coder init")
        
        let bounds = aDecoder.decodeCGRectForKey("bounds")
        
        // load project directory
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let projectName = aDecoder.decodeObjectForKey("projectName") as! String
        let projectDirectory = NSString(string: docDirectory).stringByAppendingPathComponent(projectName)
        
        self.init(frame: bounds)
        trackID = aDecoder.decodeObjectForKey("trackID") as! String
        self.projectDirectory = projectDirectory
        
        // if trackName is empty string, then audio has yet to be recorded
        let trackName = aDecoder.decodeObjectForKey("trackName") as! String
        if trackName.isEmpty {
            // init as unrecorded track
            initUnrecordedTrack()
        } else {
            // init as track ready to play
            self.view.backgroundColor = (aDecoder.decodeObjectForKey("color") as! UIColor)
            
            // using track name, create new audioPlayer
            let audioFileUrl = NSString(string: projectDirectory).stringByAppendingPathComponent(trackName)
            recordedAudio.filePathUrl = NSURL(fileURLWithPath: audioFileUrl)
            recordedAudio.title = recordedAudio.filePathUrl!.lastPathComponent
            hasStartedRecording = true
            hasStoppedRecording = true
            
            if let player = try? AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl!) {
                audioPlayer = player
                audioPlayer!.prepareToPlay()
                audioPlayer!.delegate = self
                audioFile = EZAudioFile(URL: recordedAudio.filePathUrl)
                drawWaveform()
                readyToPlay = true
            } else {
                print("Could not initialize audioPlayer at url: \(recordedAudio.filePathUrl)")
                readyToPlay = false
            }
            
            labelDate.text = aDecoder.decodeObjectForKey("labelDate") as! String
            labelDuration.text = aDecoder.decodeObjectForKey("labelDuration") as! String
            
            //set volume and pan
            volume = aDecoder.decodeFloatForKey("volume")
            pan = aDecoder.decodeFloatForKey("pan")
        }
        
        //decode values for center and name label
        self.center = aDecoder.decodeCGPointForKey("center")
        labelName.text = aDecoder.decodeObjectForKey("labelName") as! String?
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(recordedAudio.title, forKey: "trackName")
        aCoder.encodeObject(NSString(string: projectDirectory).lastPathComponent, forKey: "projectName")
        aCoder.encodeObject(labelName.text, forKey: "labelName")
        aCoder.encodeObject(labelDate.text, forKey: "labelDate")
        aCoder.encodeObject(labelDuration.text, forKey: "labelDuration")
        aCoder.encodeCGRect(self.bounds, forKey: "bounds")
        aCoder.encodeCGPoint(self.center, forKey: "center")
        aCoder.encodeObject(self.view.backgroundColor, forKey: "color")
        aCoder.encodeObject(trackID, forKey: "trackID")
        aCoder.encodeFloat(volume, forKey: "volume")
        aCoder.encodeFloat(pan, forKey: "pan")
    }
    
    func setLabelNameText(name: String) {
        labelName.text = name.uppercaseString
    }
    
    func setLabelDurationText(duration: String) {
        labelDuration.text = duration
    }
    
    func bringTrackToFront() {
        let supervw = self.superview!
        supervw.insertSubview(self, atIndex: supervw.subviews.count - 5)
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
            
            //move the track node relative to the starting location, within bounds of superview.
            let newCenterX = self.center.x + touchLoc.x - startLoc.x
            let newCenterY = self.center.y + touchLoc.y - startLoc.y
            if newCenterX < self.superview?.frame.width && newCenterX > 0 {
                self.center.x = newCenterX
            }
            if newCenterY < self.superview?.frame.height && newCenterY > 50 {
                self.center.y = newCenterY
            }
        }
    }
    
    func touchEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("track touched ended")
        if (!wasDragged) {
            if (!hasStartedRecording) {
                print("started recording")
                startRecording()
            } else if (!hasStoppedRecording) {
                print("stopping recording")
                stopRecording()
            } else if (readyToPlay) {
                playAudio()
            }
        } else {
            updateTrackCoreData()
            wasDragged = false
        }
    }
    
    func startRecording() {
        // animate record button corners into stop square
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = recordButton.bounds.width / 2
        animation.toValue = 6.0
        animation.duration = 0.4
        recordButton.layer.cornerRadius = 6
        recordButton.layer.addAnimation(animation, forKey: "cornerRadius")
        
        // animate record button size, scaled to 80%
        Track.animateWithDuration(0.4, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.recordButton.transform = CGAffineTransformMakeScale(0.8, 0.8)
            }, completion: nil )
        
        // TODO: Make sure this doesn't switch from headphones
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        do {
            try session.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
        } catch _ {
        }
        
        // begin recording and update bool values
        audioRecorder.prepareToRecord()
        audioRecorder.record()
        
        hasStartedRecording = true
        hasStoppedRecording = false
    }
    
    func stopRecording() {
        // animate removal of record button and unhide labels, audio plot, and progress view
        Track.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.recordButton.transform = CGAffineTransformMakeScale(0.01, 0.01)
            }, completion: { (Bool) -> Void in
                self.recordButton.removeFromSuperview()
                self.audioPlot.hidden = false
                self.labelName.hidden = false
                self.labelDate.hidden = false
                self.labelDuration.hidden = false
                self.progressView.hidden = false
        })
        
        // deactivate the audio session and update bool values
        audioRecorder.stop()
        var audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
        } catch _ {
        }
        hasStoppedRecording = true
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            // save file path and name
            recordedAudio.filePathUrl = recorder.url
            recordedAudio.title = recorder.url.lastPathComponent
            
            // create new audio player
            if let player = try? AVAudioPlayer(contentsOfURL: recordedAudio.filePathUrl!) {
                audioPlayer = player
                audioPlayer!.prepareToPlay()
                audioPlayer!.delegate = self
                readyToPlay = true
                print("ready for playback")
                
                // draw the waveform to the audio plot
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
                print("could not init audioPlayer with url: \(recordedAudio.filePathUrl)")
                readyToPlay = false
            }
        } else {
            print("did not record successfully")
        }
    }
    
    func playAudio() {
        if !isInEditMode && audioPlayer != nil {
            print("playing")
            
            (superview as! LinkManager).showStopButton()
            
            // prepare player for playing and then play
            audioPlayer!.volume = volume
            audioPlayer!.pan = pan
            stopAudio()
            audioPlayer!.play()
            
            //animate progress view during playback
            progressViewConstraint.constant = self.view.frame.width - 7
            UIView.animateWithDuration(audioPlayer!.duration, delay: 0.0, options:[UIViewAnimationOptions.CurveLinear, UIViewAnimationOptions.BeginFromCurrentState], animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: nil)
        } else {
            print("could not play audio")
        }
    }
    
    func playAudioAtTime(time: NSTimeInterval) {
        if !isInEditMode && audioPlayer != nil {
            print("playing")
            
            (superview as! LinkManager).showStopButton()
            
            // prepare player for playing and then play
            audioPlayer!.volume = volume
            audioPlayer!.pan = pan
            stopAudio()
            audioPlayer!.playAtTime(time)
            
            //animate progress view during playback
            progressViewConstraint.constant = self.view.frame.width - 7
            UIView.animateWithDuration(audioPlayer!.duration, delay: 0, options:[UIViewAnimationOptions.CurveLinear, UIViewAnimationOptions.BeginFromCurrentState], animations: { () -> Void in
                self.view.layoutIfNeeded()
                }, completion: nil)
        } else {
            print("could not play audio")
        }
    }
    
    func stopAudio() {
        if audioPlayer != nil {
            audioPlayer!.stop()
            audioPlayer!.currentTime = 0.0
            //reset progress view to beginning
            self.progressView.layer.removeAllAnimations()
            progressViewConstraint.constant = 5
            self.view.layoutIfNeeded()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        //reset progress view to beginning
        progressViewConstraint.constant = 5
        self.view.layoutIfNeeded()
        
        // tell link manager to hide stop button
        if superview is LinkManager {
            print("attempting to stop")
            (superview as! LinkManager).hideStopButton()
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
            if (self.superview as? LinkManager) != nil {
                (self.superview as! LinkManager).mode = "NOTOUCHES"
                self.superview!.addSubview(editView)
                editView.animateOpen()
            }
        }
        
    }
    
    func exitEditMode(volume: Float, pan: Float, color: UIColor, titleText: String) {
        self.volume = volume
        self.pan = pan
        self.view.backgroundColor = color
        setLabelNameText(titleText)
        updateTrackCoreData()
    }
    
    func updateTrackSubviews(newTrackUrl newTrackUrl: String) {
        let pathArray = [projectDirectory!, NSString(string: newTrackUrl).lastPathComponent]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        
        recordedAudio.filePathUrl = filePath
        recordedAudio.title = filePath!.lastPathComponent
        if let player = try? AVAudioPlayer(contentsOfURL: filePath!) {
            audioPlayer = player
            audioPlayer!.prepareToPlay()
            audioPlayer!.delegate = self
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
        } else {
            print("could not init audioPlayer with url: \(recordedAudio.filePathUrl)")
        }
    }
    
    func changeColor(sender: UIButton) {
        self.backgroundColor = sender.backgroundColor
        audioPlot.backgroundColor = UIColor.clearColor()
        updateTrackCoreData()
    }
    
    func deleteTrack() {
        print("DELETE TRACK")
        deleteTrackFromCoreData()
        if readyToPlay {
            stopAudio()
        }
        
        // animate track shrinking
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let curCenter = self.center
            self.frame = CGRect(x: curCenter.x, y: curCenter.y, width: 0.0, height: 0.0)
            
            if self.readyToPlay {
                // resize waveform plot
                self.drawWaveform()
            } else {
                // resize record button
                self.recordButton.frame = CGRect(x: self.bounds.origin.x + self.bounds.width / 4, y: self.bounds.origin.y + self.bounds.height / 4, width: self.bounds.width / 2, height: self.bounds.height / 2)
            }
            }, completion: { (bool:Bool) -> Void in
                self.removeFromSuperview()
        })
        
    }
    
    func updateTrackCoreData() {
        print("Updating track data")
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        if let context = appDel.managedObjectContext {
            let request = NSFetchRequest(entityName: "TrackEntity")
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "trackID = %@", argumentArray: [self.trackID])
            let results: NSArray = try! context.executeFetchRequest(request)
            if results.count == 1 {
                let trackEntity = results[0] as! TrackEntity
                let trackData = NSKeyedArchiver.archivedDataWithRootObject(self)
                trackEntity.track = trackData
            }
            do {
                try context.save()
            } catch _ {
            }
        }
    }
    
    func saveTrackCoreData(projectEntity: ProjectEntity) {
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        if let context = appDel.managedObjectContext {
            let trackData: NSData = NSKeyedArchiver.archivedDataWithRootObject(self)
            let trackEntity = NSEntityDescription.insertNewObjectForEntityForName("TrackEntity", inManagedObjectContext: context) as! TrackEntity
            trackEntity.track = trackData
            trackEntity.project = projectEntity
            trackEntity.trackID = self.trackID
            do {
                try context.save()
            } catch _ {
            }
        }
    }
    
    func deleteTrackFromCoreData() {
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        if let context = appDel.managedObjectContext {
            let request = NSFetchRequest(entityName: "TrackEntity")
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "trackID = %@", argumentArray: [self.trackID])
            let results: NSArray = try! context.executeFetchRequest(request)
            if results.count == 1 {
                let trackToDelete = results[0] as! TrackEntity
                context.deleteObject(trackToDelete)
            }
        }
    }
}
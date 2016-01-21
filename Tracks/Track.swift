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
    var hasBeenDeleted: Bool = false
    var alertWindow: UIWindow?

    enum Mode {
        case Play
        case Link
        case Trash
    }
    var mode = Mode.Play
    
    var volume: Float = 1.0
    var pan: Float = 0.0
    
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDuration: UILabel!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkImageView: UIView!
    @IBOutlet weak var trashImageView: UIView!
    
    // view for loading xib
    var view: UIView!
    var outlineView: UIView!
    
    override init (frame: CGRect){
        super.init(frame: frame)
        xibSetup()
        
        // assign shape of track
        self.view.layer.cornerRadius = 12
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clearColor()
        
        // create border outline (uses separate view so border appears behind subviews)
        outlineView = UIView()
        outlineView.frame = self.bounds
        outlineView.backgroundColor = UIColor.clearColor()
        outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
        outlineView.layer.borderWidth = 1
        outlineView.layer.cornerRadius = self.layer.cornerRadius
        self.view.addSubview(outlineView)
        self.view.sendSubviewToBack(outlineView)

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
        recordButton.layer.borderWidth = 2
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
        
        self.hasBeenDeleted = aDecoder.decodeBoolForKey("hasBeenDeleted")
        if hasBeenDeleted {
            deleteTrack()
        } else {
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
        aCoder.encodeBool(hasBeenDeleted, forKey: "hasBeenDeleted")
    }
    
    func setLabelNameText(name: String) {
        labelName.text = name.uppercaseString
    }
    
    func setLabelDurationText(duration: String) {
        labelDuration.text = duration
    }
    
    func bringTrackToFront() {
        let supervw = self.superview!
        supervw.insertSubview(self, atIndex: supervw.subviews.count - 6)
    }
    
    func touchBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("track touched began")
    
        let touch: UITouch = touches.first!
        startLoc = touch.locationInView(self)
        if !isInEditMode {
            bringTrackToFront()
        }
        selectTrack(startLoc)
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
            if newCenterY < self.superview?.frame.height && newCenterY > 100 {
                self.center.y = newCenterY
            }
        }
    }
    
    func touchEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("track touched ended")
        if !wasDragged && mode != .Trash {
            if !hasStartedRecording {
                print("started recording")
                startRecording()
            } else if !hasStoppedRecording {
                print("stopping recording")
                stopRecording()
            } else if readyToPlay {
                playAudio()
            }
        } else {
            updateTrackCoreData()
            wasDragged = false
        }
        deselectTrack()
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
        
        // animate record button size, scaled to 85%
        Track.animateWithDuration(0.4, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.recordButton.transform = CGAffineTransformMakeScale(0.85, 0.85)
            }, completion: nil )
        
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
        
        audioRecorder.stop()
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
                
                audioRecorder = nil
                
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
        if !isInEditMode && mode == .Play && readyToPlay && audioPlayer != nil {
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
        if !isInEditMode && mode == .Play && readyToPlay && audioPlayer != nil {
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
    
    func editMode(gestureRecognizer: UIGestureRecognizer) -> TrackEditView? {
        if !self.isInEditMode {
            self.isInEditMode = true
            
            // stop audio
            self.stopAudio()
            
            let editView = TrackEditView(frame: self.frame, track: self)
            if let supervw = self.superview as? LinkManager {
                supervw.mode = "NOTOUCHES"
                supervw.addSubview(editView)
                editView.animateOpen()
            }
            
            return editView
        } else {
            return nil
        }
        
    }
    
    func exitEditMode(volume: Float, pan: Float, color: UIColor, titleText: String) {
        self.volume = volume
        self.pan = pan
        self.view.backgroundColor = color
        setLabelNameText(titleText)
        deselectTrack()
        updateTrackCoreData()
        if let _ = (self.superview as? LinkManager) {
            switch mode {
            case .Link:
                (self.superview as! LinkManager).mode = "ADD_SIMUL_LINK"
            case .Play:
                (self.superview as! LinkManager).mode = ""
            case .Trash:
                (self.superview as! LinkManager).mode = "TRASH"
            }
            
        }
    }
    
    func moveMode() {
        mode = .Play
        hideTrashImageView(true)
        hideProgressView(false)
        hideLinkImage(true)
        focusTrackContent()
        
    }
    
    func linkMode() {
        mode = .Link
        hideTrashImageView(true)
        hideProgressView(true)
        hideLinkImage(false)
        dimTrackContent()
    }
    
    func trashMode() {
        mode = .Trash
        hideProgressView(true)
        hideLinkImage(true)
        dimTrackContent()
        hideTrashImageView(false)
    }
    
    func hideProgressView(bool: Bool) {
        // hides or shows the progress bar of the track (shown only in play mode)
        if hasStoppedRecording {
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            progressView.layer.addAnimation(animation, forKey: nil)
            progressView.hidden = bool
        }
    }

    func hideLinkImage(bool:Bool) {
        // hides or shows center crosshairs image for link mode
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.2
        linkImageView.layer.addAnimation(animation, forKey: nil)
        linkImageView.hidden = bool
        self.view.bringSubviewToFront(linkImageView)
        linkImageView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        linkImageView.clipsToBounds = true
        linkImageView.layer.cornerRadius = linkImageView.frame.width / 2.0
    }
    
    func hideTrashImageView(bool: Bool) {
        self.view.clipsToBounds = bool
        self.clipsToBounds = bool
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.1
        trashImageView.layer.addAnimation(animation, forKey: nil)
        trashImageView.hidden = bool
        
        trashImageView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
        trashImageView.clipsToBounds = true
        trashImageView.layer.cornerRadius = linkImageView.frame.width / 2.0
    }
    
    func dimTrackContent() {
        // lowers opacity of content on track to show inactive
        labelName.textColor = labelName.textColor.colorWithAlphaComponent(0.5)
        labelDate.textColor = labelDate.textColor.colorWithAlphaComponent(0.5)
        labelDuration.textColor = labelDuration.textColor.colorWithAlphaComponent(0.5)
        audioPlot.color = audioPlot.color.colorWithAlphaComponent(0.5)
        
        if !hasStoppedRecording {
            // lower opacity for record button if it is displaying
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            recordButton.layer.addAnimation(animation, forKey: nil)
            recordButton.alpha = 0.5
            self.view.insertSubview(recordButton, belowSubview: linkImageView)
        }
    }
    
    func focusTrackContent() {
        // raises opacity of content to show active
        labelName.textColor = labelName.textColor.colorWithAlphaComponent(1)
        labelDate.textColor = labelDate.textColor.colorWithAlphaComponent(1)
        labelDuration.textColor = labelDuration.textColor.colorWithAlphaComponent(1)
        audioPlot.color = audioPlot.color.colorWithAlphaComponent(1)
        
        if !hasStoppedRecording {
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.2
            recordButton.layer.addAnimation(animation, forKey: nil)
            recordButton.alpha = 1.0
            self.view.bringSubviewToFront(recordButton)
        }
    }
    
    func selectTrack(touch: CGPoint) {
        switch mode {
        case .Play:
            // change track border to show selected
            outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.9).CGColor
            outlineView.layer.borderWidth = 2
            self.view.sendSubviewToBack(outlineView)
        case .Link:
            if linkImageView.frame.contains(touch) {
                // change link image border (middle circle + crosshairs) to show adding link
                linkImageView.layer.borderColor = UIColor.whiteColor().CGColor
                linkImageView.layer.borderWidth = 3
            } else {
                // change track border to show selected
                outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.9).CGColor
                outlineView.layer.borderWidth = 2
                self.view.sendSubviewToBack(outlineView)
            }
        case .Trash:
            if !trashImageView.frame.contains(touch) {
                // change track border to show selected
                outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.9).CGColor
                outlineView.layer.borderWidth = 2
                self.view.sendSubviewToBack(outlineView)
            }
        }
    }
    
    func deselectTrack() {
        switch mode {
        case .Play:
            // return track border to normal
            outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
            outlineView.layer.borderWidth = 1
            self.view.sendSubviewToBack(outlineView)
            
        case .Link:
            // return track and link image border to normal
            linkImageView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
            linkImageView.layer.borderWidth = 0
            outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
            outlineView.layer.borderWidth = 1
            self.view.sendSubviewToBack(outlineView)
            
        case .Trash:
            // return track border to normal
            outlineView.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
            outlineView.layer.borderWidth = 1
            self.view.sendSubviewToBack(outlineView)
        }
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
    
    class BasicViewController: UIViewController {
        override func prefersStatusBarHidden() -> Bool {
            return true
        }
    }
    
    func confirmDelete() {
        alertWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
        let actionSheetController: UIAlertController = UIAlertController(title: "Delete Track?", message: "This track will be permanently deleted.", preferredStyle: .ActionSheet)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.alertWindow?.hidden = true
            self.alertWindow = nil
        }
        actionSheetController.addAction(cancelAction)
        
        let simulAction: UIAlertAction = UIAlertAction(title: "Delete", style: .Destructive) { action -> Void in
           print("delete TRACKKKK")
            self.alertWindow?.hidden = true
            self.alertWindow = nil
            self.deleteTrack()
        }
        actionSheetController.addAction(simulAction)
        
        alertWindow!.makeKeyAndVisible()
        alertWindow!.rootViewController = BasicViewController()
        alertWindow!.windowLevel = UIWindowLevelAlert + 1
        alertWindow!.rootViewController!.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func deleteTrack() {
        print("DELETE TRACK")
        deleteTrackFromCoreData()
        if readyToPlay {
            stopAudio()
        }
        
        // delete audio from file system if exists
        if let url = self.recordedAudio.filePathUrl where url != "" {
            let filemgr = NSFileManager.defaultManager()
            do {
                try filemgr.removeItemAtURL(url)
            } catch var error as NSError {
                print("Remove failed: \(error.localizedDescription)")
                // eventually try removing again or make user try again
            } catch {
                print("fatal error")
            }
        }
        
        // animate track shrinking
        UIView.animateWithDuration(0.6, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            let curCenter = self.center
            self.frame = CGRect(x: curCenter.x, y: curCenter.y, width: 0.0, height: 0.0)
            
            self.outlineView.removeFromSuperview()
            
            if self.readyToPlay {
                // resize waveform plot
                self.drawWaveform()
            } else {
                // resize record button
                self.recordButton.frame = CGRect(x: self.bounds.origin.x + self.bounds.width / 4, y: self.bounds.origin.y + self.bounds.height / 4, width: self.bounds.width / 2, height: self.bounds.height / 2)
            }
            }, completion: { (bool:Bool) -> Void in
                self.removeFromSuperview()
                self.hasBeenDeleted = true
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
                do {
                    try context.save()
                } catch _ {
                }
            }
        }
    }
}
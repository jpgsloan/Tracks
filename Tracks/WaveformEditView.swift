//
//  WaveformEditView.swift
//  Tracks
//
//  Created by John Sloan on 9/8/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore

class WaveformEditView: UIView, UIScrollViewDelegate, EZAudioPlayerDelegate {
    
    var audioFile: EZAudioFile!
    var audioPlayer: EZAudioPlayer!
    var duration: CMTime!
    var timeWindow: CMTime = CMTimeMake(6, 1)
    var curTime: NSTimeInterval = 0
    var fileEnded = false
    var isInTrimMode = false
    var didTouchStartTrimBar = false
    var didTouchEndTrimBar = false
    var startTouch: CGPoint!
    var view: UIView!
    var track: Track!
    var scrollTimer: NSTimer!
    var volume: Float = 1.0
    var pan: Float = 0.0
    var circle: CAShapeLayer?
    var spinner: UIActivityIndicatorView?
    var wasTrimmed: Bool = false
    
    var cancelTrimButton: UIButton!
    var trimAudioButton: UIButton!
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var curTimeLabel: UILabel!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var timeline: TimelineView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var timeSelectorView: TimeSelectorView!
    @IBOutlet weak var bottomBarBackgroundView: UIView!
    @IBOutlet weak var audioPlotLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioPlotTrailingConstraint: NSLayoutConstraint!
    
    var widthConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        print("INIT WAVEFORMAUDIO")
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        xibSetup()
        print("INIT WAVEFORM FROM CODER")
        commonInit()
    }
    
    func commonInit() {
        
        self.view.backgroundColor = UIColor.clearColor()
        self.backgroundColor = UIColor.clearColor()
    
        self.sendSubviewToBack(backgroundView)
        
        // set up current time label
        let format = NSDateFormatter()
        format.dateFormat = "mm:ss:SS"
        let durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(0))
        format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let text = format.stringFromDate(durationDate)
        curTimeLabel.text = text
        
        // style the plot
        audioPlot.plotType = EZPlotType.Buffer
        audioPlot.opaque = false
        audioPlot.color = UIColor.whiteColor()
        audioPlot.shouldFill   = false
        audioPlot.shouldMirror = true

        // auto layout constraints for sizing content inside scrollView
        widthConstraint = NSLayoutConstraint(item: scrollContentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        bottomConstraint = NSLayoutConstraint(item: scrollContentView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: cropButton, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: -13.0)
        
        self.view.addConstraint(widthConstraint)
        self.view.addConstraint(bottomConstraint)
        
        scrollView.delegate = self
        
        circle = CAShapeLayer()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "WaveformEditView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    func setAudio(url: NSURL) {
        print("SET AUDIO WAVEFORMEDITVIEW")
        audioFile = EZAudioFile(URL: url)
        audioPlayer = EZAudioPlayer(audioFile: audioFile)
        audioPlayer.delegate = self
    
        updateWaveformView()
    }
    
    func setTrackRef(track: Track) {
        self.track = track
    }
    
    func setTimeRange(timeWindow: CMTime) {
        self.timeWindow = timeWindow
        print("timeWindow: ", terminator: "")
        print(timeWindow.value)
        updateWaveformView()
    }
    
    func setTimeRange(start: CMTime, end: CMTime) {
        let timeWindow = CMTimeGetSeconds(end) - CMTimeGetSeconds(start)
        if timeWindow > 0 {
            // resize audioPlot and timeline
            if isInTrimMode { //if in trimmode, it changes range to fit the trim bars
                self.timeWindow = CMTimeMakeWithSeconds(timeWindow * 5.0 / 4.0, 10000)
            } else {
                self.timeWindow = CMTimeMakeWithSeconds(timeWindow, 10000)
            }
            updateWaveformView()
            
            // scroll to start time
            self.scrollView.contentOffset.x = (self.audioPlot.frame.width) * (CGFloat(CMTimeGetSeconds(start)) / CGFloat(self.audioPlayer.duration))
        } else {
            print("Cannot set range with value: \(timeWindow)")
        }
    }

    func updateTrack(audioURL: NSURL) {
        // update for new trimmed audio, or new track values like pan/vol
        track.updateTrackSubviews(newTrackUrl: audioURL.path!)
    }
    
    func updateWaveformView() {
        //once timeWindow is set, update the waveform view for proper sizing.
        let multiplier = CGFloat(self.audioFile.duration) / CGFloat(CMTimeGetSeconds(self.timeWindow))
        var offset = self.frame.width
        if self.isInTrimMode {
            offset = self.frame.width / 5.0
        }

        //self.view.removeConstraint(self.widthConstraint)
        let newConstraint = NSLayoutConstraint(item: self.scrollContentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: multiplier, constant: offset)
        NSLayoutConstraint.deactivateConstraints([widthConstraint])
        
        widthConstraint = newConstraint
        
        NSLayoutConstraint.activateConstraints([newConstraint])
        self.view.layoutIfNeeded()
        self.audioPlot.alpha = 0.0
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.audioPlotLeadingConstraint.constant = offset / 2.0
            self.audioPlotTrailingConstraint.constant = offset / 2.0
            self.audioPlot.alpha = 1.0
            self.timeline.addOffsets(offset / 2.0, trailing: offset / 2.0)
            self.timeline.updateTimeline(self.audioFile.duration, window: self.timeWindow)
            }) { (Bool) -> Void in
                self.drawWaveform()
                
                self.scrollContentView.setNeedsUpdateConstraints()
                self.scrollContentView.updateConstraintsIfNeeded()
                self.scrollContentView.setNeedsLayout()
                self.scrollContentView.layoutIfNeeded()
                self.scrollView.setNeedsLayout()
                self.scrollView.layoutIfNeeded()
        }
       
        // first remove old sublayer lines
        if let sublayerz = backgroundView.layer.sublayers {
            for layer in sublayerz {
                layer.removeFromSuperlayer()
            }
        }
        // then add top, bottom, and middle lines for audio plot outline.
        let lines = CAShapeLayer()
        let linesPath = UIBezierPath()
        // bottom
        linesPath.moveToPoint(CGPointMake(0, backgroundView.frame.height))
        linesPath.addLineToPoint(CGPointMake(backgroundView.frame.width, backgroundView.frame.height))
        // middle
        linesPath.moveToPoint(CGPointMake(0, audioPlot.frame.height / 2.0 + timeline.frame.height + 1))
        linesPath.addLineToPoint(CGPointMake(self.frame.width, audioPlot.frame.height / 2.0 + timeline.frame.height + 1))
        // top
        linesPath.moveToPoint(CGPointMake(0, timeline.frame.height))
        linesPath.addLineToPoint(CGPointMake(self.frame.width, timeline.frame.height))
        lines.path = linesPath.CGPath
        lines.strokeColor = UIColor.whiteColor().CGColor
        lines.lineWidth = 1
        backgroundView.layer.addSublayer(lines)
        
        
        // update circle behind play button
        if let circle = circle {
            var newBounds = playButton.bounds
            newBounds.origin.x -= 2
            circle.frame = newBounds
            let circlePath = UIBezierPath()
            circlePath.addArcWithCenter(CGPointMake(playButton.frame.width / 2.0, playButton.frame.height / 2.0), radius:(playButton.frame.width + 12.0) / 2.0, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
            circle.path = circlePath.CGPath
            circle.fillColor = UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor
            playButton.layer.insertSublayer(circle, atIndex: 0)
        }
    }
    
    @IBAction func trimMode(sender: UIButton) {
        // Must change self to trim mode first, then set the new time range, then move on to other views.
        isInTrimMode = true
        setTimeRange(CMTimeMakeWithSeconds(audioPlayer.duration * 0.0 / 4.0, 10000), end: CMTimeMakeWithSeconds(audioPlayer.duration * 4.0 / 4.0, 10000))
        timeSelectorView.trimMode()
        timeline.toggleTrimMode(true)
        
        // fade out buttons, time label, and timeline
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.3
        cropButton.layer.addAnimation(animation, forKey: nil)
        cropButton.hidden = true
        curTimeLabel.layer.addAnimation(animation, forKey: nil)
        curTimeLabel.hidden = true
        timeline.layer.addAnimation(animation, forKey: nil)
        timeline.alpha = 0.14
        
        // add button to cancel
        cancelTrimButton = UIButton(frame: cropButton.frame)
        cancelTrimButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        cancelTrimButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelTrimButton.addTarget(self, action: "cancelTrimMode:", forControlEvents: UIControlEvents.TouchUpInside)
        cancelTrimButton.adjustsImageWhenHighlighted = true;
        cancelTrimButton.sizeToFit()
        cancelTrimButton.center.y = cropButton.center.y
        cancelTrimButton.frame.origin.x = self.view.frame.width - cancelTrimButton.frame.width - 20 // adjust to match trailing constraint
        bottomBarBackgroundView.addSubview(cancelTrimButton)
        // animate fade in
        cancelTrimButton.hidden = true
        cancelTrimButton.layer.addAnimation(animation, forKey: nil)
        cancelTrimButton.hidden = false
    
        // add button to trim
        trimAudioButton = UIButton(frame: curTimeLabel.frame)
        trimAudioButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        trimAudioButton.setTitle("Trim", forState: UIControlState.Normal)
        trimAudioButton.addTarget(self, action: "trimAudio:", forControlEvents: UIControlEvents.TouchUpInside)
        trimAudioButton.adjustsImageWhenHighlighted = true;
        trimAudioButton.sizeToFit()
        trimAudioButton.center.y = curTimeLabel.center.y
        bottomBarBackgroundView.addSubview(trimAudioButton)
        // animate fade in
        trimAudioButton.hidden = true
        trimAudioButton.layer.addAnimation(animation, forKey: nil)
        trimAudioButton.hidden = false
    }
    
    func cancelTrimMode(sender: UIButton) {
        print("CANCELED TRIM")
        exitTrimMode()
    }
    
    func exitTrimMode() {
        timeSelectorView.exitTrimMode()
        timeline.toggleTrimMode(false)
        isInTrimMode = false
        setTimeRange(CMTimeMake(6, 1))
        
        // fade out trim buttons
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.3
        cancelTrimButton.layer.addAnimation(animation, forKey: nil)
        cancelTrimButton.hidden = true
        trimAudioButton.layer.addAnimation(animation, forKey: nil)
        trimAudioButton.hidden = true
        
        // fade in time label, and timeline
        cropButton.layer.addAnimation(animation, forKey: nil)
        cropButton.hidden = false
        curTimeLabel.layer.addAnimation(animation, forKey: nil)
        curTimeLabel.hidden = false
        timeline.layer.addAnimation(animation, forKey: nil)
        timeline.alpha = 1
        
        // set playback to zero
        // this should eventually resume playback where it left off and check if still in bounds of trimmed audio
        scrollView.contentOffset.x = 0
        curTime = 0
        curTimeLabel.text = "00:00:00"
        
    }

    func stopScrolling() {
        print("stop scrolling")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.scrollTimer != nil {
                self.scrollTimer.invalidate()
                self.scrollTimer = nil
            }
        })
    }
    
    func scrollWithAcceleration(accel: CGFloat, direction: Bool) {
        // direction: left = true, right = false
        let scaleFactor = CGFloat(4) // speeds up scrolling a little
        print("ACCEL: ", terminator: "")
        print(accel)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.scrollTimer != nil {
                self.scrollTimer.invalidate()
                self.scrollTimer = nil
            }

            if direction {
                self.scrollTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval((0.1 / abs(accel)) * scaleFactor), target: self, selector: "timeScrollLeft", userInfo: nil, repeats: true)
            } else {
                self.scrollTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval((0.1 / abs(accel)) * scaleFactor), target: self, selector: "timeScrollRight", userInfo: nil, repeats: true)
            }
        })
        
    }
    
    func timeScrollLeft() {
        // if scrolling the bar results in new distance, without bars too close (6px, or 0.1sec) then scroll
        let checkDistNewStart = timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX + 5.0, end: timeSelectorView.endBarX)
        let checkDistNewEnd = timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX, end: timeSelectorView.endBarX + 5.0)
        if scrollView.contentOffset.x >= 5 && (checkDistNewStart || checkDistNewEnd) {
            if timeSelectorView.didTouchEndTrimBar && checkDistNewStart {
                updateTimeSelectorStartBar(CGFloat(5.0))
                scrollView.contentOffset.x -= 5
            } else if timeSelectorView.didTouchStartTrimBar && checkDistNewEnd {
                updateTimeSelectorEndBar(CGFloat(5.0))
                scrollView.contentOffset.x -= 5
            } else {
                print("BAR DISTANCE REACHED MIN")
                stopScrolling()
            }
        } else if scrollView.contentOffset.x > 0 {
            // this is so you don't overscroll (by 5)
            if timeSelectorView.didTouchEndTrimBar && timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX + 1.0, end: timeSelectorView.endBarX) {
                updateTimeSelectorStartBar(CGFloat(1.0))
                scrollView.contentOffset.x -= 1
            } else if timeSelectorView.didTouchStartTrimBar && timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX, end: timeSelectorView.endBarX + 1.0) {
                updateTimeSelectorEndBar(CGFloat(1.0))
                scrollView.contentOffset.x -= 1
            } else {
                print("BAR DISTANCE REACHED MIN")
                stopScrolling()
            }
        } else {
            print("CONTENT OFFSET REACHED MAX")
            stopScrolling()
        }
    }
    
    func timeScrollRight() {
        let checkDistNewStart = timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX - 5.0, end: timeSelectorView.endBarX)
        let checkDistNewEnd = timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX, end: timeSelectorView.endBarX - 5.0)
        if scrollView.contentOffset.x < scrollView.contentSize.width - self.view.frame.width - 5 && (checkDistNewStart || checkDistNewEnd) {
            if timeSelectorView.didTouchEndTrimBar && checkDistNewStart {
                updateTimeSelectorStartBar(CGFloat(-5.0))
                scrollView.contentOffset.x += 5
            } else if timeSelectorView.didTouchStartTrimBar && checkDistNewEnd {
                updateTimeSelectorEndBar(CGFloat(-5.0))
                scrollView.contentOffset.x += 5
            } else {
                print("BAR DISTANCE REACHED MIN")
                stopScrolling()
            }
        } else if scrollView.contentOffset.x < scrollView.contentSize.width - self.view.frame.width {
            if timeSelectorView.didTouchEndTrimBar && timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX - 1.0, end: timeSelectorView.endBarX) {
                updateTimeSelectorStartBar(CGFloat(-1.0))
                scrollView.contentOffset.x += 1
            } else if timeSelectorView.didTouchStartTrimBar && timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX, end: timeSelectorView.endBarX - 1.0) {
                updateTimeSelectorEndBar(CGFloat(-1.0))
                scrollView.contentOffset.x += 1
            } else {
                print("BAR DISTANCE REACHED MIN")
                stopScrolling()
            }
        } else {
            print("CONTENT OFFSET OR BAR DISTANCE REACHED MIN")
            stopScrolling()
        }
    }

    
    func updateTimeSelectorStartBar(delta: CGFloat) {
        // double check bar distance is ok, then animate start bar to new X value.
        if timeSelectorView.startBarX != nil {
            let newStartX = timeSelectorView.startBarX! + delta
            if timeSelectorView.checkBarDistance(withStart: newStartX, end: timeSelectorView.endBarX!) {
                timeSelectorView.startBarX! += delta
                let barAnimation = timeSelectorView.createBarAnimation(withX: timeSelectorView.startBarX!, duration: 0.00001)
                timeSelectorView.startBarShapeLayer.addAnimation(barAnimation, forKey: nil)
                let midSquareAnimation = timeSelectorView.createMidSquareAnimation(withX: timeSelectorView.startBarX, width: timeSelectorView.endBarX - timeSelectorView.startBarX, duration: 0.00001)
                timeSelectorView.middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
            } else {
                stopScrolling()
            }
        } else {
            print("startBarX was nil in WaveformEditView.updateTimeSelectorStartBar")
        }

    }
    
    func updateTimeSelectorEndBar(delta: CGFloat) {
        // double check bar distance is ok, then animate end bar to new X value.
        if timeSelectorView.endBarX != nil {
            let newEndX = timeSelectorView.endBarX! + delta
            if timeSelectorView.checkBarDistance(withStart: timeSelectorView.startBarX!, end: newEndX) {
                timeSelectorView.endBarX! += delta
                let barAnimation = timeSelectorView.createBarAnimation(withX: timeSelectorView.endBarX!, duration: 0.00001)
                timeSelectorView.endBarShapeLayer.addAnimation(barAnimation, forKey: nil)
                let midSquareAnimation = timeSelectorView.createMidSquareAnimation(withX: timeSelectorView.startBarX, width: timeSelectorView.endBarX - timeSelectorView.startBarX, duration: 0.00001)
                timeSelectorView.middleSquareShapeLayer.addAnimation(midSquareAnimation, forKey: nil)
            } else {
                stopScrolling()
            }
        } else {
            print("endBarX was nil in WaveformEditView.updateTimeSelectorEndBar")
        }
    }
    
    func trimAudio(sender: UIButton) {
        print("TRIM AUDIO")
        spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        spinner?.center = CGPointMake(self.view.center.x, audioPlot.center.y)
        self.view.addSubview(spinner!)
        
        for subview in self.view.subviews {
            subview.userInteractionEnabled = false
        }
        
        //switch to background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            
            //back to the main thread to start spinner
            dispatch_async(dispatch_get_main_queue(), {
                if let _ = self.spinner {
                    self.spinner!.startAnimating()
                }
                })

            if let asset: AVAsset = AVAsset(URL: self.audioFile.url) {
                self.exportAsset(asset, fileName: self.audioFile.url.lastPathComponent! + "-tmp-cropping.wav")
            }
            })
    }
    
    func exportAsset(asset:AVAsset, fileName:String) {
        let projectDirectory = audioFile.url.URLByDeletingLastPathComponent!
        let trimmedFilePath = projectDirectory.URLByAppendingPathComponent(fileName)
        print("trimmed url: ", terminator: "")
        print(trimmedFilePath)

        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(trimmedFilePath.path!) {
            print("sound exists")
        }
        
        if let exporter: AVAssetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) {
        exporter.outputFileType = AVFileTypeAppleM4A
        exporter.outputURL = trimmedFilePath
        
        // e.g. the first 5 seconds
        let startTime = timeSelectorView.currentStartTime()
        let stopTime = timeSelectorView.currentEndTime()
        print("start: ", terminator: "")
        print(startTime.value)
        print("end: ", terminator: "")
        print(stopTime.value)
        
        let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
        exporter.timeRange = exportTimeRange
        
        // set up the audio mix
        let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
        if tracks.count == 0 {
            return
        }
        let track = tracks[0] 
        let exportAudioMix = AVMutableAudioMix()
        let exportAudioMixInputParameters =
        AVMutableAudioMixInputParameters(track: track)
        exportAudioMixInputParameters.setVolume(1.0, atTime: CMTimeMake(0, 1))
        exportAudioMix.inputParameters = [exportAudioMixInputParameters]
        exporter.audioMix = exportAudioMix
        
        // export trimmed file
        exporter.exportAsynchronouslyWithCompletionHandler({
            switch exporter.status {
            case  AVAssetExportSessionStatus.Failed:
                print("export failed \(exporter.error)")
            case AVAssetExportSessionStatus.Cancelled:
                print("export cancelled \(exporter.error)")
            default:
                print("export complete")
                // on success, delete the old file, rename cropped file with old name.
                let oldFileURL = self.audioFile.url
                let filemgr = NSFileManager.defaultManager()
                var error: NSError?
                do {
                    try filemgr.removeItemAtURL(oldFileURL)
                    print("Remove successful")
                    // move file
                    do {
                        try filemgr.moveItemAtURL(trimmedFilePath, toURL: oldFileURL)
                        print("Move successful")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.setAudio(oldFileURL)
                            self.wasTrimmed = true
                            
                            // update track
                            self.updateTrack(oldFileURL)
                            self.exitTrimMode()
                            
                            // remove spinner
                            if let _ = self.spinner {
                                self.spinner!.stopAnimating()
                                self.spinner!.removeFromSuperview()
                                self.spinner = nil
                            }

                        })
                    } catch var error1 as NSError {
                        error = error1
                        print("Moved failed with error: \(error!.localizedDescription)")
                    }
                } catch var error1 as NSError {
                    error = error1
                    print("Remove failed: \(error!.localizedDescription)")
                    // eventually try removing again or delete trimmed audio and make user try again
                } catch {
                    fatalError()
                }
            }
            for subview in self.view.subviews {
                subview.userInteractionEnabled = true
            }
        })
        }
    }
    
    @IBAction func playAudio(sender: UIButton) {
        if isInTrimMode {
            playAudioWithStartEnd(sender)
        } else {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                // set playbutton image to play
                playButton.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
                playButton.imageEdgeInsets.left += 2
                playButton.imageEdgeInsets.right -= 2
            } else {
                if curTime >= audioPlayer.duration {
                    curTime = NSTimeInterval(0.0)
                }
                audioPlayer.currentTime = curTime
                audioPlayer.volume = volume
                audioPlayer.pan = pan
                audioPlayer.play()
                // set playbutton image to pause
                playButton.setImage(UIImage(named: "pause.png"), forState: UIControlState.Normal)
                playButton.imageEdgeInsets.left -= 2
                playButton.imageEdgeInsets.right += 2
            }
        }
    }
    
    func playAudioWithStartEnd(sender: UIButton) {
    
        let startTime = timeSelectorView.currentStartTime()
        let endTime = timeSelectorView.currentEndTime()
        
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            // set playbutton image to play
            playButton.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
            playButton.imageEdgeInsets.left += 2
            playButton.imageEdgeInsets.right -= 2
        } else {
            if curTime >= endTime.seconds {
                curTime = NSTimeInterval(startTime.seconds)
            } else if curTime < startTime.seconds {
                curTime = startTime.seconds
            }
            audioPlayer.currentTime = curTime
            audioPlayer.volume = volume
            audioPlayer.pan = pan
            audioPlayer.play()
           // set playbutton image to pause
            playButton.setImage(UIImage(named: "pause.png"), forState: UIControlState.Normal)
            playButton.imageEdgeInsets.left -= 2
            playButton.imageEdgeInsets.right += 2
        }
        
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, reachedEndOfAudioFile audioFile: EZAudioFile!) {
        print("file ended")
        fileEnded = true
        // set playbutton image to play
        playButton.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
        playButton.imageEdgeInsets.left += 2
        playButton.imageEdgeInsets.right -= 2
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
        if !isInTrimMode {
            if fileEnded {
                curTime = audioPlayer.duration
                fileEnded = false
            } else {
                curTime = NSTimeInterval(Double(framePosition) / Double(audioPlayer.totalFrames)) * audioPlayer.duration
            }
            
            let format = NSDateFormatter()
            if curTime >= 3600 {
                format.dateFormat = "H:mm:ss:SS"
            } else {
                format.dateFormat = "mm:ss:SS"
            }
            
            let durationDate = NSDate(timeIntervalSinceReferenceDate: curTime)
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            let text = format.stringFromDate(durationDate)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // update current time label and scroll offset
                self.curTimeLabel.text = text
                self.scrollView.contentOffset.x = self.audioPlot.frame.width * (CGFloat(self.curTime) / CGFloat(self.audioPlayer.duration))
            })
        } else {
            if fileEnded {
                curTime = timeSelectorView.currentEndTime().seconds
                fileEnded = false
            } else {
                curTime = NSTimeInterval(Double(framePosition) / Double(audioPlayer.totalFrames)) * audioPlayer.duration
            }
            if curTime >= timeSelectorView.currentEndTime().seconds {
                // reached end of play interval, reset bars, buttons, and pause.
                curTime = 0.0
                audioPlayer.pause()
                // set playbutton image to play
                playButton.setImage(UIImage(named: "play.png"), forState: UIControlState.Normal)
                playButton.imageEdgeInsets.left += 2
                playButton.imageEdgeInsets.right -= 2
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.timeSelectorView.playBarTime = nil
                    self.timeSelectorView.setNeedsDisplay()
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // update playback bar
                    self.timeSelectorView.playBarTime = CMTime(seconds: self.curTime, preferredTimescale: 10000)
                    self.timeSelectorView.setNeedsDisplay()
                })
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if isInTrimMode {
            let curX = scrollView.contentOffset.x
            if curX < 0 {
                timeSelectorView.frame.origin.x = -curX
            } else if curX + scrollView.frame.width > scrollView.contentSize.width {
                print("should scroll time selector")
                print(curX)
                timeSelectorView.frame.origin.x = -((curX + scrollView.frame.width) - scrollView.contentSize.width)
            } else {
                timeSelectorView.setNeedsDisplay()
            }
        } else {
            // update current time label
            let seconds = CGFloat(audioPlayer.duration) * (scrollView.contentOffset.x / audioPlot.frame.width)
            let format = NSDateFormatter()
            if seconds >= 3600 {
                format.dateFormat = "H:mm:ss:SS"
            } else {
                format.dateFormat = "mm:ss:SS"
            }
            
            // set curTime and durationDate
            var durationDate: NSDate!
            if seconds >= CGFloat(audioPlayer.duration) {
                curTime = audioPlayer.duration
                durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(seconds))
            } else if seconds < 0 {
                curTime = NSTimeInterval(0)
                durationDate = NSDate(timeIntervalSinceReferenceDate: curTime)
            } else {
                curTime = NSTimeInterval(seconds)
                durationDate = NSDate(timeIntervalSinceReferenceDate: curTime)
            }
            
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            let text = format.stringFromDate(durationDate)
            curTimeLabel.text = text
        }
        
    }

    func drawWaveform() {
        let waveformData = self.audioFile!.getWaveformData()
        self.audioPlot.updateBuffer(waveformData.buffers[0], withBufferSize: waveformData.bufferSize)
    }
    
    func adjustVolume(value: Float) {
        volume = value
        audioPlayer.volume = value
    }
    
    func adjustPan(value: Float) {
        pan = value
        audioPlayer.pan = value
    }
}

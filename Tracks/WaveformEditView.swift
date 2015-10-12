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
    
    var cancelTrimButton: UIButton!
    var trimAudioButton: UIButton!

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var curTimeLabel: UILabel!
    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var timeline: TimelineView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var timeSelectorView: TimeSelectorView!
    
    @IBOutlet weak var audioPlotLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioPlotTrailingConstraint: NSLayoutConstraint!
    
    var widthConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        println("INIT WAVEFORMAUDIO")
        commonInit()
    }
    
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        xibSetup()
        println("INIT WAVEFORM FROM CODER")
        commonInit()
    }
    
    func commonInit() {
        
        self.backgroundColor = UIColor.clearColor()
        
        // set up current time label
        var format = NSDateFormatter()
        format.dateFormat = "mm:ss:SS"
        var durationDate = NSDate(timeIntervalSinceReferenceDate: NSTimeInterval(0))
        format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        var text = format.stringFromDate(durationDate)
        curTimeLabel.text = text
        
        // style the plot
        audioPlot.plotType = EZPlotType.Buffer
        audioPlot.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(2.0)
        audioPlot.opaque = false
        audioPlot.color = UIColor.whiteColor()
        audioPlot.shouldFill   = true
        audioPlot.shouldMirror = true

        // auto layout constraints for sizing content inside scrollView
        widthConstraint = NSLayoutConstraint(item: scrollContentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        bottomConstraint = NSLayoutConstraint(item: scrollContentView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: cropButton, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: -13.0)
        
        self.view.addConstraint(widthConstraint)
        self.view.addConstraint(bottomConstraint)
        
        scrollView.delegate = self
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "WaveformEditView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    func setAudio(url: NSURL) {
        println("SET AUDIO WAVEFORMEDITVIEW")
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
        print("timeWindow: ")
        println(timeWindow.value)
        updateWaveformView()
    }
    
    func setTimeRange(start: CMTime, end: CMTime) {
        var timeWindow = CMTimeGetSeconds(end) - CMTimeGetSeconds(start)
        if timeWindow > 0 {
            // resize audioPlot and timeline
            if isInTrimMode {
                self.timeWindow = CMTimeMakeWithSeconds(timeWindow * 5.0 / 4.0, 10000)
            } else {
                self.timeWindow = CMTimeMakeWithSeconds(timeWindow, 10000)
            }
            updateWaveformView()
            
            // scroll to start time
            self.scrollView.contentOffset.x = (self.audioPlot.frame.width) * (CGFloat(CMTimeGetSeconds(start)) / CGFloat(self.audioPlayer.duration))
        } else {
            print("Cannot set range with value: ")
            println(timeWindow)
        }
    }

    func updateTrack(audioURL: NSURL) {
        // update for new trimmed audio, or new track values like pan/vol
        track.updateTrackSubviews(newTrackUrl: audioURL.path!)
    }
    
    func updateWaveformView() {
        //once timeWindow is set, update the waveform view for proper sizing.
        var multiplier = CGFloat(self.audioFile.duration) / CGFloat(CMTimeGetSeconds(self.timeWindow))
        var offset = self.frame.width
        if self.isInTrimMode {
            offset = self.frame.width / 5.0
        }
        var tmpWidthValue = self.widthConstraint.multiplier
        self.view.removeConstraint(self.widthConstraint)
        self.widthConstraint = NSLayoutConstraint(item: self.scrollContentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: multiplier, constant: offset)
        self.view.addConstraint(self.widthConstraint)
        
        self.audioPlotLeadingConstraint.constant = offset / 2.0
        self.audioPlotTrailingConstraint.constant = offset / 2.0
        self.drawWaveform()
        
        self.timeline.addOffsets(offset / 2.0, trailing: offset / 2.0)
        self.timeline.updateTimeline(self.audioFile.duration)
        
        self.scrollContentView.setNeedsUpdateConstraints()
        self.scrollContentView.updateConstraintsIfNeeded()
        self.scrollContentView.setNeedsLayout()
        self.scrollContentView.layoutIfNeeded()
        self.scrollView.setNeedsLayout()
        self.scrollView.layoutIfNeeded()
        
    }
    
    @IBAction func trimMode(sender: UIButton) {
        timeSelectorView.trimMode()
        isInTrimMode = true
        setTimeRange(CMTimeMakeWithSeconds(audioPlayer.duration * 0.0 / 4.0, 10000), end: CMTimeMakeWithSeconds(audioPlayer.duration * 4.0 / 4.0, 10000))
        
        // fade out buttons and time label
        var animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.3
        cropButton.layer.addAnimation(animation, forKey: nil)
        cropButton.hidden = true
        curTimeLabel.layer.addAnimation(animation, forKey: nil)
        curTimeLabel.hidden = true
        playButton.layer.addAnimation(animation, forKey: nil)
        playButton.hidden = true
        
        // add button to cancel
        cancelTrimButton = UIButton(frame: cropButton.frame)
        cancelTrimButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        cancelTrimButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelTrimButton.addTarget(self, action: "cancelTrimMode:", forControlEvents: UIControlEvents.TouchUpInside)
        cancelTrimButton.adjustsImageWhenHighlighted = true;
        cancelTrimButton.sizeToFit()
        
        self.addSubview(cancelTrimButton)
        // animate fade in
        cancelTrimButton.hidden = true
        cancelTrimButton.layer.addAnimation(animation, forKey: nil)
        cancelTrimButton.hidden = false
    
        // add button to trim
        trimAudioButton = UIButton(frame: playButton.frame)
        trimAudioButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        trimAudioButton.setTitle("Trim", forState: UIControlState.Normal)
        trimAudioButton.addTarget(self, action: "trimAudio:", forControlEvents: UIControlEvents.TouchUpInside)
        trimAudioButton.adjustsImageWhenHighlighted = true;
        trimAudioButton.sizeToFit()
        
        self.addSubview(trimAudioButton)
        // animate fade in
        trimAudioButton.hidden = true
        trimAudioButton.layer.addAnimation(animation, forKey: nil)
        trimAudioButton.hidden = false
    }
    
    func cancelTrimMode(sender: UIButton) {
        println("CANCELED TRIM")
        exitTrimMode()
    }
    
    func exitTrimMode() {
        timeSelectorView.exitTrimMode()
        isInTrimMode = false
        setTimeRange(CMTimeMake(6, 1))
        
        // fade out trim buttons
        var animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.3
        cancelTrimButton.layer.addAnimation(animation, forKey: nil)
        cancelTrimButton.hidden = true
        trimAudioButton.layer.addAnimation(animation, forKey: nil)
        trimAudioButton.hidden = true
        
        // fade in play buttons and time label
        cropButton.layer.addAnimation(animation, forKey: nil)
        cropButton.hidden = false
        curTimeLabel.layer.addAnimation(animation, forKey: nil)
        curTimeLabel.hidden = false
        playButton.layer.addAnimation(animation, forKey: nil)
        playButton.hidden = false
        
        // set playback to zero
        //TODO: this should eventually resume playback where it left off and check if still in bounds of trimmed audio
        scrollView.contentOffset.x = 0
        curTime = 0
        curTimeLabel.text = "00:00:00"
        
    }

    func scrollWithAcceleration(accel: CGFloat, direction: Bool) {
        // direction: left = true, right = false
        let scaleFactor = CGFloat(2) // speeds up scrolling a little
        print("ACCEL: ")
        println(accel)
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
        if scrollView.contentOffset.x >= 5 {
            scrollView.contentOffset.x -= 5
        } else if scrollView.contentOffset.x > 0 {
            scrollView.contentOffset.x -= 1
        } else {
            println("CONTENT OFFSET REACHED MAX")
            stopScrolling()
        }
    }
    
    func timeScrollRight() {
        if scrollView.contentOffset.x < scrollView.contentSize.width - self.view.frame.width - 5 {
            scrollView.contentOffset.x += 5
        } else if scrollView.contentOffset.x < scrollView.contentSize.width - self.view.frame.width {
            scrollView.contentOffset.x += 1
        } else {
            println("CONTENT OFFSET REACHED MIN")
            stopScrolling()
        }
    }
    
    func stopScrolling() {
        println("stop scrolling")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.scrollTimer != nil {
                self.scrollTimer.invalidate()
                self.scrollTimer = nil
            }
        })
    }
    
    func trimAudio(sender: UIButton) {
        println("TRIM AUDIO")
        if let asset = AVAsset.assetWithURL(audioFile.url) as? AVAsset {
            exportAsset(asset, fileName: audioFile.url.lastPathComponent! + "-tmp-cropping.wav")
        }
    }
    
    func exportAsset(asset:AVAsset, fileName:String) {
        let projectDirectory = audioFile.url.URLByDeletingLastPathComponent!
        let trimmedFilePath = projectDirectory.URLByAppendingPathComponent(fileName)
        print("trimmed url: ")
        println(trimmedFilePath)

        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(trimmedFilePath.path!) {
            println("sound exists")
        }
        
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        exporter.outputFileType = AVFileTypeAppleM4A
        exporter.outputURL = trimmedFilePath
        
        // e.g. the first 5 seconds
        let startTime = timeSelectorView.currentStartTime()
        let stopTime = timeSelectorView.currentEndTime()
        print("start: ")
        println(startTime.value)
        print("end: ")
        println(stopTime.value)
        
        let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
        exporter.timeRange = exportTimeRange
        
        // set up the audio mix
        let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
        if tracks.count == 0 {
            return
        }
        let track = tracks[0] as! AVAssetTrack
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
                println("export failed \(exporter.error)")
            case AVAssetExportSessionStatus.Cancelled:
                println("export cancelled \(exporter.error)")
            default:
                println("export complete")
                //TODO: delete the old file, rename cropped file with old name.
                // on success, delete the old file, rename cropped file with old name.
                let oldFileURL = self.audioFile.url
                let filemgr = NSFileManager.defaultManager()
                var error: NSError?
                if filemgr.removeItemAtURL(oldFileURL, error: &error) {
                    println("Remove successful")
                    // move file
                    if filemgr.moveItemAtURL(trimmedFilePath, toURL: oldFileURL, error: &error) {
                        println("Move successful")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.setAudio(oldFileURL)
                            // update track
                            self.updateTrack(oldFileURL)
                            self.exitTrimMode()
                        })
                    } else {
                        println("Moved failed with error: \(error!.localizedDescription)")
                    }
                } else {
                    println("Remove failed: \(error!.localizedDescription)")
                    //TODO: try removing again or delete trimmed audio and make user try again
                }
            }
        })
    }
    
    @IBAction func playAudio(sender: UIButton) {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            playButton.setTitle("Play", forState: UIControlState.Normal)
            playButton.sizeToFit()
        } else {
            if curTime >= audioPlayer.duration {
                curTime = NSTimeInterval(0.0)
            }
            audioPlayer.currentTime = curTime
            audioPlayer.play()
            playButton.setTitle("Pause", forState: UIControlState.Normal)
            playButton.sizeToFit()
        }
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, reachedEndOfAudioFile audioFile: EZAudioFile!) {
        println("file ended")
        fileEnded = true
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
        if !isInTrimMode {
            if fileEnded {
                curTime = audioPlayer.duration
                fileEnded = false
            } else {
                curTime = NSTimeInterval(Double(framePosition) / Double(audioPlayer.totalFrames)) * audioPlayer.duration
            }
            
            var format = NSDateFormatter()
            if curTime >= 3600 {
                format.dateFormat = "H:mm:ss:SS"
            } else {
                format.dateFormat = "mm:ss:SS"
            }
            
            var durationDate = NSDate(timeIntervalSinceReferenceDate: curTime)
            format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            var text = format.stringFromDate(durationDate)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // update current time label and scroll offset
                self.curTimeLabel.text = text
                self.scrollView.contentOffset.x = self.audioPlot.frame.width * (CGFloat(self.curTime) / CGFloat(self.audioPlayer.duration))
            })
        } else {
            //TODO: add play capabilities during trim to hear how new audio will sound.
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if isInTrimMode {
            var curX = scrollView.contentOffset.x
            if curX < 0 {
                timeSelectorView.frame.origin.x = -curX
            } else if curX + scrollView.frame.width > scrollView.contentSize.width {
                println("should scroll time selector")
                println(curX)
                timeSelectorView.frame.origin.x = -((curX + scrollView.frame.width) - scrollView.contentSize.width)
            }
        } else {
            // update current time label
            var seconds = CGFloat(audioPlayer.duration) * (scrollView.contentOffset.x / audioPlot.frame.width)
            var format = NSDateFormatter()
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
            var text = format.stringFromDate(durationDate)
            curTimeLabel.text = text
        }
        
    }

    func drawWaveform() {
        let waveformData = self.audioFile!.getWaveformData()
        self.audioPlot.updateBuffer(waveformData.buffers[0], withBufferSize: waveformData.bufferSize)
    }
    
    override func drawRect(rect: CGRect) {
        var context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(context, 1)
        
        // draw bottom line for waveform
        CGContextMoveToPoint(context, 0, audioPlot.frame.height + timeline.frame.height)
        CGContextAddLineToPoint(context, self.frame.width, audioPlot.frame.height + timeline.frame.height)
        
        // draw middle line for waveform
        CGContextMoveToPoint(context, 0, audioPlot.frame.height / 2.0 + timeline.frame.height)
        CGContextAddLineToPoint(context, self.frame.width, audioPlot.frame.height / 2.0 + timeline.frame.height)
        
        // draw top line for waveform
        CGContextMoveToPoint(context, 0, timeline.frame.height)
        CGContextAddLineToPoint(context, self.frame.width, timeline.frame.height)
        CGContextStrokePath(context)
    }
    
}

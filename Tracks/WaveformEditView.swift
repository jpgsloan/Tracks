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
    var view: UIView!

    @IBOutlet weak var cropButton: UIButton!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var timeline: TimelineView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var curTimeLabel: UILabel!
    
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
        audioPlot.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        audioPlot.opaque = false
        audioPlot.color = UIColor.whiteColor()
        audioPlot.shouldFill   = true
        audioPlot.shouldMirror = true

        // auto layout constraints for sizing content inside scrollView
        widthConstraint = NSLayoutConstraint(item: scrollContentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 2.0, constant: 0.0)
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
    
    func setTimeRange(timeWindow: CMTime) {
        self.timeWindow = timeWindow
        print("timeWindow: ")
        println(timeWindow.value)
        updateWaveformView()
    }
    
    func updateWaveformView() {
        var multiplier = CGFloat(audioFile.duration) / CGFloat(CMTimeGetSeconds(timeWindow))
        if multiplier < 1.0 {
            multiplier = 1.0
        }
        var offset = self.frame.width
        
        self.view.removeConstraint(widthConstraint)
        widthConstraint = NSLayoutConstraint(item: scrollContentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: multiplier, constant: offset)
        self.view.addConstraint(widthConstraint)
        
        audioPlotLeadingConstraint.constant = offset / 2.0
        audioPlotTrailingConstraint.constant = offset / 2.0
        drawWaveform()

        timeline.addOffsets(offset / 2.0, trailing: offset / 2.0)
        timeline.updateTimeline(audioFile.duration)
    }
    
    @IBAction func test(sender: UIButton) {
        //TODO: crop audio
        setTimeRange(CMTimeMake(4,1))
        self.layoutIfNeeded()
        scrollView.contentOffset.x = 300
    }
    
    @IBAction func playAudio(sender: UIButton) {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            if curTime >= audioPlayer.duration {
                curTime = NSTimeInterval(0.0)
            }
            audioPlayer.currentTime = curTime
            audioPlayer.play()
        }
    }
    
    func audioPlayer(audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, inAudioFile audioFile: EZAudioFile!) {
        curTime = NSTimeInterval(Double(framePosition) / Double(audioPlayer.totalFrames)) * audioPlayer.duration
       
        var format = NSDateFormatter()
        if curTime >= 3600 {
            format.dateFormat = "H:mm:ss:SS"
        } else {
            format.dateFormat = "mm:ss:SS"
        }
        
        var durationDate: NSDate!
        if curTime == 0 {
            durationDate = NSDate(timeIntervalSinceReferenceDate: audioPlayer.duration)
        } else {
            durationDate = NSDate(timeIntervalSinceReferenceDate: curTime)
        }
        format.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        var text = format.stringFromDate(durationDate)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // update current time label and scroll offset
            self.curTimeLabel.text = text
            self.scrollView.contentOffset.x = self.audioPlot.frame.width * (CGFloat(self.audioPlayer.currentTime) / CGFloat(self.audioPlayer.duration))
        })
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var seconds = CGFloat(audioPlayer.duration) * (scrollView.contentOffset.x / audioPlot.frame.width)
        
        // update current time label
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
        
                //Then update time label
    }
    
    func drawWaveform() {
        // asycronously get waveform data from audio file and update audioPlot buffer.
        var waveClosure: EZAudioWaveformDataCompletionBlock = {
            (waveformData: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, length: Int32) in
            self.audioPlot.updateBuffer(waveformData[0], withBufferSize: UInt32(length))
        }
        audioFile.getWaveformDataWithCompletionBlock(waveClosure)
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

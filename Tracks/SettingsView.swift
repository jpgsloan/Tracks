//
//  SettingsView.swift
//  Tracks
//
//  Created by John Sloan on 1/20/16.
//  Copyright © 2016 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore

class SettingsView: UIView {

    var view: UIView!
    var engine: AVAudioEngine!
    var mixerNode: AVAudioMixerNode!
    
    @IBOutlet weak var topBarBackgroundView: UIView!
    @IBOutlet weak var monitoringSwitch: UISwitch!
    @IBOutlet weak var monitorLevelSlider: UISlider!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        xibSetup()
        commonInit()
    }
    
    func commonInit() {
        // add top bar bottom shadow
        topBarBackgroundView.layer.masksToBounds = false
        topBarBackgroundView.layer.shadowOffset = CGSizeMake(0, 3)
        topBarBackgroundView.layer.shadowRadius = 3
        topBarBackgroundView.layer.shadowOpacity = 0.4
      
        // initialize audio engine and attach input -> mixer (for volume adjustements) -> output
        engine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        mixerNode.outputVolume = 0.5
        engine.attachNode(mixerNode)
        engine.connect(engine.inputNode!, to: mixerNode, format: engine.inputNode!.inputFormatForBus(0))
        engine.connect(mixerNode, to: engine.outputNode, format: mixerNode.inputFormatForBus(0))
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "SettingsView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
 
    @IBAction func switchMonitoring(sender: UISwitch) {
        if sender.on {
            do {
                try engine.start()
            } catch {
                print("monitoring failed to start")
            }
        } else {
            engine.pause()
        }
        
    }
    
    
    @IBAction func changeMonitorLevel(sender: UISlider) {
        mixerNode.outputVolume = sender.value
    }
    
    @IBAction func exitSetting(sender: UIButton) {
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.2
        self.layer.addAnimation(animation, forKey: nil)
        self.hidden = true
        self.userInteractionEnabled = false
    }

}

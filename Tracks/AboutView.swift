//
//  AboutView.swift
//  Tracks
//
//  Created by John Sloan on 1/20/16.
//  Copyright © 2016 JPGS inc. All rights reserved.
//

import UIKit

class AboutView: UIView {

    var view: UIView!
    
    @IBOutlet weak var topBarBackgroundView: UIView!
    
    
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
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = self.bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        self.addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "AboutView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }

    @IBAction func exitAbout(sender: UIButton) {
        let animation = CATransition()
        animation.type = kCATransitionFade
        animation.duration = 0.2
        self.layer.addAnimation(animation, forKey: nil)
        self.hidden = true
        self.userInteractionEnabled = false
    }
    
    

}

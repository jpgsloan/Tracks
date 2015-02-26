//
//  ViewController.swift
//  Tracks
//
//  Created by John Sloan on 1/28/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit
import QuartzCore

class ProjectViewController: UIViewController {
    
    var labelCounter = 0
    
    //@IBOutlet weak var toolbar: UIToolbar!
    
    @IBOutlet weak var drawView: DrawView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(red: 0.969, green: 0.949, blue: 0.922, alpha: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func wasDragged(button: UIButton, event:UIEvent) {
        var touch: UITouch = event.touchesForView(button)?.anyObject() as UITouch
        
        var previousLoc: CGPoint = touch.previousLocationInView(button)
        var loc: CGPoint = touch.locationInView(button)
        var delta_x: CGFloat = loc.x - previousLoc.x;
        var delta_y: CGFloat = loc.y - previousLoc.y;
        
        button.center = CGPointMake(button.center.x + delta_x,
            button.center.y + delta_y);
    }
    
    @IBAction func record(sender: UIButton) {
        println("recording!")
    }

    
    @IBAction func addTrack(sender: UIButton) {
        //Create a new button to add
        //var newButton: UIButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        //newButton.setTitle("Drag Me", forState: UIControlState.Normal)
        //newButton.backgroundColor = UIColor.yellowColor()
        
        //Attach drag action to wasDragged function
        //newButton.addTarget(self, action: "wasDragged:event:", forControlEvents: UIControlEvents.TouchDragInside)
        //newButton.addTarget(self, action: "record:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //Create new Track node.
       
        var newTrack = Track(frame: CGRect(x: self.view.center.x,y: self.view.center.y,width: 100.0,height: 100.0))
        
        //Center and add the new track node.
        newTrack.center = self.view.center
        newTrack.setLabelNameText("untitled " + labelCounter.description)
        labelCounter++
        self.view.addSubview(newTrack)
    }

    @IBAction func undoDraw(sender: UIButton) {
        println("UNDOING")
        drawView.undoDraw()
        
    }
   
}

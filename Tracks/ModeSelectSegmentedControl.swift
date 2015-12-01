//
//  ModeSelectSegmentedControl.swift
//  
//
//  Adapted by John Sloan, from ADVSegmentedControl.swift by Tope Abayomi.
//

import UIKit

@IBDesignable class ModeSelectSegmentedControl: UIControl {
    
    struct item {
        var labelText: String
        var image: UIImageView
    }
    
    private var itemViews = [UIView]()
    
    var thumbView = UIView()
    
    var items: [item] = [ item(labelText: "MOVE", image: UIImageView(image: UIImage(named: "move"))), item(labelText: "LINK", image: UIImageView(image: UIImage(named: "links"))), item(labelText: "SNIP", image: UIImageView(image: UIImage(named: "snip"))) ] {
        didSet {
            setupLabels()
        }
    }
    
    var selectedIndex : Int = 0 {
        didSet {
            displayNewSelectedIndex()
        }
    }
    
    @IBInspectable var selectedLabelColor : UIColor = UIColor.blackColor() {
        didSet {
            setSelectedColors()
        }
    }
    
    @IBInspectable var unselectedLabelColor : UIColor = UIColor.whiteColor() {
        didSet {
            setSelectedColors()
        }
    }
    
    @IBInspectable var thumbColor : UIColor = UIColor.whiteColor() {
        didSet {
            setSelectedColors()
        }
    }
    
    @IBInspectable var borderColor : UIColor = UIColor.whiteColor() {
        didSet {
            layer.borderColor = borderColor.CGColor
        }
    }
    
    @IBInspectable var font : UIFont! = UIFont.systemFontOfSize(10) {
        didSet {
            setFont()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView(){
        self.backgroundColor = UIColor(red: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
        
        // Add bottom border of slightly darker color than background
        let lowerBorder = CALayer()
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if let bool = self.backgroundColor?.getRed(&r, green: &g, blue: &b, alpha: &a) {
            lowerBorder.backgroundColor = UIColor(red: max(r - 0.1, 0.0), green: max(g - 0.1, 0.0), blue: max(b - 0.1, 0.0), alpha: a).CGColor
        }
        lowerBorder.frame = CGRectMake(0, self.frame.height - 1.0, self.frame.width, 1.0)
        layer.addSublayer(lowerBorder)
        
        // set up the labels, constraints, and add thumbview to selected
        setupLabels()
        
        addIndividualItemConstraints(itemViews, mainView: self, padding: 0)
        
        insertSubview(thumbView, atIndex: 0)
    }
    
    func setupLabels(){
        
        for item in itemViews {
            item.removeFromSuperview()
        }
        
        itemViews.removeAll(keepCapacity: true)
        
        for index in 1...items.count {
            let newView = UIView(frame: CGRectMake(0, 0, 70, 40))
            newView.translatesAutoresizingMaskIntoConstraints = false
            newView.userInteractionEnabled = false
            
            let item = items[index - 1]
            let label = UILabel()
            let attributedString = NSMutableAttributedString(string: item.labelText)
            attributedString.addAttribute(NSKernAttributeName, value: CGFloat(1.2), range: NSRange(location: 0, length: item.labelText.characters.count - 1))
            attributedString.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir-Medium", size: 10)!, range: NSRange(location: 0, length: item.labelText.characters.count))
            label.attributedText = attributedString
            label.backgroundColor = UIColor.clearColor()
            label.textAlignment = .Center
            label.textColor = index == 1 ? selectedLabelColor : unselectedLabelColor
            label.translatesAutoresizingMaskIntoConstraints = false
            label.userInteractionEnabled = false
            newView.addSubview(label)
            
            let imgView = UIImageView(image: item.image.image)
            imgView.translatesAutoresizingMaskIntoConstraints = false
            imgView.userInteractionEnabled = false
            newView.addSubview(imgView)
            self.addSubview(newView)
            addItemViewConstraints(newView, label: label, image: imgView)
            itemViews.append(newView)
        }
        
        addIndividualItemConstraints(itemViews, mainView: self, padding: 0)
    }
    
    func addIndividualItemConstraints(items: [UIView], mainView: UIView, padding: CGFloat) {
        
        for (index, button) in items.enumerate() {
            let topConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
            
            let bottomConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0)
            
            var rightConstraint : NSLayoutConstraint!
            
            if index == items.count - 1 {
                
                rightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: -padding)
                
            } else{
                
                let nextButton = items[index+1]
                rightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: nextButton, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: -padding)
            }
            
            
            var leftConstraint : NSLayoutConstraint!
            
            if index == 0 {
                
                leftConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: padding)
                
            } else{
                
                let prevButton = items[index-1]
                leftConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: prevButton, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: padding)
                
                let firstItem = items[0]
                
                let widthConstraint = NSLayoutConstraint(item: button, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: firstItem, attribute: .Width, multiplier: 1.0  , constant: 0)
                
                mainView.addConstraint(widthConstraint)
            }
            
            mainView.addConstraints([topConstraint, bottomConstraint, rightConstraint, leftConstraint])
        }
    }
    
    func addItemViewConstraints(itemView: UIView, label: UILabel, image: UIImageView) {
        let topConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.Bottom, multiplier: 0.1, constant: 0)
    
        let midConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: image, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 1)
        
        let bottomConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.Bottom, multiplier: 0.95, constant: 0)
        
        let labelRightConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0)
        
        let labelLeftConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: 0)
    
        let imgCenterConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        
        let imgHeightConstraint = NSLayoutConstraint(item: image, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: itemView, attribute: NSLayoutAttribute.Height, multiplier: 0.5, constant: 0)
        
        itemView.addConstraints([topConstraint, midConstraint, bottomConstraint, labelRightConstraint, imgCenterConstraint, labelLeftConstraint, imgHeightConstraint])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var selectFrame = self.bounds
        let newWidth = CGRectGetWidth(selectFrame) / CGFloat(items.count)
        selectFrame.size.width = newWidth
        thumbView.frame = selectFrame
        thumbView.backgroundColor = thumbColor
        
        displayNewSelectedIndex()
        
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        var calculatedIndex : Int?
        for (index, item) in itemViews.enumerate() {
            if item.frame.contains(location) {
                calculatedIndex = index
            }
        }
        
        
        if calculatedIndex != nil {
            selectedIndex = calculatedIndex!
            sendActionsForControlEvents(.ValueChanged)
        }
        
        return false
    }
    
    func displayNewSelectedIndex(){
        for (index, item) in itemViews.enumerate() {
            for subview in item.subviews {
                if subview is UILabel {
                    (subview as! UILabel).textColor = unselectedLabelColor
                }
            }
        }
        
        let selItem = itemViews[selectedIndex]
        for subview in selItem.subviews {
            if subview is UILabel {
                (subview as! UILabel).textColor = selectedLabelColor
            }
        }
        self.thumbView.frame = selItem.frame
    }
    
    func setSelectedColors(){
        for item in itemViews {
            for subview in item.subviews {
                if subview is UILabel {
                    (subview as! UILabel).textColor = unselectedLabelColor
                }
            }
        }

        
        if itemViews.count > 0 {
            for subview in itemViews[0].subviews {
                if subview is UILabel {
                    (subview as! UILabel).textColor = selectedLabelColor
                }
            }
        }
        
        thumbView.backgroundColor = thumbColor
    }
    
    func setFont(){
        for item in itemViews {
            for subview in item.subviews {
                if subview is UILabel {
                    (subview as! UILabel).font = font
                }
            }
        }
    }
}

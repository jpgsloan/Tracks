//
//  ProjectCellTableViewCell.swift
//  Tracks
//
//  Created by John Sloan on 3/4/15.
//  Copyright (c) 2015 JPGS inc. All rights reserved.
//

import UIKit

class ProjectCellTableViewCell: UITableViewCell {

    @IBOutlet weak var projectName: UITextField!
    @IBOutlet weak var projectDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

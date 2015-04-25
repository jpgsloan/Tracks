//
//  ProjectTableViewCell.swift
//  
//
//  Created by John Sloan on 4/22/15.
//
//

import UIKit

class ProjectTableViewCell: UITableViewCell {
    @IBOutlet weak var projectName: UILabel!

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

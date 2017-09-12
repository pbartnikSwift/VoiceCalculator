//
//  OperationCell.swift
//  VoiceCalculator
//
//  Created by Przemysław Bartnik on 12.09.2017.
//  Copyright © 2017 Przemysław Bartnik. All rights reserved.
//

import UIKit

class OperationCell: UITableViewCell {

    @IBOutlet weak var operation: UILabel!
    @IBOutlet weak var result: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func set(operation:String, result:String){
        self.operation.text = operation
        self.result.text = result
    }
}

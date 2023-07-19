//
//  IndexedCollectionViewCell.swift
//  ProjectHolos
//
//  Created by Ojas Sethi on 22/03/19.
//  Copyright © 2019 Ojas Sethi. All rights reserved.
//

import UIKit
class IndexedCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "collectionViewCellID"
    let label = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    //  MARK:   Functions
    func setLabelText(_ text: String) {
        self.label.frame = self.bounds
        self.label.text = text
        self.label.textAlignment = .center
        
        self.label.textColor = UIColor.white
        self.contentView.addSubview(label)
    }
}

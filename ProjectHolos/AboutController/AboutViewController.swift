//
//  AboutViewController.swift
//  ProjectHolos
//
//  Created by admin on 07/08/19.
//  Copyright © 2019 Ojas Sethi. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    //MARK:- Property and Variable
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    //MARK:- Action method
    @IBAction func back_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

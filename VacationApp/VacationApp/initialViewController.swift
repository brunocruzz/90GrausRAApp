//
//  initialViewController.swift
//  VacationApp
//
//  Created by Bruno Cruz on 27/12/17.
//  Copyright © 2017 Bruno Cruz. All rights reserved.
//

import UIKit

class initialViewController: UIViewController {

    @IBOutlet weak var scanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.scanButton.layer.cornerRadius = 7.0
        self.navigationController?.navigationBar.isHidden = true
    }

    @IBAction func goToCamera(_ sender: Any) {
        
        let storyboard = UIStoryboard(name:"Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "camera") as! ViewController
        
        self.navigationController?.pushViewController(nextVC, animated: true)
        
    }
    
}

//
//  ShareViewController.swift
//  VacationApp
//
//  Created by Bruno Cruz on 26/12/17.
//  Copyright © 2017 Bruno Cruz. All rights reserved.
//

import UIKit

class ShareViewController: UIViewController {

    var photo = UIImage()
    @IBOutlet weak var photoPreview: UIImageView!
    
    @IBOutlet weak var shareButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareButton.layer.cornerRadius = 7.0
        self.presentingViewController?.dismiss(animated: false, completion: nil)
        self.photoPreview.image = photo
    }


    @IBAction func cancelButton(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func shareImage(_ sender: Any) {
        
        let imageToShare = [ photo ]
        let activityViewController = UIActivityViewController(activityItems:imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
        

    }
}

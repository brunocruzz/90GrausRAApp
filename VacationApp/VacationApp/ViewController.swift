//
//  ViewController.swift
//  VacationApp
//
//  Created by Bruno Cruz on 14/12/17.
//  Copyright © 2017 Bruno Cruz. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var photoButton: UIButton!
    var firstLabel: UILabel!
    var secondLabel: UILabel!
    
    var detectedDataAnchor: ARAnchor?
    var processing: Bool!
    var modelName = "cup"
    var photo: UIImage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = false
        self.createPhotoButton()
        self.createBackButton()
        self.createFirstLabel()
    }
    
    func createPhotoButton(){
        
        let buttonSize:CGFloat = 70.0
        photoButton = UIButton(type: UIButtonType.custom)
        photoButton.frame = CGRect(x: ((self.view.frame.midX) - (buttonSize/2.0)), y: (self.view.frame.height*0.87), width: buttonSize, height: buttonSize)
        photoButton.setImage(UIImage.init(named: "cameraButton"), for: .normal)
        photoButton.setTitleShadowColor(UIColor.black, for: .normal)
        photoButton.addTarget(self, action:  #selector(goNextVc), for: .touchUpInside)
        photoButton.isHidden = true
        sceneView.addSubview(photoButton)
    }
    
    
    func createFirstLabel(){
        let labelSize = CGRect(x:self.view.frame.width*0.05, y: self.view.frame.height*0.25, width: self.view.frame.width*0.90, height: 100)
        firstLabel = UILabel(frame: labelSize)
        firstLabel.text = "Posicione a câmera em frente ao QrCode"
        firstLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 25)
        firstLabel.textColor = UIColor.white
        firstLabel.textAlignment = NSTextAlignment.center
        firstLabel.numberOfLines = 0
        sceneView.addSubview(firstLabel)
    }

    func createSecondLabel(){
        let labelSize = CGRect(x:self.view.frame.width*0.05, y: self.view.frame.height*0.25, width: self.view.frame.width*0.90, height: 100)
        secondLabel = UILabel(frame: labelSize)
        secondLabel.text = "Agora, aproveite e tire uma foto"
        secondLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 25)
        secondLabel.textColor = UIColor.white
        secondLabel.textAlignment = NSTextAlignment.center
        secondLabel.numberOfLines = 0
        sceneView.addSubview(secondLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.secondLabel.isHidden = true
        }
    }

    
    func createBackButton(){
        
        let buttonSize:CGFloat = 40.0
        let backButton = UIButton(type: UIButtonType.custom)
        backButton.frame = CGRect(x: 10, y: 34, width: buttonSize, height: buttonSize)
        backButton.setImage(UIImage.init(named: "backButton"), for: .normal)
        backButton.addTarget(self, action:  #selector(backRootView), for: .touchUpInside)
        sceneView.addSubview(backButton)
        
    }

    @objc func backRootView(){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func goNextVc(){

        let storyboard = UIStoryboard(name:"Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(withIdentifier: "shareImage") as! ShareViewController
        nextVC.photo = self.sceneView.snapshot()
        self.navigationController?.pushViewController(nextVC, animated: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.processing = false
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode() }
        sceneView.session.pause()
    }
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if self.processing {
            return
        }
        
        self.processing = true
        
        let request = VNDetectBarcodesRequest { (request, error) in
            
            if let results = request.results, let result = results.first as? VNBarcodeObservation {
                
                self.modelName = result.payloadStringValue!
                
                var rect = result.boundingBox
                rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
                rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
                let center = CGPoint(x: rect.midX, y: rect.midY)
                
        
                DispatchQueue.main.async {
                    
                    // Perform a hit test on the ARFrame to find a surface
                    let hitTestResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
                    
                    // If we have a result, process it
                    if let hitTestResult = hitTestResults.first {
                        
                        // If we already have an anchor, update the position of the attached node
                        if let detectedDataAnchor = self.detectedDataAnchor,
                            let node = self.sceneView.node(for: detectedDataAnchor) {
                            
                            node.transform = SCNMatrix4(hitTestResult.worldTransform)
                            
                        } else {
                            // Create an anchor. The node will be created in delegate methods
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                        }
                    }
                    
                    self.processing = false
                }
                
            } else {
                self.processing = false
            }
        }
        
        // Process the request in the background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                request.symbologies = [.QR]
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                try imageRequestHandler.perform([request])
            } catch {}
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        if self.detectedDataAnchor?.identifier == anchor.identifier {
            
            guard let virtualObjectScene = SCNScene(named: self.modelName + ".scn", inDirectory: "art.scnassets/" + self.modelName) else {
                return nil
            }
            
            let wrapperNode = SCNNode()
            
            for child in virtualObjectScene.rootNode.childNodes {
                child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                child.movabilityHint = .movable
                wrapperNode.addChildNode(child)
            }
            
            // Set its position based off the anchor
            wrapperNode.transform = SCNMatrix4(anchor.transform)
            DispatchQueue.main.async {
                self.photoButton.isHidden = false
                self.firstLabel.removeFromSuperview()
                self.createSecondLabel()
            }
            return wrapperNode
        }
        
        return nil
    }
}


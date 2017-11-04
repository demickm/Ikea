//
//  ViewController.swift
//  Ikea
//
//  Created by Demick McMullin on 10/21/17.
//  Copyright © 2017 Demick McMullin. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate {
  
    let itemArray: [String] = ["cup", "vase", "boxing", "table"]
    var selectedItem: String?
    
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var itemCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.registerGestureRecognizer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        }
    
    func registerGestureRecognizer() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecogjizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecogjizer)
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        if !hitTest.isEmpty {
            
            if let results = hitTest.first {
                let node = results.node
                let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
                node.runAction(pinchAction)
                sender.scale = 1.0 
            }
        }

    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        if !hitTest.isEmpty {
            if let hitTest = hitTest.first {
            addItem(hitTestResult: hitTest)
            print("touched a horizontal surface")
            }
        } else {
            print("You Suck")
        }
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if !hitTest.isEmpty {
            if let result = hitTest.first {
                if sender.state == .began {
                    let action = SCNAction.rotateBy(x: 0, y:CGFloat(360.degreesToRadians), z: 0, duration: 1)
                    let forever = SCNAction.repeatForever(action)
                    result.node.runAction(forever)
                } else if sender.state == .ended {
                      result.node.removeAllActions()
                    }
                }
            }
        }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
        let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            guard let node = scene?.rootNode.childNode(withName: selectedItem, recursively: false) else { return }
            let transform = hitTestResult.worldTransform
            let itemPosition = transform.columns.3 
            node.position = SCNVector3(itemPosition.x, itemPosition.y, itemPosition.z)
            if selectedItem == "table" {
                self.centerPivot(for: node)
            }
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as? ItemCollectionViewCell else { return UICollectionViewCell()}
        cell.itemLabel.text = itemArray[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {return}
        selectedItem = self.itemArray[indexPath.row]
        cell.backgroundColor = UIColor.green
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {return}
        cell.backgroundColor = UIColor.orange
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.planeDetected.isHidden = true
            }
        }
    }
    
    func centerPivot(for node: SCNNode) {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + (max.x - min.x)/2,
            min.y + (max.y - min.y)/2,
            min.z + (max.z - min.z)/2
        )
    }
    
    
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180 }
    
}



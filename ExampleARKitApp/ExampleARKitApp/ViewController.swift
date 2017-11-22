//
//  ViewController.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 11/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import UIKit
import Vision
import SceneKit
import ARKit

class ViewController: UIViewController {
  
  @IBOutlet fileprivate var sceneView: ARSCNView!
  @IBOutlet fileprivate var distanceLabel: UILabel!
  @IBOutlet fileprivate var addButton: UIButton!
  @IBOutlet fileprivate var confirmButton: UIButton!
  @IBOutlet fileprivate var instructionLabel: UILabel!
  @IBOutlet fileprivate var crosshairs: [UIView]!
  
  fileprivate var planes: [ARPlaneAnchor : SCNNode] = [:]
  fileprivate var squareNode: SCNNode?
  fileprivate var measuringTape: MeasuringTape?
  fileprivate var sphereNode: SCNNode?
  fileprivate var currentFaceView: UIView?
  fileprivate var shouldPollForFaces: Bool = false
  fileprivate var panGestureRecogniser: UIPanGestureRecognizer = UIPanGestureRecognizer()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self
    sceneView.showsStatistics = true
    confirmButton.isHidden = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    createAndStartNewSession()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  fileprivate func createAndStartNewSession() {
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    configuration.isLightEstimationEnabled = true
    
    // Run the view's session
    sceneView.session.run(configuration)
    sceneView.automaticallyUpdatesLighting = true
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    
    // Update instruction label UI
    instructionLabel.text = "Please move around your world to detect the floor"
  }
  
  @IBAction fileprivate func didTapReset() {
    distanceLabel.text = "Height: ?"
    addButton.isEnabled = true
    addButton.backgroundColor = .defaultOrange
    addButton.isHidden = false
    confirmButton.isHidden = true
    shouldPollForFaces = false
    for view in crosshairs {
      view.isHidden = false
    }
    
    for plane in planes {
      plane.value.removeFromParentNode()
    }
    planes.removeAll()
    
    squareNode?.removeFromParentNode()
    measuringTape?.removeFromParentNode()
    sphereNode?.removeFromParentNode()
    currentFaceView?.removeFromSuperview()
    
    squareNode = nil
    measuringTape = nil
    sphereNode = nil
    currentFaceView = nil
    
    sceneView.session.pause()
    view.removeGestureRecognizer(panGestureRecogniser)
    createAndStartNewSession()
  }
  
  @IBAction fileprivate func didTapAdd() {
    let point = CGPoint(x: view.frame.origin.x + (view.frame.width / 2), y: view.frame.origin.y + (view.frame.height / 2))
    let result = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
    if result.count == 0 {
      return
    }
    
    for view in crosshairs {
      view.isHidden = true
    }
    
    guard let hitResult = result.first else { return }
    insertReferenceNode(at: hitResult)
  }
  
  @IBAction fileprivate func didTapConfirm() {
    didConfirmFace()
  }
  
  fileprivate func insertReferenceNode(at hitResult: ARHitTestResult) {
    let box = SCNBox(width: 0.2, height: 0.0001, length: 0.2, chamferRadius: 0.0)
    box.firstMaterial?.diffuse.contents = UIColor.defaultOrange
    let node = SCNNode(geometry: box)
    
    node.position = SCNVector3Make(
      hitResult.worldTransform.columns.3.x,
      hitResult.worldTransform.columns.3.y,
      hitResult.worldTransform.columns.3.z
    )
    
    squareNode = node
    sceneView.scene.rootNode.addChildNode(node)
    
    addButton.isEnabled = false
    addButton.backgroundColor = UIColor.lightGray
    
    shouldPollForFaces = true
    
    instructionLabel.text = "Please point the camera at the person you would like to measure!"
  }
  
  func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
    // Create a SceneKit plane to visualize the node using its position and extent.
    let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
    plane.setAndScaleTexture()
    let planeNode = SCNNode(geometry: plane)
    planeNode.opacity = 0.3
    
    // SCNPlanes are vertically oriented in their local coordinate space.
    // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
    planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
    planes[anchor] = planeNode
    
    return planeNode
  }
  
  //Start face tracking
  @objc fileprivate func startFaceTracking() {
    guard let frame = self.sceneView.session.currentFrame else {
      print("No frame available")
      return
    }
    
    // Create and rotate image
    let image = CIImage(cvPixelBuffer: frame.capturedImage).rotate
    
    let facesRequest = VNDetectFaceRectanglesRequest { request, error in
      guard error == nil else {
        print("Face request error: \(error!.localizedDescription)")
        return
      }
      
      guard let observations = request.results as? [VNFaceObservation] else {
        print("No face observations")
        return
      }
      self.drawVisionRequestResults(observations)
    }
    
    try? VNImageRequestHandler(ciImage: image).perform([facesRequest])
  }
  
  func drawVisionRequestResults(_ results: [VNFaceObservation]) {
    print("Number of faces: \(results.count)")
    if results.count == 0 {
      currentFaceView?.removeFromSuperview()
    }
    
    guard let face = results.first else { return }
    let boundingBox = self.transformBoundingBox(face.boundingBox)
    didDetectFaceAt(boundingBox: boundingBox)
  }
  
  fileprivate func didDetectFaceAt(boundingBox: CGRect) {
    if (sphereNode != nil) { return }
    
    drawFrame(around: boundingBox)
    addButton.isHidden = true
    confirmButton.isHidden = false
    instructionLabel.text = "Face detected! Please confirm."
  }
  
  fileprivate func drawFrame(around rect: CGRect) {
    if let currentView = currentFaceView {
      currentView.removeFromSuperview()
    }
    
    let borderView = UIView()
    borderView.frame = CGRect(x: rect.origin.x, y: rect.origin.y - (rect.height / 4), width: rect.width, height: rect.height*1.5)
    
    borderView.backgroundColor = .clear
    borderView.layer.cornerRadius = 10
    borderView.layer.borderColor = UIColor.defaultOrange.cgColor
    borderView.layer.borderWidth = 2.0
    
    currentFaceView = borderView
    
    view.addSubview(borderView)
  }
  
  
  fileprivate func didConfirmFace() {
    instructionLabel.text = "Thanks! Pan up or down to adjust the position!"
    currentFaceView?.removeFromSuperview()
    
    guard let currentFaceFrame = currentFaceView?.frame else { return }
    let boundingBox = CGRect(x: currentFaceFrame.midX, y: currentFaceFrame.minY, width: 0.1, height: 0.1)
    guard let worldCoord = sceneView.determineWorldCoord(boundingBox) else { return }
    let sphere = SCNSphere(radius: 0.01)
    sphere.firstMaterial?.diffuse.contents = UIColor.defaultOrange
    let node = SCNNode(geometry: sphere)
    node.position = worldCoord
    
    sceneView.scene.rootNode.addChildNode(node)
    sphereNode = node
    
    calculateHeight()
    
    addPanGestureRecogniser()
  }
  
  fileprivate func calculateHeight() {
    guard let squareNode = squareNode,
      let sphereNode = sphereNode else { return }
    let distance = sphereNode.position.verticalDistance(endPosition: squareNode.position)
    let distanceString = String(format: "%.2f", distance)
    distanceLabel.text = "Height: \(distanceString)m"
    
    if let node = measuringTape {
      node.removeFromParentNode()
    }
    let toVector = SCNVector3Make(sphereNode.position.x, squareNode.position.y, sphereNode.position.z)
    measuringTape = MeasuringTape(parent: sceneView.scene.rootNode, startPoint: sphereNode.position, endPoint: toVector)
    guard let measuringTape = measuringTape else { return }
    sceneView.scene.rootNode.addChildNode(measuringTape)
  }
  
  fileprivate func addPanGestureRecogniser()  {
    panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(didPan(recogniser:)))
    view.addGestureRecognizer(panGestureRecogniser)
  }
  
  @objc fileprivate func didPan(recogniser: UIPanGestureRecognizer) {
    let translation = recogniser.translation(in: view)
    guard let spherePosition = sphereNode?.position else { return }
    sphereNode?.position = SCNVector3Make(spherePosition.x, spherePosition.y - Float(translation.y / 2000), spherePosition.z)
    calculateHeight()
  }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
  
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    if shouldPollForFaces {
      DispatchQueue.main.async {
        self.startFaceTracking()
      }
    }
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    // This visualization covers only detected planes.
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    let planeNode = createPlaneNode(anchor: planeAnchor)
    
    // ARKit owns the node corresponding to the anchor, so make the plane a child node.
    node.addChildNode(planeNode)
    DispatchQueue.main.async {
      self.instructionLabel.text = "Floor detected! Please place a reference point!"
    }
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor,
    let plane = planes[planeAnchor] else { return }
    
    let newPlane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    newPlane.setAndScaleTexture()
    plane.geometry = newPlane
    plane.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.y)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    // Remove existing plane nodes
    planes[planeAnchor]?.removeFromParentNode()
  }
}

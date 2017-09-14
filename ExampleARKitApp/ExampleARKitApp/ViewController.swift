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
  @IBOutlet fileprivate var instructionLabel: UILabel!
  
  fileprivate var planes: [ARPlaneAnchor : SCNNode] = [:]
  fileprivate var squareNode: SCNNode?
  fileprivate var cylinderNode: CylinderLine?
  fileprivate var currentFaceView: UIView?
  fileprivate var pollingTimer: Timer?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self
    sceneView.showsStatistics = true
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
    sceneView.debugOptions = [.showWireframe]
  }
  
  @IBAction fileprivate func didTapReset() {
    distanceLabel.text = "Height: ?"
    addButton.isEnabled = true
    addButton.backgroundColor = UIColor(red: 234 / 256, green: 101 / 256, blue: 0 / 256, alpha: 1)
    
    if let node = squareNode {
      node.removeFromParentNode()
    }
    squareNode = nil
    
    if let node = cylinderNode {
      node.removeFromParentNode()
    }
  }
  
  @IBAction fileprivate func didTapAdd() {
    let point = CGPoint(x: view.frame.origin.x + (view.frame.width / 2), y: view.frame.origin.y + (view.frame.height / 2))
    //    let point = center.
    let result = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
    if result.count == 0 {
      return
    }
    
    let hitResult = result.first
    insertGeomerty(hitResult!) //UNCOMMENT TO ADD NODES
  }
  
  fileprivate func startPollingForFaceDetection() {
    DispatchQueue.main.async {
      if self.instructionLabel.alpha == 0.0 {
        self.instructionLabel.text = "Floor detected! Please focus on the face of the person you would like to measure!"
        self.instructionLabel.showViewWithAnimation()
        self.pollingTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.startFaceTracking), userInfo: nil, repeats: true)
      }
    }
  }
  
  fileprivate func stopPollingForFaceDetection() {
    pollingTimer?.invalidate()
  }
  
  fileprivate func insertGeomerty(_ hitResult: ARHitTestResult) {
    let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0.0)
    let node = SCNNode(geometry: box)
    
    node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
    node.physicsBody?.mass = 2.0
    node.position = SCNVector3Make(
      hitResult.worldTransform.columns.3.x,
      hitResult.worldTransform.columns.3.y,
      hitResult.worldTransform.columns.3.z
    )
    
    squareNode = node
    sceneView.scene.rootNode.addChildNode(node)
    
    addButton.isEnabled = false
    addButton.backgroundColor = UIColor.lightGray
  }
  
  func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
    // Create a SceneKit plane to visualize the node using its position and extent.
    let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
    let material = SCNMaterial()
    material.colorBufferWriteMask = []
    plane.materials = [material]
    
    let planeNode = SCNNode(geometry: plane)
    
    // SCNPlanes are vertically oriented in their local coordinate space.
    // Rotate it to match the horizontal orientation of the ARPlaneAnchor.
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
    planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
    planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: plane, options: nil))
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
    if results.count > 0 {
      stopPollingForFaceDetection() // TODO
      DispatchQueue.main.async {
        self.instructionLabel.hideViewWithAnimation()
        self.stopPollingForFaceDetection()
      }
    }
    
    guard let face = results.first else { return }
    let topBoundingBox = CGRect(x: face.boundingBox.origin.x, y: face.boundingBox.origin.y + (face.boundingBox.height / 3), width: face.boundingBox.width, height: face.boundingBox.height)
    let boundingBox = self.transformBoundingBox(topBoundingBox)
    guard let worldCoord = self.normalizeWorldCoord(boundingBox) else { return }
    drawNodeAround(worldCoord: worldCoord, boundingBox: boundingBox)
  }
  
  fileprivate func drawNodeAround(worldCoord: SCNVector3, boundingBox: CGRect) {
    let sphere = SCNSphere(radius: 0.004)
    sphere.firstMaterial?.diffuse.contents = UIColor.gray
    let sphereNode = SCNNode(geometry: sphere)
    sphereNode.opacity = 0.6
    
    sphereNode.position = SCNVector3Make(worldCoord.x, worldCoord.y, worldCoord.z)
    sceneView.scene.rootNode.addChildNode(sphereNode)
    
    guard let squareNode = squareNode else { return }
    let distance = sphereNode.position.verticalDistance(endPosition: squareNode.position)
    let distanceString = String(format: "%.2f", distance)
    distanceLabel.text = "Height: \(distanceString)m"
    
    let toVector = SCNVector3Make(sphereNode.position.x, squareNode.position.y, sphereNode.position.z)
    cylinderNode = CylinderLine(parent: sceneView.scene.rootNode, v1: sphereNode.position, v2: toVector, radius: 0.001, radSegmentCount: 6, color: .red)
    sceneView.scene.rootNode.addChildNode(cylinderNode!)
  }
  
  /// In order to get stable vectors, we determine multiple coordinates within an interval.
  ///
  /// - Parameters:
  ///   - boundingBox: Rect of the face on the screen
  /// - Returns: the normalized vector
  private func normalizeWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
    
    var array: [SCNVector3] = []
    Array(0...2).forEach{_ in
      if let position = determineWorldCoord(boundingBox) {
        array.append(position)
      }
      usleep(12000) // .012 seconds
    }
    
    if array.isEmpty {
      return nil
    }
    
    return SCNVector3.center(array)
  }
  
  /// Determine the vector from the position on the screen.
  ///
  /// - Parameter boundingBox: Rect of the face on the screen
  /// - Returns: the vector in the sceneView
  private func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
    let arHitTestResults = sceneView.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
    
    // Filter results that are to close
    if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
      return SCNVector3.positionFromTransform(closestResult.worldTransform)
    }
    return nil
  }
  
  /// Transform bounding box according to device orientation
  ///
  /// - Parameter boundingBox: of the face
  /// - Returns: transformed bounding box
  private func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
    var size: CGSize
    var origin: CGPoint
    
    switch UIDevice.current.orientation {
    case .landscapeLeft:
      size = CGSize(width: boundingBox.width * self.view.bounds.height,
                    height: boundingBox.height * self.view.bounds.width)
      origin = CGPoint(x: boundingBox.minY * self.view.bounds.width,
                       y: boundingBox.minX * self.view.bounds.height)
    case .landscapeRight:
      size = CGSize(width: boundingBox.width * self.view.bounds.height,
                    height: boundingBox.height * self.view.bounds.width)
      origin = CGPoint(x: (1 - boundingBox.maxY) * self.view.bounds.width,
                       y: (1 - boundingBox.maxX) * self.view.bounds.height)
    case .portraitUpsideDown:
      size = CGSize(width: boundingBox.width * self.view.bounds.width,
                    height: boundingBox.height * self.view.bounds.height)
      origin = CGPoint(x: (1 - boundingBox.maxX) * self.view.bounds.width,
                       y: boundingBox.minY * self.view.bounds.height)
    default:
      size = CGSize(width: boundingBox.width * self.view.bounds.width,
                    height: boundingBox.height * self.view.bounds.height)
      origin = CGPoint(x: boundingBox.minX * self.view.bounds.width,
                       y: (1 - boundingBox.maxY) * self.view.bounds.height)
    }
    
    return CGRect(origin: origin, size: size)
  }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    // This visualization covers only detected planes.
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    let planeNode = createPlaneNode(anchor: planeAnchor)
    
    // ARKit owns the node corresponding to the anchor, so make the plane a child node.
    node.addChildNode(planeNode)
    print("Added plane. Now starting face detection.")
    
    DispatchQueue.main.async {
      if self.instructionLabel.alpha == 1.0 {
        self.instructionLabel.hideViewWithAnimation()
      }
    }
    
    startPollingForFaceDetection()
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    // Remove existing plane nodes
    planes[planeAnchor]?.removeFromParentNode()
    
    
    let planeNode = createPlaneNode(anchor: planeAnchor)
    
    node.addChildNode(planeNode)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    // Remove existing plane nodes
    planes[planeAnchor]?.removeFromParentNode()
  }
}

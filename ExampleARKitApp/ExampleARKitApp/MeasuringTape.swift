//
//  MeasuringTape.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 13/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import Foundation
import SceneKit

class MeasuringTape: SCNNode {
  
  private let newParent: SCNNode?
  private let startPoint: SCNVector3?
  private let endPoint: SCNVector3?
  private let oneCentimeter: CGFloat = 0.01
  
  init(parent: SCNNode, startPoint: SCNVector3, endPoint: SCNVector3) {
    self.newParent = parent
    self.startPoint = startPoint
    self.endPoint = endPoint
    super.init()
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    guard let startPoint = startPoint,
      let endPoint = endPoint else { return }
    position = startPoint
    let nodeV2 = SCNNode()
    nodeV2.position = endPoint
    newParent?.addChildNode(nodeV2)
    
    configureTapeNodes()
    
    constraints = [SCNLookAtConstraint(target: nodeV2)]
  }
  
  private func configureTapeNodes() {
    guard let startPoint = startPoint,
      let endPoint = endPoint else { return }
    let  height = startPoint.distanceFrom(endPosition: endPoint)
    let zAlign = SCNNode()
    zAlign.eulerAngles.x = .pi / 2
    
    let heightInCm = height*100
    let roundedDownHeight = ceil(heightInCm)
    guard roundedDownHeight > 0 else { return }
    for i in 1...Int(roundedDownHeight) {
      let plane = SCNBox(width: oneCentimeter, height: oneCentimeter, length: 0.001, chamferRadius: 0)
      plane.firstMaterial?.diffuse.contents = UIImage(named: "MeasureTape")
      let planeNode = SCNNode(geometry: plane)
      let multiplier = CGFloat(i - 1)
      let offset = (multiplier * oneCentimeter) + (oneCentimeter / 2)
      planeNode.position.y = Float(-(height) + Float(offset))
      zAlign.addChildNode(planeNode)
    }
    
    addChildNode(zAlign)
  }
}

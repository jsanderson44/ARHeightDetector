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
  
  init(parent: SCNNode, startPoint: SCNVector3, endPoint: SCNVector3, width: CGFloat = 0.01) {
    super.init()
    
    //Calculate the height of our line
    let  height = startPoint.distanceFrom(endPosition: endPoint)
    
    //set position to v1 coordonate
    position = startPoint
    
    //Create the second node to draw direction vector
    let nodeV2 = SCNNode()
    
    //define his position
    nodeV2.position = endPoint
    //add it to parent
    parent.addChildNode(nodeV2)
    
    //Align Z axis
    let zAlign = SCNNode()
    zAlign.eulerAngles.x = .pi / 2
    
    //create our cylinder
    let heightInCm = height*100
    let roundedDownHeight = floor(heightInCm)
    guard roundedDownHeight > 0 else { return }
    for i in 1...Int(roundedDownHeight) {
        let plane = SCNBox(width: width, height: 0.01, length: 0.001, chamferRadius: 0)
        plane.firstMaterial?.diffuse.contents = UIImage(named: "MeasureTape")
        let planeNode = SCNNode(geometry: plane)
        let offset = (Double(i-1) * 0.01) + 0.005 //TODO
        planeNode.position.y = Float(-(height/2))// + Float(offset))
        zAlign.addChildNode(planeNode)
    }

    //Add it to child
    addChildNode(zAlign)
    
    //set constraint direction to our vector
    constraints = [SCNLookAtConstraint(target: nodeV2)]
  }
  
  override init() {
    super.init()
  }
    
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

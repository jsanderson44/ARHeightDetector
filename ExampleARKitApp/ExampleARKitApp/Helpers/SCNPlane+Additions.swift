//
//  SCNPlane+Additions.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 18/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

extension SCNPlane {
  
  func setAndScaleTexture() {
    guard let material = firstMaterial else { return }
    material.diffuse.contents = UIImage(named: "grid")
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(boundingBox.min.x, boundingBox.min.y, 1)
    material.diffuse.wrapS = .repeat
    material.diffuse.wrapT = .repeat
    firstMaterial = material
  }
}

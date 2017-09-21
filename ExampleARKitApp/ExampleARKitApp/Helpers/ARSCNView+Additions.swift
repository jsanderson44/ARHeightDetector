//
//  ARSCNView+Additions.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 18/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import UIKit

extension ARSCNView {
  
  /// Determine the vector from the position on the screen.
  ///
  /// - Parameter boundingBox: Rect of the face on the screen
  /// - Returns: the vector in the sceneView
 func determineWorldCoord(_ boundingBox: CGRect) -> SCNVector3? {
    let arHitTestResults = self.hitTest(CGPoint(x: boundingBox.midX, y: boundingBox.midY), types: [.featurePoint])
    
    // Filter results that are to close
    if let closestResult = arHitTestResults.filter({ $0.distance > 0.10 }).first {
      return SCNVector3.positionFromTransform(closestResult.worldTransform)
    }
    return nil
  }
}

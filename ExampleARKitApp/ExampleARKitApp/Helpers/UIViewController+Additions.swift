//
//  UIViewController+Additions.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 18/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
  
  /// Transform bounding box according to device orientation
  ///
  /// - Parameter boundingBox: of the face
  /// - Returns: transformed bounding box
 func transformBoundingBox(_ boundingBox: CGRect) -> CGRect {
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

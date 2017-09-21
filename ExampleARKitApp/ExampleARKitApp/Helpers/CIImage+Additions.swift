//
//  CIImage+Additions.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 13/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import Foundation
import ARKit
import Vision

import Foundation
import Vision
import ARKit

public extension CIImage {
  
  var rotate: CIImage {
    get {
      return self.oriented(UIDevice.current.orientation.cameraOrientation())
    }
  }
}

private extension UIDeviceOrientation {
  func cameraOrientation() -> CGImagePropertyOrientation {
    switch self {
    case .landscapeLeft: return .up
    case .landscapeRight: return .down
    case .portraitUpsideDown: return .left
    default: return .right
    }
  }
}

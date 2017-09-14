//
//  UIView+Additions.swift
//  ExampleARKitApp
//
//  Created by John Sanderson on 14/09/2017.
//  Copyright © 2017 The App Business. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
  func hideViewWithAnimation() {
    UIView.animate(withDuration: 0.3, animations: {
      self.alpha = 0.0
    })
  }
  
  func showViewWithAnimation() {
    UIView.animate(withDuration: 0.3, animations: {
      self.alpha = 1.0
    })
  }
}

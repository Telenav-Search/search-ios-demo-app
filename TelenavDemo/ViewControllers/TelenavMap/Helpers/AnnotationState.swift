//
//  AnnotationState.swift
//  TelenavDemo
//
//  Created by Sergey Zubkov on 26.11.2021.
//

import Foundation
import VividDriveSessionSDK

class AnnotationState {
  var isSelected = false
  var annotation: VNAnnotation
  
  init(isSelected: Bool, annotation: VNAnnotation) {
    self.isSelected = isSelected
    self.annotation = annotation
  }
}

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
  var annotaton: VNAnnotation
  
  init(isSelected: Bool, annotaton: VNAnnotation) {
    self.isSelected = isSelected
    self.annotaton = annotaton
  }
}

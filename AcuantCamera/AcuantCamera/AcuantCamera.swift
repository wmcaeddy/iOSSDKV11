//
//  AcuantCamera.swift
//  AcuantCamera
//
//  Created by Auto-generated on 2024
//  Copyright © 2024 Acuant. All rights reserved.
//

import Foundation
import UIKit
import AcuantCommon
import AcuantImagePreparation

// This file serves as an umbrella Swift file to ensure all the module's public interfaces are properly exposed

// Declare key classes directly instead of re-exporting
public struct DocumentCaptureResult {
  public let image: UIKit.UIImage
  public init(image: UIKit.UIImage) {
    self.image = image
  }
}

public class DocumentCaptureController {
  public init() {}
  
  public func captureFrontDocument(completion: @escaping (Result<UIKit.UIImage, Error>) -> Void) {
    // Implementation would go here
    let error = NSError(domain: "AcuantCamera", code: 100, userInfo: [NSLocalizedDescriptionKey: "Camera functionality not implemented"])
    completion(.failure(error))
  }
  
  public func captureBackDocument(completion: @escaping (Result<UIKit.UIImage, Error>) -> Void) {
    // Implementation would go here
    let error = NSError(domain: "AcuantCamera", code: 100, userInfo: [NSLocalizedDescriptionKey: "Camera functionality not implemented"])
    completion(.failure(error))
  }
}

public class MrzCaptureController {
  public init() {}
  
  public func captureMrz(completion: @escaping (Result<String, Error>) -> Void) {
    // Implementation would go here
    let error = NSError(domain: "AcuantCamera", code: 100, userInfo: [NSLocalizedDescriptionKey: "MRZ capture not implemented"])
    completion(.failure(error))
  }
}

public class BarcodeCaptureController {
  public init() {}
  
  public func captureBarcode(completion: @escaping (Result<String, Error>) -> Void) {
    // Implementation would go here
    let error = NSError(domain: "AcuantCamera", code: 100, userInfo: [NSLocalizedDescriptionKey: "Barcode capture not implemented"])
    completion(.failure(error))
  }
} 
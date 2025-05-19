import Flutter
import UIKit
import AcuantiOSSDKV11
import AcuantCommon

public class SwiftAcuantFlutterPlugin: NSObject, FlutterPlugin {
  private var viewController: UIViewController?
  private var result: FlutterResult?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "acuant_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftAcuantFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Get viewController
    if let viewController = UIApplication.shared.delegate?.window??.rootViewController {
        instance.viewController = viewController
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    self.result = result
    
    switch call.method {
    case "initialize":
        initialize(call, result: result)
    case "captureFrontDocument":
        captureFrontDocument()
    case "captureBackDocument":
        captureBackDocument()
    case "captureFace":
        captureFace()
    case "processDocument":
        processDocument(call, result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
  }
  
  private func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let username = args["username"] as? String,
          let password = args["password"] as? String,
          let subscription = args["subscription"] as? String,
          let endpoints = args["endpoints"] as? [String: String] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
        return
    }
    
    // Create Endpoints from the provided data
    let acuantEndpoint = Endpoints()
    if let frm = endpoints["frm_endpoint"] {
        acuantEndpoint.frmEndpoint = frm
    }
    if let passive = endpoints["passive_liveness_endpoint"] {
        acuantEndpoint.passiveLivenessEndpoint = passive
    }
    if let med = endpoints["med_endpoint"] {
        acuantEndpoint.medEndpoint = med
    }
    if let assureid = endpoints["assureid_endpoint"] {
        acuantEndpoint.assureIDEndpoint = assureid
    }
    if let acas = endpoints["acas_endpoint"] {
        acuantEndpoint.acasEndpoint = acas
    }
    if let ozone = endpoints["ozone_endpoint"] {
        acuantEndpoint.ozoneEndpoint = ozone
    }

    // Initialize Acuant SDK
    Credential.setUsername(username)
    Credential.setPassword(password)
    Credential.setSubscription(subscription)
    
    let initCallback = InitializationHandler()
    initCallback.onSuccess = {
        result(["success": true, "message": "Acuant SDK initialized successfully"])
    }
    initCallback.onFail = { error, description in
        result(FlutterError(code: "INITIALIZATION_FAILED", message: description, details: nil))
    }
    
    Initializer.initializeWithToken(credentials: Credential.getCredentials(), endpoints: acuantEndpoint, handler: initCallback)
  }
  
  private func captureFrontDocument() {
    guard let viewController = self.viewController else {
        self.result?(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
        return
    }
    
    DispatchQueue.main.async {
        let cameraController = DocumentCameraController.getCameraController(delegate: self)
        cameraController.cameraOptions.autoCapture = true
        cameraController.cameraOptions.hideNavigationBar = false
        cameraController.cameraOptions.documentType = .id1
        cameraController.cameraOptions.allowBox = true
        
        viewController.present(cameraController, animated: true, completion: nil)
    }
  }
  
  private func captureBackDocument() {
    guard let viewController = self.viewController else {
        self.result?(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
        return
    }
    
    DispatchQueue.main.async {
        let cameraController = DocumentCameraController.getCameraController(delegate: self)
        cameraController.cameraOptions.autoCapture = true
        cameraController.cameraOptions.hideNavigationBar = false
        cameraController.cameraOptions.documentType = .id1
        cameraController.cameraOptions.allowBox = true
        cameraController.cameraOptions.isBackSide = true
        
        viewController.present(cameraController, animated: true, completion: nil)
    }
  }
  
  private func captureFace() {
    guard let viewController = self.viewController else {
        self.result?(FlutterError(code: "NO_VIEWCONTROLLER", message: "Unable to get view controller", details: nil))
        return
    }
    
    DispatchQueue.main.async {
        let cameraController = FaceCameraController.getCameraController(delegate: self)
        viewController.present(cameraController, animated: true, completion: nil)
    }
  }
  
  private func processDocument(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let frontImagePath = args["frontImagePath"] as? String,
          let backImagePath = args["backImagePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required image paths", details: nil))
        return
    }
    
    // Load images from paths
    guard let frontImage = UIImage(contentsOfFile: frontImagePath),
          let backImage = UIImage(contentsOfFile: backImagePath) else {
        result(FlutterError(code: "IMAGE_LOAD_FAILED", message: "Failed to load images from paths", details: nil))
        return
    }
    
    // Create document instance
    let processingHandler = ProcessingHandler()
    processingHandler.onSuccess = { responseData in
        var resultData: [String: Any] = [:]
        
        // Extract fields from the responseData
        if let fields = responseData.fields {
            var extractedFields: [String: String] = [:]
            for field in fields {
                if let name = field.name, let value = field.value {
                    extractedFields[name] = value
                }
            }
            resultData["fields"] = extractedFields
        }
        
        resultData["success"] = true
        resultData["authenticationResult"] = responseData.authenticationResult?.rawValue ?? 0
        
        result(resultData)
    }
    
    processingHandler.onFail = { error, description in
        result(FlutterError(code: "PROCESSING_FAILED", message: description, details: nil))
    }
    
    // Create document instance and process
    let document = DocumentProcessor.createInstance()
    document.frontImage = frontImage
    document.backImage = backImage
    DocumentProcessor.processDocument(document: document, options: ProcessingOptions(), handler: processingHandler)
  }
}

// MARK: - DocumentCameraControllerDelegate
extension SwiftAcuantFlutterPlugin: DocumentCameraControllerDelegate {
    public func documentCameraControllerDidCancel(_ controller: UIViewController) {
        controller.dismiss(animated: true, completion: nil)
        self.result?(FlutterError(code: "USER_CANCELLED", message: "User cancelled the capture", details: nil))
    }
    
    public func documentCameraController(_ controller: UIViewController, didCapture image: UIImage, barcodeString: String?) {
        controller.dismiss(animated: true, completion: nil)
        
        // Save image to temp directory and return the path
        if let imagePath = saveImageToTemp(image: image) {
            self.result?(["imagePath": imagePath, "barcodeString": barcodeString ?? ""])
        } else {
            self.result?(FlutterError(code: "SAVE_FAILED", message: "Failed to save captured image", details: nil))
        }
    }
    
    private func saveImageToTemp(image: UIImage) -> String? {
        let fileName = "acuant_\(UUID().uuidString).jpg"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        if let imageData = image.jpegData(compressionQuality: 0.9) {
            do {
                try imageData.write(to: fileURL)
                return fileURL.path
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        return nil
    }
}

// MARK: - FaceCameraControllerDelegate
extension SwiftAcuantFlutterPlugin: FaceCameraControllerDelegate {
    public func faceCameraControllerDidCancel(_ controller: UIViewController) {
        controller.dismiss(animated: true, completion: nil)
        self.result?(FlutterError(code: "USER_CANCELLED", message: "User cancelled the face capture", details: nil))
    }
    
    public func faceCameraController(_ controller: UIViewController, didCapture image: UIImage) {
        controller.dismiss(animated: true, completion: nil)
        
        if let imagePath = saveImageToTemp(image: image) {
            self.result?(["imagePath": imagePath])
        } else {
            self.result?(FlutterError(code: "SAVE_FAILED", message: "Failed to save captured face image", details: nil))
        }
    }
} 
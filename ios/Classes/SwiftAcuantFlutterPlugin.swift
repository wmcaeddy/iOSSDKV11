import Flutter
import UIKit
import AVFoundation
// import AcuantCommon
// import AcuantDocumentProcessing
// import AcuantFaceMatch
// import AcuantImagePreparation
// import AcuantCamera
// import AcuantFaceCapture

// Local implementation of AcuantCommon classes
class AcuantCredentials {
  let username: String
  let password: String
  let subscription: String
  
  init(username: String, password: String, subscription: String) {
    self.username = username
    self.password = password
    self.subscription = subscription
  }
}

class AcuantEndpoints {
  var frmEndpoint: String = "https://frm.acuant.net"
  var passiveLivenessEndpoint: String = "https://us.passlive.acuant.net"
  var medEndpoint: String = "https://medicscan.acuant.net"
  var assureidEndpoint: String = "https://services.assureid.net"
  var acasEndpoint: String = "https://acas.acuant.net"
  var ozoneEndpoint: String = "https://ozone.acuant.net"
}

class AcuantCommon {
  static let version = "11.6.5"
  
  static func initialize(credentials: AcuantCredentials, endpoints: [String: String], completion: @escaping (Bool, Error?) -> Void) {
    // Simulate successful initialization
    completion(true, nil)
  }
}

// Camera controller for document and face capture
class CameraController: NSObject, AVCapturePhotoCaptureDelegate {
  private var captureSession: AVCaptureSession?
  private var currentCamera: AVCaptureDevice?
  private var photoOutput: AVCapturePhotoOutput?
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var completionHandler: ((Result<UIImage, Error>) -> Void)?
  private var cameraView: UIView?
  private var overlayView: UIView?
  private var captureButton: UIButton?
  private var cameraVC: UIViewController?
  private var captureCompletion: ((Result<UIImage, Error>) -> Void)?
  
  func setupCamera(on view: UIView, completion: @escaping (Bool) -> Void) {
    cameraView = view
    
    // Initialize capture session
    captureSession = AVCaptureSession()
    captureSession?.beginConfiguration()
    
    // Set session preset
    if captureSession?.canSetSessionPreset(.photo) == true {
      captureSession?.sessionPreset = .photo
    } else {
      captureSession?.sessionPreset = .high
    }
    
    // Get camera device
    guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      print("Failed to get back camera")
      completion(false)
      return
    }
    
    currentCamera = backCamera
    
    do {
      // Create device input
      let input = try AVCaptureDeviceInput(device: backCamera)
      
      // Create photo output
      photoOutput = AVCapturePhotoOutput()
      photoOutput?.isHighResolutionCaptureEnabled = true
      
      if captureSession?.canAddInput(input) == true,
         captureSession?.canAddOutput(photoOutput!) == true {
        
        captureSession?.addInput(input)
        captureSession?.addOutput(photoOutput!)
        
        captureSession?.commitConfiguration()
        
        // Setup preview layer
        setupPreviewLayer(on: view)
        
        // Setup overlay
        setupOverlay(on: view)
        
        completion(true)
      } else {
        print("Failed to add input/output to session")
        completion(false)
      }
    } catch {
      print("Error setting up camera: \(error.localizedDescription)")
      completion(false)
    }
  }
  
  private func setupPreviewLayer(on view: UIView) {
    // Create and configure preview layer
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
    previewLayer?.videoGravity = .resizeAspectFill
    previewLayer?.frame = view.layer.bounds
    
    // Add preview layer to view
    if let previewLayer = previewLayer {
      view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    // Add document frame overlay
    addDocumentFrameOverlay(to: view)
  }
  
  private func addDocumentFrameOverlay(to view: UIView) {
    // Create overlay view
    let overlayView = UIView(frame: view.bounds)
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    overlayView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(overlayView)
    
    NSLayoutConstraint.activate([
      overlayView.topAnchor.constraint(equalTo: view.topAnchor),
      overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    
    // Create document frame cutout
    let documentWidth = view.bounds.width * 0.8
    let documentHeight = documentWidth * 0.63 // ID card aspect ratio
    let documentX = (view.bounds.width - documentWidth) / 2
    let documentY = (view.bounds.height - documentHeight) / 2
    
    let documentRect = CGRect(x: documentX, y: documentY, width: documentWidth, height: documentHeight)
    
    // Create mask layer
    let maskLayer = CAShapeLayer()
    let path = UIBezierPath(rect: view.bounds)
    path.append(UIBezierPath(roundedRect: documentRect, cornerRadius: 10).reversing())
    maskLayer.path = path.cgPath
    overlayView.layer.mask = maskLayer
    
    // Add border around document frame
    let borderLayer = CAShapeLayer()
    borderLayer.path = UIBezierPath(roundedRect: documentRect, cornerRadius: 10).cgPath
    borderLayer.strokeColor = UIColor.white.cgColor
    borderLayer.fillColor = UIColor.clear.cgColor
    borderLayer.lineWidth = 3
    overlayView.layer.addSublayer(borderLayer)
    
    // Add instruction label
    let instructionLabel = UILabel()
    instructionLabel.text = "Position document within frame"
    instructionLabel.textColor = .white
    instructionLabel.textAlignment = .center
    instructionLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(instructionLabel)
    
    NSLayoutConstraint.activate([
      instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
      instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
      instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
    ])
  }
  
  private func setupOverlay(on view: UIView) {
    // Create overlay for document capture guidance
    overlayView = UIView(frame: view.bounds)
    overlayView?.backgroundColor = UIColor.clear
    
    // Create a transparent rectangle in the middle
    let overlayPath = UIBezierPath(rect: view.bounds)
    let width = view.bounds.width * 0.9
    let height = width * 0.63 // ID card aspect ratio
    let x = (view.bounds.width - width) / 2
    let y = (view.bounds.height - height) / 2
    let transparentPath = UIBezierPath(rect: CGRect(x: x, y: y, width: width, height: height))
    overlayPath.append(transparentPath)
    overlayPath.usesEvenOddFillRule = true
    
    let fillLayer = CAShapeLayer()
    fillLayer.path = overlayPath.cgPath
    fillLayer.fillRule = .evenOdd
    fillLayer.fillColor = UIColor(white: 0, alpha: 0.5).cgColor
    overlayView?.layer.addSublayer(fillLayer)
    
    // Add border around the transparent rectangle
    let borderLayer = CAShapeLayer()
    borderLayer.path = transparentPath.cgPath
    borderLayer.strokeColor = UIColor.white.cgColor
    borderLayer.fillColor = UIColor.clear.cgColor
    borderLayer.lineWidth = 2.0
    overlayView?.layer.addSublayer(borderLayer)
    
    // Add instruction label
    let instructionLabel = UILabel()
    instructionLabel.text = "Position document within the frame"
    instructionLabel.textColor = .white
    instructionLabel.textAlignment = .center
    instructionLabel.frame = CGRect(x: 0, y: y + height + 20, width: view.bounds.width, height: 30)
    overlayView?.addSubview(instructionLabel)
    
    // Add capture button
    captureButton = UIButton(type: .system)
    captureButton?.setTitle("Capture", for: .normal)
    captureButton?.setTitleColor(.white, for: .normal)
    captureButton?.backgroundColor = UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0)
    captureButton?.layer.cornerRadius = 25
    captureButton?.frame = CGRect(x: (view.bounds.width - 150) / 2, y: view.bounds.height - 100, width: 150, height: 50)
    captureButton?.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    
    overlayView?.addSubview(captureButton!)
    view.addSubview(overlayView!)
  }
  
  func setupFaceCapture(on view: UIView) {
    // Modify overlay for face capture
    if let instructionLabel = overlayView?.subviews.first(where: { $0 is UILabel }) as? UILabel {
      instructionLabel.text = "Position face within the frame"
    }
    
    // Create circular mask for face
    if let fillLayer = overlayView?.layer.sublayers?.first as? CAShapeLayer {
      let overlayPath = UIBezierPath(rect: view.bounds)
      let diameter = view.bounds.width * 0.7
      let x = (view.bounds.width - diameter) / 2
      let y = (view.bounds.height - diameter) / 2
      let transparentPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: diameter, height: diameter))
      overlayPath.append(transparentPath)
      overlayPath.usesEvenOddFillRule = true
      
      fillLayer.path = overlayPath.cgPath
    }
    
    // Update border to circular
    if let borderLayer = overlayView?.layer.sublayers?[1] as? CAShapeLayer {
      let diameter = view.bounds.width * 0.7
      let x = (view.bounds.width - diameter) / 2
      let y = (view.bounds.height - diameter) / 2
      let transparentPath = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: diameter, height: diameter))
      
      borderLayer.path = transparentPath.cgPath
    }
  }
  
  private func startSession() {
    if let captureSession = captureSession, !captureSession.isRunning {
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.captureSession?.startRunning()
      }
    }
  }
  
  private func stopSession() {
    if let captureSession = captureSession, captureSession.isRunning {
      captureSession.stopRunning()
    }
  }
  
  @objc func capturePhoto() {
    guard let photoOutput = photoOutput else {
      completionHandler?(.failure(NSError(domain: "CameraController", code: 104, userInfo: [NSLocalizedDescriptionKey: "Photo output not available"])))
      return
    }
    
    let settings = AVCapturePhotoSettings()
    settings.flashMode = .auto
    
    photoOutput.capturePhoto(with: settings, delegate: self)
  }
  
  // MARK: - AVCapturePhotoCaptureDelegate
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
      captureCompletion?(.failure(error))
      return
    }
    
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else {
      captureCompletion?(.failure(NSError(domain: "CameraController", code: 105, userInfo: [NSLocalizedDescriptionKey: "Failed to process captured image"])))
      return
    }
    
    // Stop the session and dismiss the camera view controller
    stopSession()
    cameraVC?.dismiss(animated: true) { [weak self] in
      self?.captureCompletion?(.success(image))
    }
  }
  
  func captureImage(completion: @escaping (Result<UIImage, Error>) -> Void) {
    checkCameraPermission { [weak self] granted in
      guard let self = self else { return }
      
      if granted {
        self.captureCompletion = completion
        self.presentCameraViewController(completion: completion)
      } else {
        completion(.failure(NSError(domain: "CameraController", code: 101, userInfo: [NSLocalizedDescriptionKey: "Camera permission denied"])))
      }
    }
  }
  
  private func getTopViewController() -> UIViewController? {
    // Get key window for iOS 13+
    var keyWindow: UIWindow?
    
    if #available(iOS 13.0, *) {
      keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    } else {
      keyWindow = UIApplication.shared.keyWindow
    }
    
    // Get the root view controller
    guard let rootViewController = keyWindow?.rootViewController else {
      return nil
    }
    
    // Find the top-most presented view controller
    var topController = rootViewController
    while let presentedController = topController.presentedViewController {
      topController = presentedController
    }
    
    return topController
  }
  
  private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      completion(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          completion(granted)
        }
      }
    case .denied, .restricted:
      completion(false)
      
      // Show alert to direct user to settings
      DispatchQueue.main.async { [weak self] in
        if let topVC = self?.getTopViewController() {
          let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please allow camera access in Settings to capture documents and faces.",
            preferredStyle: .alert
          )
          
          alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(settingsURL)
            }
          })
          
          alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
          
          topVC.present(alert, animated: true)
        }
      }
    @unknown default:
      completion(false)
    }
  }
  
  private func presentCameraViewController(completion: @escaping (Result<UIImage, Error>) -> Void) {
    // Create and configure camera view controller
    cameraVC = UIViewController()
    guard let cameraVC = cameraVC else { return }
    
    cameraVC.modalPresentationStyle = .fullScreen
    cameraVC.view.backgroundColor = .black
    
    // Create camera view
    let cameraView = UIView()
    cameraView.translatesAutoresizingMaskIntoConstraints = false
    cameraVC.view.addSubview(cameraView)
    
    NSLayoutConstraint.activate([
      cameraView.topAnchor.constraint(equalTo: cameraVC.view.topAnchor),
      cameraView.bottomAnchor.constraint(equalTo: cameraVC.view.bottomAnchor),
      cameraView.leadingAnchor.constraint(equalTo: cameraVC.view.leadingAnchor),
      cameraView.trailingAnchor.constraint(equalTo: cameraVC.view.trailingAnchor)
    ])
    
    // Add close button
    let closeButton = UIButton(type: .system)
    closeButton.setTitle("Cancel", for: .normal)
    closeButton.setTitleColor(.white, for: .normal)
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    cameraVC.view.addSubview(closeButton)
    
    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: cameraVC.view.safeAreaLayoutGuide.topAnchor, constant: 16),
      closeButton.leadingAnchor.constraint(equalTo: cameraVC.view.leadingAnchor, constant: 16),
      closeButton.widthAnchor.constraint(equalToConstant: 80),
      closeButton.heightAnchor.constraint(equalToConstant: 44)
    ])
    
    closeButton.addTarget(self, action: #selector(dismissCamera), for: .touchUpInside)
    
    // Find the top view controller to present from
    if let topVC = getTopViewController() {
      // Present camera view controller
      topVC.present(cameraVC, animated: true) { [weak self] in
        // Setup camera after presentation
        self?.setupCamera(on: cameraView) { success in
          if success {
            // Start camera session after setup
            self?.startSession()
          } else {
            // Handle setup failure
            DispatchQueue.main.async {
              completion(.failure(NSError(domain: "CameraController", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to setup camera"])))
              cameraVC.dismiss(animated: true)
            }
          }
        }
      }
    } else {
      completion(.failure(NSError(domain: "CameraController", code: 105, userInfo: [NSLocalizedDescriptionKey: "Could not find view controller to present from"])))
    }
  }
  
  @objc func dismissCamera() {
    stopSession()
    cameraVC?.dismiss(animated: true)
  }
  
  // Add a capture button to the camera view
  private func addCaptureButton(to view: UIView) {
    let captureButton = UIButton(type: .system)
    captureButton.translatesAutoresizingMaskIntoConstraints = false
    captureButton.backgroundColor = UIColor.white
    captureButton.layer.cornerRadius = 35
    captureButton.layer.borderWidth = 5
    captureButton.layer.borderColor = UIColor.lightGray.cgColor
    
    view.addSubview(captureButton)
    
    NSLayoutConstraint.activate([
      captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
      captureButton.widthAnchor.constraint(equalToConstant: 70),
      captureButton.heightAnchor.constraint(equalToConstant: 70)
    ])
    
    captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
  }
  
  @objc private func captureButtonTapped() {
    takePicture()
  }
  
  private func takePicture() {
    guard let captureSession = captureSession, captureSession.isRunning else {
      captureCompletion?(.failure(NSError(domain: "CameraController", code: 103, userInfo: [NSLocalizedDescriptionKey: "Camera session not running"])))
      return
    }
    
    guard let photoOutput = photoOutput else {
      captureCompletion?(.failure(NSError(domain: "CameraController", code: 104, userInfo: [NSLocalizedDescriptionKey: "Photo output not available"])))
      return
    }
    
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
  }
}

// Local implementation of AcuantCamera classes
class DocumentCaptureResult {
  let image: UIImage
  
  init(image: UIImage) {
    self.image = image
  }
}

class DocumentCaptureController {
  private let cameraController = CameraController()
  
  func captureFrontDocument(completion: @escaping (Result<UIImage, Error>) -> Void) {
    cameraController.captureImage(completion: completion)
  }
  
  func captureBackDocument(completion: @escaping (Result<UIImage, Error>) -> Void) {
    cameraController.captureImage(completion: completion)
  }
}

// Local implementation of AcuantFaceCapture classes
class AcuantFaceCaptureController {
  private let cameraController = CameraController()
  
  func captureFace(completion: @escaping (Result<UIImage, Error>) -> Void) {
    cameraController.captureImage { result in
      switch result {
      case .success(let image):
        // Process the image for face capture
        completion(.success(image))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// Local implementation of AcuantDocumentProcessing classes
class DocumentData {
  let fields: [String: String]
  let authenticationResult: AuthenticationResult
  
  init(fields: [String: String], authenticationResult: AuthenticationResult) {
    self.fields = fields
    self.authenticationResult = authenticationResult
  }
}

class AuthenticationResult {
  let result: Int
  let score: Int
  
  init(result: Int, score: Int) {
    self.result = result
    self.score = score
  }
}

class AcuantDocumentProcessingController {
  func processDocument(frontImage: UIImage, backImage: UIImage, completion: @escaping (Result<DocumentData, Error>) -> Void) {
    // Simulate document processing with OCR
    DispatchQueue.global(qos: .userInitiated).async {
      // Simulate processing delay
      Thread.sleep(forTimeInterval: 2.0)
      
      // Create mock document data
      let fields = [
        "firstName": "John",
        "lastName": "Doe",
        "dateOfBirth": "1980-01-01",
        "documentNumber": "123456789",
        "expirationDate": "2030-01-01",
        "issuingCountry": "USA",
        "documentType": "Driver's License"
      ]
      
      let authResult = AuthenticationResult(result: 1, score: 85)
      let documentData = DocumentData(fields: fields, authenticationResult: authResult)
      
      DispatchQueue.main.async {
        completion(.success(documentData))
      }
    }
  }
}

// Local implementation of AcuantFaceMatch classes
class FaceMatchData {
  let score: Float
  let isMatch: Bool
  
  init(score: Float, isMatch: Bool) {
    self.score = score
    self.isMatch = isMatch
  }
}

class AcuantFaceMatchController {
  func matchFaces(faceImage: UIImage, idImage: UIImage, completion: @escaping (Result<FaceMatchData, Error>) -> Void) {
    // Simulate face matching
    DispatchQueue.global(qos: .userInitiated).async {
      // Simulate processing delay
      Thread.sleep(forTimeInterval: 1.5)
      
      // Create mock face match result with high score
      let matchData = FaceMatchData(score: 0.92, isMatch: true)
      
      DispatchQueue.main.async {
        completion(.success(matchData))
      }
    }
  }
}

public class SwiftAcuantFlutterPlugin: NSObject, FlutterPlugin {
  private var documentCaptureController: DocumentCaptureController?
  private var faceCaptureController: AcuantFaceCaptureController?
  private var documentProcessingController: AcuantDocumentProcessingController?
  private var faceMatchController: AcuantFaceMatchController?
  private var pendingResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "acuant_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftAcuantFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      if let args = call.arguments as? [String: Any],
         let username = args["username"] as? String,
         let password = args["password"] as? String,
         let subscription = args["subscription"] as? String,
         let endpoints = args["endpoints"] as? [String: String] {
        initialize(username: username, password: password, subscription: subscription, endpoints: endpoints, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for initialize", details: nil))
      }
    case "captureFrontDocument":
      pendingResult = result
      captureFrontDocument()
    case "captureBackDocument":
      pendingResult = result
      captureBackDocument()
    case "captureFace":
      pendingResult = result
      captureFace()
    case "processDocument":
      if let args = call.arguments as? [String: Any],
         let frontImagePath = args["frontImagePath"] as? String,
         let backImagePath = args["backImagePath"] as? String {
        processDocument(frontImagePath: frontImagePath, backImagePath: backImagePath, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for processDocument", details: nil))
      }
    case "matchFaces":
      if let args = call.arguments as? [String: Any],
         let faceImagePath = args["faceImagePath"] as? String,
         let idImagePath = args["idImagePath"] as? String {
        matchFaces(faceImagePath: faceImagePath, idImagePath: idImagePath, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for matchFaces", details: nil))
      }
    case "getSdkVersion":
      getSdkVersion(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func initialize(username: String, password: String, subscription: String, endpoints: [String: String], result: @escaping FlutterResult) {
    let credentials = AcuantCredentials(username: username, password: password, subscription: subscription)
    
    let endpointsObj = AcuantEndpoints()
    if let frmEndpoint = endpoints["frm_endpoint"] {
      endpointsObj.frmEndpoint = frmEndpoint
    }
    if let passiveLivenessEndpoint = endpoints["passive_liveness_endpoint"] {
      endpointsObj.passiveLivenessEndpoint = passiveLivenessEndpoint
    }
    if let medEndpoint = endpoints["med_endpoint"] {
      endpointsObj.medEndpoint = medEndpoint
    }
    if let assureidEndpoint = endpoints["assureid_endpoint"] {
      endpointsObj.assureidEndpoint = assureidEndpoint
    }
    if let acasEndpoint = endpoints["acas_endpoint"] {
      endpointsObj.acasEndpoint = acasEndpoint
    }
    if let ozoneEndpoint = endpoints["ozone_endpoint"] {
      endpointsObj.ozoneEndpoint = ozoneEndpoint
    }
    
    AcuantCommon.initialize(credentials: credentials, endpoints: endpoints) { [weak self] success, error in
        if success {
            self?.documentCaptureController = DocumentCaptureController()
            self?.faceCaptureController = AcuantFaceCaptureController()
            self?.documentProcessingController = AcuantDocumentProcessingController()
            self?.faceMatchController = AcuantFaceMatchController()
            
            result([
                "success": true,
                "message": "Acuant SDK initialized successfully"
            ])
        } else {
            result([
                "success": false,
                "message": error?.localizedDescription ?? "Failed to initialize Acuant SDK"
            ])
        }
    }
  }
  
  private func captureFrontDocument() {
    guard let controller = documentCaptureController else {
        pendingResult?([
            "success": false,
            "message": "Document capture controller not initialized"
        ])
        return
    }
    
    controller.captureFrontDocument { [weak self] result in
        switch result {
        case .success(let image):
            // Save image to temporary directory
            if let imagePath = self?.saveImageToTemporaryDirectory(image) {
                self?.pendingResult?([
                    "success": true,
                    "imagePath": imagePath
                ])
            } else {
                self?.pendingResult?([
                    "success": false,
                    "message": "Failed to save captured image"
                ])
            }
        case .failure(let error):
            self?.pendingResult?([
                "success": false,
                "message": error.localizedDescription
            ])
        }
    }
  }
  
  private func captureBackDocument() {
    guard let controller = documentCaptureController else {
        pendingResult?([
            "success": false,
            "message": "Document capture controller not initialized"
        ])
        return
    }
    
    controller.captureBackDocument { [weak self] result in
        switch result {
        case .success(let image):
            // Save image to temporary directory
            if let imagePath = self?.saveImageToTemporaryDirectory(image) {
                self?.pendingResult?([
                    "success": true,
                    "imagePath": imagePath
                ])
            } else {
                self?.pendingResult?([
                    "success": false,
                    "message": "Failed to save captured image"
                ])
            }
        case .failure(let error):
            self?.pendingResult?([
                "success": false,
                "message": error.localizedDescription
            ])
        }
    }
  }
  
  private func captureFace() {
    guard let controller = faceCaptureController else {
        pendingResult?([
            "success": false,
            "message": "Face capture controller not initialized"
        ])
        return
    }
    
    controller.captureFace { [weak self] result in
        switch result {
        case .success(let image):
            // Save image to temporary directory
            if let imagePath = self?.saveImageToTemporaryDirectory(image) {
                self?.pendingResult?([
                    "success": true,
                    "imagePath": imagePath
                ])
            } else {
                self?.pendingResult?([
                    "success": false,
                    "message": "Failed to save captured image"
                ])
            }
        case .failure(let error):
            self?.pendingResult?([
                "success": false,
                "message": error.localizedDescription
            ])
        }
    }
  }
  
  private func processDocument(frontImagePath: String, backImagePath: String, result: @escaping FlutterResult) {
    guard let controller = documentProcessingController else {
        result([
            "success": false,
            "message": "Document processing controller not initialized"
        ])
        return
    }
    
    guard let frontImage = UIImage(contentsOfFile: frontImagePath),
          let backImage = UIImage(contentsOfFile: backImagePath) else {
        result([
            "success": false,
            "message": "Failed to load document images"
        ])
        return
    }
    
    controller.processDocument(frontImage: frontImage, backImage: backImage) { processResult in
        switch processResult {
        case .success(let documentData):
            result([
                "success": true,
                "fields": documentData.fields,
                "authenticationResult": [
                    "result": documentData.authenticationResult.result,
                    "score": documentData.authenticationResult.score
                ]
            ])
        case .failure(let error):
            result([
                "success": false,
                "message": error.localizedDescription
            ])
        }
    }
  }
  
  private func matchFaces(faceImagePath: String, idImagePath: String, result: @escaping FlutterResult) {
    guard let controller = faceMatchController else {
        result([
            "success": false,
            "message": "Face match controller not initialized"
        ])
        return
    }
    
    guard let faceImage = UIImage(contentsOfFile: faceImagePath),
           let idImage = UIImage(contentsOfFile: idImagePath) else {
        result([
            "success": false,
            "message": "Failed to load face images"
        ])
        return
    }
    
    controller.matchFaces(faceImage: faceImage, idImage: idImage) { matchResult in
        switch matchResult {
        case .success(let matchData):
            result([
                "success": true,
                "score": matchData.score,
                "isMatch": matchData.isMatch
            ])
        case .failure(let error):
            result([
                "success": false,
                "message": error.localizedDescription
            ])
        }
    }
  }
  
  private func getSdkVersion(result: @escaping FlutterResult) {
    result([
        "success": true,
        "sdkVersion": AcuantCommon.version
    ])
  }
  
  private func saveImageToTemporaryDirectory(_ image: UIImage) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.8) else {
        return nil
    }
    
    let tempDir = NSTemporaryDirectory()
    let fileName = UUID().uuidString + ".jpg"
    let fileURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
    
    do {
        try data.write(to: fileURL)
        return fileURL.path
    } catch {
        print("Error saving image: \(error)")
        return nil
    }
  }
} 
import Flutter
import UIKit
import AVFoundation

public class SwiftAcuantFlutterPlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "acuant_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftAcuantFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
        initialize(result: result)
    case "captureFrontDocument":
        pendingResult = result
        captureImage(isBack: false, isFace: false)
    case "captureBackDocument":
        pendingResult = result
        captureImage(isBack: true, isFace: false)
    case "captureFace":
        pendingResult = result
        captureImage(isBack: false, isFace: true)
    case "processDocument":
        if let args = call.arguments as? [String: Any],
           let frontImagePath = args["frontImagePath"] as? String,
           let backImagePath = args["backImagePath"] as? String {
            processDocument(frontImagePath: frontImagePath, backImagePath: backImagePath)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid arguments for processDocument",
                              details: nil))
        }
    case "getSdkVersion":
        getSdkVersion(result: result)
    case "matchFace":
        if let args = call.arguments as? [String: Any],
           let faceImagePath = args["faceImagePath"] as? String,
           let documentImagePath = args["documentImagePath"] as? String {
            matchFace(faceImagePath: faceImagePath, documentImagePath: documentImagePath)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid arguments for matchFace",
                              details: nil))
        }
    default:
        result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Implementation Methods
  
  private func initialize(result: @escaping FlutterResult) {
    // Simulate successful initialization
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      result([
        "success": true,
        "message": "SDK initialized successfully"
      ])
    }
  }
  
  private func captureImage(isBack: Bool, isFace: Bool) {
    let cameraPosition: AVCaptureDevice.Position = isFace ? .front : .back
    
    // Create and present the camera view controller
    let cameraVC = SimpleCameraViewController()
    cameraVC.cameraPosition = cameraPosition
    cameraVC.isDocumentCapture = !isFace
    cameraVC.completionHandler = { [weak self] result in
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
    
    // Present the camera view controller
    if let topVC = UIApplication.shared.keyWindow?.rootViewController {
      var presentingVC = topVC
      while let presented = presentingVC.presentedViewController {
        presentingVC = presented
      }
      
      presentingVC.present(cameraVC, animated: true)
    } else {
      pendingResult?([
        "success": false,
        "message": "Could not present camera"
      ])
    }
  }
  
  private func processDocument(frontImagePath: String, backImagePath: String) {
    // Create mock document data
    let mockFields: [String: String] = [
      "firstName": "John",
      "lastName": "Doe",
      "dateOfBirth": "1980-01-01",
      "documentNumber": "X123456789",
      "expirationDate": "2025-01-01",
      "issuingCountry": "USA",
      "issuingState": "CA",
      "documentType": "Driver's License"
    ]
    
    // Simulate processing delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.pendingResult?([
        "success": true,
        "fields": mockFields,
        "authenticationResult": [
          "result": "Passed",
          "score": 95
        ]
      ])
    }
  }
  
  private func getSdkVersion(result: @escaping FlutterResult) {
    result([
      "success": true,
      "sdkVersion": "11.0.0"
    ])
  }

  private func matchFace(faceImagePath: String, documentImagePath: String) {
    // Simulate face matching delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.pendingResult?([
        "success": true,
        "score": 90,
        "isMatch": true
      ])
    }
  }
  
  private func saveImageToTemporaryDirectory(_ image: UIImage) -> String? {
    let tempDir = NSTemporaryDirectory()
    let fileName = UUID().uuidString + ".jpg"
    let filePath = (tempDir as NSString).appendingPathComponent(fileName)
    
    if let imageData = image.jpegData(compressionQuality: 0.8) {
      do {
        try imageData.write(to: URL(fileURLWithPath: filePath))
        return filePath
      } catch {
        print("Error saving image: \(error)")
        return nil
      }
    }
    return nil
  }
}

// MARK: - Simple Camera View Controller
class SimpleCameraViewController: UIViewController {
  private var captureSession: AVCaptureSession!
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private var photoOutput: AVCapturePhotoOutput!
  private var overlayView: UIView!
  
  var cameraPosition: AVCaptureDevice.Position = .back
  var isDocumentCapture: Bool = true
  var completionHandler: ((Result<UIImage, Error>) -> Void)?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set up UI
    view.backgroundColor = .black
    
    // Set up capture session
    setupCaptureSession()
    
    // Set up UI elements
    setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Start the session on a background thread
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      self?.captureSession.startRunning()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Stop the session
    captureSession.stopRunning()
  }
  
  private func setupCaptureSession() {
    // Initialize capture session
    captureSession = AVCaptureSession()
    
    // Begin configuration
    captureSession.beginConfiguration()
    
    // Set session preset
    if captureSession.canSetSessionPreset(.photo) {
      captureSession.sessionPreset = .photo
    }
    
    // Setup camera input
    guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
          let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
          captureSession.canAddInput(videoDeviceInput) else {
      captureSession.commitConfiguration()
      completionHandler?(.failure(NSError(domain: "SimpleCameraViewController", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to set up camera input"])))
      return
    }
    
    captureSession.addInput(videoDeviceInput)
    
    // Setup photo output
    photoOutput = AVCapturePhotoOutput()
    guard captureSession.canAddOutput(photoOutput) else {
      captureSession.commitConfiguration()
      completionHandler?(.failure(NSError(domain: "SimpleCameraViewController", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to set up photo output"])))
      return
    }
    
    captureSession.addOutput(photoOutput)
    captureSession.commitConfiguration()
    
    // Setup preview layer
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.addSublayer(previewLayer)
  }
  
  private func setupUI() {
    // Add overlay view
    overlayView = UIView(frame: view.bounds)
    overlayView.backgroundColor = UIColor.clear
    view.addSubview(overlayView)
    
    // Add frame guide
    if isDocumentCapture {
      addDocumentFrameGuide()
    } else {
      addFaceFrameGuide()
    }
    
    // Add capture button
    let captureButton = UIButton(type: .system)
    captureButton.translatesAutoresizingMaskIntoConstraints = false
    captureButton.backgroundColor = .white
    captureButton.layer.cornerRadius = 35
    captureButton.layer.borderWidth = 5
    captureButton.layer.borderColor = UIColor.lightGray.cgColor
    captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    view.addSubview(captureButton)
    
    NSLayoutConstraint.activate([
      captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
      captureButton.widthAnchor.constraint(equalToConstant: 70),
      captureButton.heightAnchor.constraint(equalToConstant: 70)
    ])
    
    // Add cancel button
    let cancelButton = UIButton(type: .system)
    cancelButton.translatesAutoresizingMaskIntoConstraints = false
    cancelButton.setTitle("Cancel", for: .normal)
    cancelButton.setTitleColor(.white, for: .normal)
    cancelButton.addTarget(self, action: #selector(cancelCapture), for: .touchUpInside)
    view.addSubview(cancelButton)
    
    NSLayoutConstraint.activate([
      cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      cancelButton.widthAnchor.constraint(equalToConstant: 80),
      cancelButton.heightAnchor.constraint(equalToConstant: 44)
    ])
  }
  
  private func addDocumentFrameGuide() {
    // Create document frame cutout
    let documentWidth = view.bounds.width * 0.8
    let documentHeight = documentWidth * 0.63 // ID card aspect ratio
    let documentX = (view.bounds.width - documentWidth) / 2
    let documentY = (view.bounds.height - documentHeight) / 2
    
    let documentRect = CGRect(x: documentX, y: documentY, width: documentWidth, height: documentHeight)
    
    // Add semi-transparent overlay with cutout
    let overlayPath = UIBezierPath(rect: view.bounds)
    overlayPath.append(UIBezierPath(roundedRect: documentRect, cornerRadius: 10).reversing())
    
    let overlayLayer = CAShapeLayer()
    overlayLayer.path = overlayPath.cgPath
    overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
    overlayView.layer.addSublayer(overlayLayer)
    
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
  
  private func addFaceFrameGuide() {
    // Create face oval cutout
    let faceWidth = view.bounds.width * 0.7
    let faceHeight = faceWidth * 1.3 // Oval face aspect ratio
    let faceX = (view.bounds.width - faceWidth) / 2
    let faceY = (view.bounds.height - faceHeight) / 2
    
    let faceRect = CGRect(x: faceX, y: faceY, width: faceWidth, height: faceHeight)
    
    // Add semi-transparent overlay with cutout
    let overlayPath = UIBezierPath(rect: view.bounds)
    overlayPath.append(UIBezierPath(ovalIn: faceRect).reversing())
    
    let overlayLayer = CAShapeLayer()
    overlayLayer.path = overlayPath.cgPath
    overlayLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
    overlayView.layer.addSublayer(overlayLayer)
    
    // Add border around face frame
    let borderLayer = CAShapeLayer()
    borderLayer.path = UIBezierPath(ovalIn: faceRect).cgPath
    borderLayer.strokeColor = UIColor.white.cgColor
    borderLayer.fillColor = UIColor.clear.cgColor
    borderLayer.lineWidth = 3
    overlayView.layer.addSublayer(borderLayer)
    
    // Add instruction label
    let instructionLabel = UILabel()
    instructionLabel.text = "Position your face within the oval"
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
  
  @objc private func capturePhoto() {
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
  }
  
  @objc private func cancelCapture() {
    completionHandler?(.failure(NSError(domain: "SimpleCameraViewController", code: 103, userInfo: [NSLocalizedDescriptionKey: "Capture cancelled"])))
    dismiss(animated: true)
  }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension SimpleCameraViewController: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
      completionHandler?(.failure(error))
      dismiss(animated: true)
      return
    }
    
    guard let imageData = photo.fileDataRepresentation(),
          let image = UIImage(data: imageData) else {
      completionHandler?(.failure(NSError(domain: "SimpleCameraViewController", code: 104, userInfo: [NSLocalizedDescriptionKey: "Failed to process captured image"])))
      dismiss(animated: true)
      return
    }
    
    completionHandler?(.success(image))
    dismiss(animated: true)
  }
} 
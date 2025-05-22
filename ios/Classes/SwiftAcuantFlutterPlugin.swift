import Flutter
import UIKit
import AVFoundation
import Foundation

// Import the AcuantSDK directly
// No need for explicit import as AcuantSDK.swift is in the same module

// MARK: - Camera Controller

class CameraController: NSObject {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var cameraVC: UIViewController?
    
    enum CaptureError: Error {
        case cameraSetupFailed
        case captureFailed
        case userCancelled
    }
    
    func captureImage(isBack: Bool, isFace: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        let cameraPosition: AVCaptureDevice.Position = isFace ? .front : .back
        
        // Create and present the camera view controller
        let cameraVC = SimpleCameraViewController()
        cameraVC.cameraPosition = cameraPosition
        cameraVC.isDocumentCapture = !isFace
        cameraVC.completionHandler = { result in
            switch result {
            case .success(let image):
                // Save image to temporary directory
                if let imagePath = self.saveImageToTemporaryDirectory(image) {
                    completion(.success(imagePath))
                } else {
                    completion(.failure(CaptureError.captureFailed))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        // Present the camera view controller
        if let topVC = UIApplication.shared.keyWindow?.rootViewController {
            var presentingVC = topVC
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            
            self.cameraVC = cameraVC
            presentingVC.present(cameraVC, animated: true)
        } else {
            completion(.failure(CaptureError.cameraSetupFailed))
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

public class SwiftAcuantFlutterPlugin: NSObject, FlutterPlugin {
  private var pendingResult: FlutterResult?
  private var isInitialized = false
  private var credentials: Credentials?
  private var cameraController: CameraController?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "acuant_flutter_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftAcuantFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
        if let args = call.arguments as? [String: Any] {
            initialize(args: args, result: result)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid arguments for initialize",
                              details: nil))
        }
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
            pendingResult = result
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
            pendingResult = result
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
  
  private func initialize(args: [String: Any], result: @escaping FlutterResult) {
    print("Initializing Acuant SDK...")
    
    guard let username = args["username"] as? String,
          let password = args["password"] as? String,
          let subscription = args["subscription"] as? String,
          let endpoints = args["endpoints"] as? [String: String] else {
        print("Missing required initialization parameters")
        result([
            "success": false,
            "message": "Missing required initialization parameters"
        ])
        return
    }
    
    // Log the initialization parameters
    print("Username: \(username)")
    print("Subscription: \(subscription)")
    print("Endpoints: \(endpoints)")
    
    // Create Acuant credentials
    let credentials = Credentials()
    credentials.username = username
    credentials.password = password
    credentials.subscription = subscription
    
    // Set endpoints
    if let frmEndpoint = endpoints["frm_endpoint"] {
        credentials.frm = frmEndpoint
    }
    if let passiveLivenessEndpoint = endpoints["passive_liveness_endpoint"] {
        credentials.passiveLiveness = passiveLivenessEndpoint
    }
    if let medEndpoint = endpoints["med_endpoint"] {
        credentials.med = medEndpoint
    }
    if let acasEndpoint = endpoints["acas_endpoint"] {
        credentials.acas = acasEndpoint
    }
    if let ozoneEndpoint = endpoints["ozone_endpoint"] {
        credentials.ozone = ozoneEndpoint
    }
    if let assureidEndpoint = endpoints["assureid_endpoint"] {
        credentials.assureID = assureidEndpoint
    }
    
    self.credentials = credentials
    
    // Initialize the Acuant SDK
    Initializer.initializeWithCredentials(credentials: credentials) { [weak self] error in
        DispatchQueue.main.async {
            if let error = error {
                print("Acuant SDK initialization failed: \(error.localizedDescription)")
                result([
                    "success": false,
                    "message": "SDK initialization failed: \(error.localizedDescription)"
                ])
            } else {
                print("Acuant SDK initialized successfully")
                self?.isInitialized = true
                result([
                    "success": true,
                    "message": "SDK initialized successfully"
                ])
            }
        }
    }
  }
  
  private func captureImage(isBack: Bool, isFace: Bool) {
    if !isInitialized {
        print("Acuant SDK is not initialized")
        pendingResult?([
            "success": false,
            "message": "Acuant SDK is not initialized"
        ])
        return
    }
    
    // Initialize camera controller if needed
    if cameraController == nil {
        cameraController = CameraController()
    }
    
    // Capture image using the camera controller
    cameraController?.captureImage(isBack: isBack, isFace: isFace) { [weak self] result in
        switch result {
        case .success(let imagePath):
            print("\(isFace ? "Face" : (isBack ? "Back document" : "Front document")) image captured and saved at: \(imagePath)")
            self?.pendingResult?([
                "success": true,
                "imagePath": imagePath
            ])
        case .failure(let error):
            print("Image capture failed: \(error.localizedDescription)")
            self?.pendingResult?([
                "success": false,
                "message": error.localizedDescription
            ])
        }
    }
  }
  
  private func processDocument(frontImagePath: String, backImagePath: String) {
    print("Processing document with Acuant SDK...")
    print("Front image path: \(frontImagePath)")
    print("Back image path: \(backImagePath)")
    
    // Check if SDK is initialized
    if !isInitialized {
        print("Acuant SDK is not initialized")
        pendingResult?([
            "success": false,
            "message": "Acuant SDK is not initialized"
        ])
        return
    }
    
    // Check if images exist
    let frontImageExists = FileManager.default.fileExists(atPath: frontImagePath)
    let backImageExists = FileManager.default.fileExists(atPath: backImagePath)
    
    print("Image files exist - Front: \(frontImageExists), Back: \(backImageExists)")
    
    if !frontImageExists || !backImageExists {
      print("One or both image files do not exist")
      pendingResult?([
        "success": false,
        "message": "One or both image files do not exist"
      ])
      return
    }
    
    // Load images
    guard let frontImage = UIImage(contentsOfFile: frontImagePath),
          let backImage = UIImage(contentsOfFile: backImagePath) else {
      print("Failed to load images from file paths")
      pendingResult?([
        "success": false,
        "message": "Failed to load images from file paths"
      ])
      return
    }
    
    print("Successfully loaded images - Front: \(frontImage.size), Back: \(backImage.size)")
    
    // Process images with Acuant SDK
    print("Step 1: Preparing document images...")
    let frontCroppedImage = ImagePreparation.prepareImage(image: frontImage)
    let backCroppedImage = ImagePreparation.prepareImage(image: backImage)
    
    print("Step 2: Creating document instance...")
    let idData = IdData()
    idData.frontImage = frontCroppedImage
    idData.backImage = backCroppedImage
    
    // Create document instance
    DocumentProcessor.createInstance(idData: idData) { [weak self] instanceId, error in
        if let error = error {
            print("Failed to create document instance: \(error.localizedDescription)")
            self?.pendingResult?([
                "success": false,
                "message": "Failed to create document instance: \(error.localizedDescription)"
            ])
            return
        }
        
        guard let instanceId = instanceId else {
            print("No instance ID returned")
            self?.pendingResult?([
                "success": false,
                "message": "No instance ID returned"
            ])
            return
        }
        
        print("Step 3: Document instance created with ID: \(instanceId)")
        
        // Process the document instance
        print("Step 4: Processing document instance...")
        DocumentProcessor.processInstance(instanceId: instanceId) { [weak self] result, error in
            if let error = error {
                print("Failed to process document: \(error.localizedDescription)")
                self?.pendingResult?([
                    "success": false,
                    "message": "Failed to process document: \(error.localizedDescription)"
                ])
                return
            }
            
            guard let result = result else {
                print("No result returned from document processing")
                self?.pendingResult?([
                    "success": false,
                    "message": "No result returned from document processing"
                ])
                return
            }
            
            print("Step 5: Document processed successfully")
            
            // Extract document fields
            var fields: [String: String] = [:]
            
            // Extract document data fields
            print("Step 6: Extracting document fields...")
            if let dataFields = result.fields {
                for field in dataFields {
                    if let name = field.name, let value = field.value {
                        fields[name] = value
                        print("Field extracted: \(name) = \(value)")
                    }
                }
            }
            
            // Save document photo if available
            var photoPath: String? = nil
            if let faceImage = result.faceImage {
                photoPath = self?.saveImageToTemporaryDirectory(faceImage)
                fields["photoPath"] = photoPath
                print("Document face photo saved at: \(photoPath ?? "unknown")")
            }
            
            print("Document fields extracted: \(fields.keys.joined(separator: ", "))")
            
            // Get authentication result
            let authResult = result.authenticationResult
            let authResultDict: [String: Any] = [
                "result": authResult?.result ?? "Unknown",
                "score": authResult?.score ?? 0
            ]
            
            print("Authentication result: \(authResult?.result ?? "Unknown") (Score: \(authResult?.score ?? 0))")
            
            // Return the processed document data
            self?.pendingResult?([
                "success": true,
                "fields": fields,
                "authenticationResult": authResultDict
            ])
            
            print("Document processing completed successfully")
        }
    }
  }
  
  private func getSdkVersion(result: @escaping FlutterResult) {
    let version = Initializer.getSDKVersion()
    print("Acuant SDK version: \(version)")
    result([
      "success": true,
      "sdkVersion": version
    ])
  }

  private func matchFace(faceImagePath: String, documentImagePath: String) {
    print("Matching face with Acuant SDK...")
    print("Face image path: \(faceImagePath)")
    print("Document image path: \(documentImagePath)")
    
    // Check if SDK is initialized
    if !isInitialized {
        print("Acuant SDK is not initialized")
        pendingResult?([
            "success": false,
            "message": "Acuant SDK is not initialized"
        ])
        return
    }
    
    // Check if images exist
    let faceImageExists = FileManager.default.fileExists(atPath: faceImagePath)
    let documentImageExists = documentImagePath != "null" && FileManager.default.fileExists(atPath: documentImagePath)
    
    print("Image files exist - Face: \(faceImageExists), Document: \(documentImageExists)")
    
    if !faceImageExists {
      print("Face image file does not exist")
      pendingResult?([
        "success": false,
        "message": "Face image file does not exist"
      ])
      return
    }
    
    if documentImagePath == "null" || !documentImageExists {
      print("Document image file does not exist or is null")
      pendingResult?([
        "success": false,
        "message": "Document image file does not exist or is null"
      ])
      return
    }
    
    // Load images
    guard let faceImage = UIImage(contentsOfFile: faceImagePath),
          let documentImage = UIImage(contentsOfFile: documentImagePath) else {
      print("Failed to load images from file paths")
      pendingResult?([
        "success": false,
        "message": "Failed to load images from file paths"
      ])
      return
    }
    
    print("Successfully loaded images - Face: \(faceImage.size), Document: \(documentImage.size)")
    
    // Process face match with Acuant SDK
    print("Step 1: Preparing face images...")
    
    print("Step 2: Performing facial match...")
    FacialMatch.processFacialMatch(selfieImage: faceImage, documentImage: documentImage) { [weak self] result, error in
        if let error = error {
            print("Face matching failed: \(error.localizedDescription)")
            self?.pendingResult?([
                "success": false,
                "message": "Face matching failed: \(error.localizedDescription)"
            ])
            return
        }
        
        guard let result = result else {
            print("No result returned from face matching")
            self?.pendingResult?([
                "success": false,
                "message": "No result returned from face matching"
            ])
            return
        }
        
        print("Step 3: Face matching completed - Score: \(result.score)")
        
        // Determine if it's a match based on score threshold
        let isMatch = result.score >= 80 // Using 80 as a threshold, adjust as needed
        
        print("Match determination: \(isMatch ? "MATCH" : "NO MATCH")")
        
        // Return face matching result
        self?.pendingResult?([
            "success": true,
            "score": result.score,
            "isMatch": isMatch
        ])
        
        print("Face matching process completed successfully")
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
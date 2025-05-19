# Acuant Flutter Plugin

A Flutter plugin for using Acuant iOS SDK v11.6.5 in Flutter applications.

## Features

* Document capture (front and back)
* Face capture
* Document processing and data extraction
* Supports Acuant authentication and verification services

## Getting Started

This plugin provides a Flutter interface to the native Acuant iOS SDK.

### Prerequisites

* iOS 11.0 or later
* Acuant account with credentials
* Flutter SDK (v3.29.3 or later)
* Dart SDK (v3.7.2 or later)

### Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  acuant_flutter_plugin:
    git:
      url: https://github.com/your-username/acuant_flutter_plugin.git
```

### iOS Setup

For iOS, you need to update your Info.plist file with:

1. Camera permissions:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to your camera to capture ID documents and face.</string>
```

2. Create a file named AcuantConfig.plist in your iOS project with your Acuant credentials:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>acuant_username</key>
    <string>YOUR_ACUANT_USERNAME</string>
    <key>acuant_password</key>
    <string>YOUR_ACUANT_PASSWORD</string>
    <key>acuant_subscription</key>
    <string>YOUR_ACUANT_SUBSCRIPTION</string>
    <key>frm_endpoint</key>
    <string>https://frm.acuant.net</string>
    <key>passive_liveness_endpoint</key>
    <string>https://us.passlive.acuant.net</string>
    <key>med_endpoint</key>
    <string>https://medicscan.acuant.net</string>
    <key>assureid_endpoint</key>
    <string>https://services.assureid.net</string>
    <key>acas_endpoint</key>
    <string>https://acas.acuant.net</string>
    <key>ozone_endpoint</key>
    <string>https://ozone.acuant.net</string>
</dict>
</plist>
```

## Step-by-Step Integration Guide

### 1. Import the Plugin

In your Dart file, import the Acuant Flutter plugin:

```dart
import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';
```

### 2. Initialize the SDK

Initialize the Acuant SDK with your credentials at app startup (typically in your main.dart or during app initialization):

```dart
Future<void> initializeAcuantSDK() async {
  try {
    final initResult = await AcuantFlutterPlugin.initialize(
      username: 'YOUR_USERNAME',
      password: 'YOUR_PASSWORD',
      subscription: 'YOUR_SUBSCRIPTION',
      endpoints: {
        'frm_endpoint': 'https://frm.acuant.net',
        'passive_liveness_endpoint': 'https://us.passlive.acuant.net',
        'med_endpoint': 'https://medicscan.acuant.net',
        'assureid_endpoint': 'https://services.assureid.net',
        'acas_endpoint': 'https://acas.acuant.net',
        'ozone_endpoint': 'https://ozone.acuant.net',
      },
    );
    
    if (initResult['success'] == true) {
      print('Acuant SDK initialized successfully');
    } else {
      print('Failed to initialize Acuant SDK: ${initResult['error']}');
    }
  } catch (e) {
    print('Error initializing Acuant SDK: $e');
  }
}
```

### 3. Capture Document Images

Implement document capture functionality in your app:

#### Capture Front of ID Document

```dart
Future<void> captureFrontOfDocument() async {
  try {
    final frontResult = await AcuantFlutterPlugin.captureFrontDocument();
    if (frontResult['success'] == true) {
      String? frontImagePath = frontResult['imagePath'];
      // Store this path for later processing
      setState(() {
        _frontImagePath = frontImagePath;
      });
    } else {
      print('Failed to capture front of document: ${frontResult['error']}');
    }
  } catch (e) {
    print('Error capturing front of document: $e');
  }
}
```

#### Capture Back of ID Document

```dart
Future<void> captureBackOfDocument() async {
  try {
    final backResult = await AcuantFlutterPlugin.captureBackDocument();
    if (backResult['success'] == true) {
      String? backImagePath = backResult['imagePath'];
      // Store this path for later processing
      setState(() {
        _backImagePath = backImagePath;
      });
    } else {
      print('Failed to capture back of document: ${backResult['error']}');
    }
  } catch (e) {
    print('Error capturing back of document: $e');
  }
}
```

### 4. Process Document Images

After capturing both sides of the document, process them to extract information:

```dart
Future<void> processDocument() async {
  if (_frontImagePath == null || _backImagePath == null) {
    print('Both front and back images must be captured first');
    return;
  }
  
  try {
    setState(() {
      _isProcessing = true;
    });
    
    final processResult = await AcuantFlutterPlugin.processDocument(
      frontImagePath: _frontImagePath!,
      backImagePath: _backImagePath!,
    );
    
    setState(() {
      _isProcessing = false;
    });
    
    if (processResult['success'] == true) {
      // Extract and use document data
      final fields = processResult['fields'];
      final authResult = processResult['authenticationResult'];
      
      setState(() {
        _documentData = fields;
        _authenticationResult = authResult;
      });
      
      // Example of accessing specific fields
      print('Document owner: ${fields['firstName']} ${fields['lastName']}');
      print('Document number: ${fields['documentNumber']}');
      print('Authentication score: ${authResult['score']}');
    } else {
      print('Failed to process document: ${processResult['error']}');
    }
  } catch (e) {
    setState(() {
      _isProcessing = false;
    });
    print('Error processing document: $e');
  }
}
```

### 5. Capture Face Image

For identity verification, capture a facial image:

```dart
Future<void> captureFace() async {
  try {
    final faceResult = await AcuantFlutterPlugin.captureFace();
    if (faceResult['success'] == true) {
      String? faceImagePath = faceResult['imagePath'];
      setState(() {
        _faceImagePath = faceImagePath;
      });
    } else {
      print('Failed to capture face: ${faceResult['error']}');
    }
  } catch (e) {
    print('Error capturing face: $e');
  }
}
```

### 6. Perform Face Match

Compare the captured face with the document photo:

```dart
Future<void> performFaceMatch() async {
  if (_faceImagePath == null || _documentData == null) {
    print('Face image and document data must be available first');
    return;
  }
  
  try {
    setState(() {
      _isMatching = true;
    });
    
    final matchResult = await AcuantFlutterPlugin.matchFace(
      faceImagePath: _faceImagePath!,
      documentImagePath: _documentData['photoPath'],
    );
    
    setState(() {
      _isMatching = false;
    });
    
    if (matchResult['success'] == true) {
      final score = matchResult['score'];
      final isMatch = matchResult['isMatch'];
      
      setState(() {
        _faceMatchScore = score;
        _isFaceMatched = isMatch;
      });
      
      print('Face match score: $score');
      print('Is match: $isMatch');
    } else {
      print('Failed to match face: ${matchResult['error']}');
    }
  } catch (e) {
    setState(() {
      _isMatching = false;
    });
    print('Error matching face: $e');
  }
}
```

### 7. Get SDK Version Information

Retrieve SDK version information:

```dart
Future<void> getSdkVersionInfo() async {
  try {
    final versionInfo = await AcuantFlutterPlugin.getSdkVersion();
    print('SDK Version: ${versionInfo['sdkVersion']}');
  } catch (e) {
    print('Error getting SDK version: $e');
  }
}
```

### 8. Complete Implementation Example

Here's a more complete example of a screen that uses the Acuant Flutter plugin:

```dart
import 'package:flutter/material.dart';
import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';

class DocumentVerificationScreen extends StatefulWidget {
  @override
  _DocumentVerificationScreenState createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  String? _frontImagePath;
  String? _backImagePath;
  String? _faceImagePath;
  Map<String, dynamic>? _documentData;
  Map<String, dynamic>? _authenticationResult;
  double? _faceMatchScore;
  bool? _isFaceMatched;
  bool _isProcessing = false;
  bool _isMatching = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      final initResult = await AcuantFlutterPlugin.initialize(
        username: 'YOUR_USERNAME',
        password: 'YOUR_PASSWORD',
        subscription: 'YOUR_SUBSCRIPTION',
        endpoints: {
          'frm_endpoint': 'https://frm.acuant.net',
          'passive_liveness_endpoint': 'https://us.passlive.acuant.net',
          'med_endpoint': 'https://medicscan.acuant.net',
          'assureid_endpoint': 'https://services.assureid.net',
          'acas_endpoint': 'https://acas.acuant.net',
          'ozone_endpoint': 'https://ozone.acuant.net',
        },
      );
      
      setState(() {
        _isInitialized = initResult['success'] == true;
      });
      
      if (!_isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize Acuant SDK')),
        );
      }
    } catch (e) {
      setState(() {
        _isInitialized = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing Acuant SDK: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Verification'),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => InfoDialog(),
              );
            },
          ),
        ],
      ),
      body: _isInitialized
          ? SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCaptureSection(),
                  SizedBox(height: 24),
                  _buildProcessingSection(),
                  SizedBox(height: 24),
                  _buildResultsSection(),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Acuant SDK...'),
                ],
              ),
            ),
    );
  }

  Widget _buildCaptureSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Capture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    label: Text('Front'),
                    onPressed: _captureFrontOfDocument,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    label: Text('Back'),
                    onPressed: _captureBackOfDocument,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.face),
              label: Text('Capture Face'),
              onPressed: _captureFace,
            ),
            SizedBox(height: 16),
            _buildCaptureStatusText(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureStatusText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Front ID: ${_frontImagePath != null ? "Captured" : "Not captured"}',
          style: TextStyle(
            color: _frontImagePath != null ? Colors.green : Colors.red,
          ),
        ),
        Text(
          'Back ID: ${_backImagePath != null ? "Captured" : "Not captured"}',
          style: TextStyle(
            color: _backImagePath != null ? Colors.green : Colors.red,
          ),
        ),
        Text(
          'Face: ${_faceImagePath != null ? "Captured" : "Not captured"}',
          style: TextStyle(
            color: _faceImagePath != null ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingSection() {
    final bool canProcess = _frontImagePath != null && _backImagePath != null;
    final bool canMatchFace = _documentData != null && _faceImagePath != null;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: canProcess ? _processDocument : null,
              child: _isProcessing
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Process Document'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: canMatchFace ? _performFaceMatch : null,
              child: _isMatching
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Match Face'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_documentData == null) {
      return SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Document Information:'),
            SizedBox(height: 8),
            _buildInfoRow('Name', '${_documentData!['firstName']} ${_documentData!['lastName']}'),
            _buildInfoRow('Document Number', '${_documentData!['documentNumber']}'),
            _buildInfoRow('Date of Birth', '${_documentData!['dateOfBirth']}'),
            _buildInfoRow('Expiration Date', '${_documentData!['expirationDate']}'),
            
            if (_authenticationResult != null) ...[
              SizedBox(height: 16),
              Text('Authentication:'),
              SizedBox(height: 8),
              _buildInfoRow('Result', '${_authenticationResult!['result']}'),
              _buildInfoRow('Score', '${_authenticationResult!['score']}'),
            ],
            
            if (_faceMatchScore != null) ...[
              SizedBox(height: 16),
              Text('Face Match:'),
              SizedBox(height: 8),
              _buildInfoRow('Score', '$_faceMatchScore'),
              _buildInfoRow('Match', _isFaceMatched == true ? 'Yes' : 'No'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _captureFrontOfDocument() async {
    try {
      final frontResult = await AcuantFlutterPlugin.captureFrontDocument();
      if (frontResult['success'] == true) {
        setState(() {
          _frontImagePath = frontResult['imagePath'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture front of document')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _captureBackOfDocument() async {
    try {
      final backResult = await AcuantFlutterPlugin.captureBackDocument();
      if (backResult['success'] == true) {
        setState(() {
          _backImagePath = backResult['imagePath'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture back of document')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _captureFace() async {
    try {
      final faceResult = await AcuantFlutterPlugin.captureFace();
      if (faceResult['success'] == true) {
        setState(() {
          _faceImagePath = faceResult['imagePath'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture face')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _processDocument() async {
    if (_frontImagePath == null || _backImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Both front and back images must be captured first')),
      );
      return;
    }
    
    try {
      setState(() {
        _isProcessing = true;
      });
      
      final processResult = await AcuantFlutterPlugin.processDocument(
        frontImagePath: _frontImagePath!,
        backImagePath: _backImagePath!,
      );
      
      setState(() {
        _isProcessing = false;
      });
      
      if (processResult['success'] == true) {
        setState(() {
          _documentData = processResult['fields'];
          _authenticationResult = processResult['authenticationResult'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process document')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _performFaceMatch() async {
    if (_faceImagePath == null || _documentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Face image and document data must be available first')),
      );
      return;
    }
    
    try {
      setState(() {
        _isMatching = true;
      });
      
      final matchResult = await AcuantFlutterPlugin.matchFace(
        faceImagePath: _faceImagePath!,
        documentImagePath: _documentData!['photoPath'],
      );
      
      setState(() {
        _isMatching = false;
      });
      
      if (matchResult['success'] == true) {
        setState(() {
          _faceMatchScore = matchResult['score'];
          _isFaceMatched = matchResult['isMatch'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to match face')),
        );
      }
    } catch (e) {
      setState(() {
        _isMatching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Initialization Failures**
   - Verify your Acuant credentials are correct
   - Check network connectivity
   - Ensure all required endpoints are properly configured

2. **Camera Access Issues**
   - Verify NSCameraUsageDescription is properly set in Info.plist
   - Check camera permissions at runtime

3. **Document Processing Errors**
   - Ensure images are clear and well-lit
   - Verify document is fully visible in the frame
   - Check network connectivity for API calls

4. **Face Matching Issues**
   - Ensure face is clearly visible and well-lit
   - Check that the document contains a valid face photo

### Error Handling

Always implement proper error handling in your code:

```dart
try {
  // Acuant SDK method call
} on PlatformException catch (e) {
  print('Platform error: ${e.message}');
} catch (e) {
  print('General error: $e');
}
```

## Limitations

Currently, this plugin only supports iOS. Android support may be added in the future.

## License

This plugin is subject to Acuant's end user license agreement (EULA) as it integrates with the Acuant SDK.

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
* Flutter SDK

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

## Usage

```dart
import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';

// Initialize the SDK
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

// Capture front of ID document
final frontResult = await AcuantFlutterPlugin.captureFrontDocument();
String? frontImagePath = frontResult['imagePath'];

// Capture back of ID document
final backResult = await AcuantFlutterPlugin.captureBackDocument();
String? backImagePath = backResult['imagePath'];

// Process the document
if (frontImagePath != null && backImagePath != null) {
  final processResult = await AcuantFlutterPlugin.processDocument(
    frontImagePath: frontImagePath,
    backImagePath: backImagePath,
  );
  
  // Handle the results
  if (processResult['success'] == true) {
    // Access extracted fields
    final fields = processResult['fields'];
    final authResult = processResult['authenticationResult'];
    
    // Use the data as needed
    print('Document owner: ${fields['firstName']} ${fields['lastName']}');
  }
}

// Capture face
final faceResult = await AcuantFlutterPlugin.captureFace();
String? faceImagePath = faceResult['imagePath'];
```

## Limitations

Currently, this plugin only supports iOS. Android support may be added in the future.

## License

This plugin is subject to Acuant's end user license agreement (EULA) as it integrates with the Acuant SDK.

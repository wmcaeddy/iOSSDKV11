import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AcuantFlutterPlugin {
  static const MethodChannel _channel = MethodChannel('acuant_flutter_plugin');

  /// Initialize the Acuant SDK with credentials
  static Future<Map<String, dynamic>> initialize({
    required String username,
    required String password,
    required String subscription,
    required Map<String, String> endpoints,
  }) async {
    try {
      final result = await _channel.invokeMethod('initialize', {
        'username': username,
        'password': password,
        'subscription': subscription,
        'endpoints': endpoints,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  /// Capture front side of a document using native camera
  static Future<Map<String, dynamic>> captureFrontDocument() async {
    try {
      final result = await _channel.invokeMethod('captureFrontDocument');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  /// Capture back side of a document using native camera
  static Future<Map<String, dynamic>> captureBackDocument() async {
    try {
      final result = await _channel.invokeMethod('captureBackDocument');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  /// Capture face using native camera
  static Future<Map<String, dynamic>> captureFace() async {
    try {
      final result = await _channel.invokeMethod('captureFace');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  /// Process the captured document images
  static Future<Map<String, dynamic>> processDocument({
    required String frontImagePath,
    required String backImagePath,
  }) async {
    try {
      final result = await _channel.invokeMethod('processDocument', {
        'frontImagePath': frontImagePath,
        'backImagePath': backImagePath,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
  
  /// Get the SDK version information
  static Future<Map<String, dynamic>> getSdkVersion() async {
    try {
      final result = await _channel.invokeMethod('getSdkVersion');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
}

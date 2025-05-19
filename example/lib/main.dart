import 'package:flutter/material.dart';
import 'dart:async';

import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;
  String _statusMessage = 'Not initialized';
  String? _frontImagePath;
  String? _backImagePath;
  String? _facePath;
  Map<String, dynamic>? _documentData;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeSDK() async {
    setState(() {
      _statusMessage = 'Initializing...';
    });

    // Replace these with your Acuant credentials
    final Map<String, dynamic> result = await AcuantFlutterPlugin.initialize(
      username: 'acme_username',
      password: 'acme_password',
      subscription: 'acme_subscription',
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
      _isInitialized = result['success'] ?? false;
      _statusMessage = result['message'] ?? 'Unknown status';
    });
  }

  Future<void> _captureFrontDocument() async {
    if (!_isInitialized) {
      setState(() {
        _statusMessage = 'Please initialize SDK first';
      });
      return;
    }

    final result = await AcuantFlutterPlugin.captureFrontDocument();

    setState(() {
      _frontImagePath = result['imagePath'];
      _statusMessage =
          _frontImagePath != null
              ? 'Front document captured'
              : 'Front document capture failed';
    });
  }

  Future<void> _captureBackDocument() async {
    if (!_isInitialized) {
      setState(() {
        _statusMessage = 'Please initialize SDK first';
      });
      return;
    }

    final result = await AcuantFlutterPlugin.captureBackDocument();

    setState(() {
      _backImagePath = result['imagePath'];
      _statusMessage =
          _backImagePath != null
              ? 'Back document captured'
              : 'Back document capture failed';
    });
  }

  Future<void> _captureFace() async {
    if (!_isInitialized) {
      setState(() {
        _statusMessage = 'Please initialize SDK first';
      });
      return;
    }

    final result = await AcuantFlutterPlugin.captureFace();

    setState(() {
      _facePath = result['imagePath'];
      _statusMessage =
          _facePath != null ? 'Face captured' : 'Face capture failed';
    });
  }

  Future<void> _processDocument() async {
    if (_frontImagePath == null || _backImagePath == null) {
      setState(() {
        _statusMessage = 'Please capture both sides of the document';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Processing document...';
    });

    final result = await AcuantFlutterPlugin.processDocument(
      frontImagePath: _frontImagePath!,
      backImagePath: _backImagePath!,
    );

    setState(() {
      _documentData = result;
      _statusMessage =
          result['success'] ?? false
              ? 'Document processed successfully'
              : 'Document processing failed: ${result['message']}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Acuant Flutter Plugin Example')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Status: $_statusMessage'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeSDK,
                  child: const Text('Initialize Acuant SDK'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isInitialized ? _captureFrontDocument : null,
                  child: const Text('Capture Front Document'),
                ),
                if (_frontImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Front image saved at: $_frontImagePath',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isInitialized ? _captureBackDocument : null,
                  child: const Text('Capture Back Document'),
                ),
                if (_backImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Back image saved at: $_backImagePath',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isInitialized ? _captureFace : null,
                  child: const Text('Capture Face'),
                ),
                if (_facePath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Face image saved at: $_facePath',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      (_frontImagePath != null && _backImagePath != null)
                          ? _processDocument
                          : null,
                  child: const Text('Process Document'),
                ),
                if (_documentData != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Document Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_documentData.toString()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

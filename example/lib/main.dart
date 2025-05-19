import 'package:flutter/material.dart';
import 'dart:async';

import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acuant_flutter_plugin/settings_page.dart';
import 'package:acuant_flutter_plugin/info_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDV Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

    // Get settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final subscription = prefs.getString('subscription') ?? '';
    
    // Check if settings are available
    if (username.isEmpty || password.isEmpty || subscription.isEmpty) {
      setState(() {
        _statusMessage = 'Please configure settings first';
      });
      
      // Navigate to settings page if not configured
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
      
      if (result == true) {
        // If settings were saved, try initializing again
        _initializeSDK();
      }
      return;
    }

    // Get endpoints from SharedPreferences
    final endpoints = {
      'frm_endpoint': prefs.getString('frm_endpoint') ?? 'https://frm.acuant.net',
      'passive_liveness_endpoint': prefs.getString('passive_liveness_endpoint') ?? 'https://us.passlive.acuant.net',
      'med_endpoint': prefs.getString('med_endpoint') ?? 'https://medicscan.acuant.net',
      'assureid_endpoint': prefs.getString('assureid_endpoint') ?? 'https://services.assureid.net',
      'acas_endpoint': prefs.getString('acas_endpoint') ?? 'https://acas.acuant.net',
      'ozone_endpoint': prefs.getString('ozone_endpoint') ?? 'https://ozone.acuant.net',
    };

    // Initialize SDK with saved settings
    final Map<String, dynamic> result = await AcuantFlutterPlugin.initialize(
      username: username,
      password: password,
      subscription: subscription,
      endpoints: endpoints,
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
  
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => const InfoDialog(),
    );
  }
  
  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    
    if (result == true) {
      // If settings were updated, reset the SDK
      setState(() {
        _isInitialized = false;
        _statusMessage = 'Settings updated, please initialize SDK';
        _frontImagePath = null;
        _backImagePath = null;
        _facePath = null;
        _documentData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acuant Flutter Plugin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'App Information',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Status: $_statusMessage',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acuant_flutter_plugin/settings_page.dart';
import 'package:acuant_flutter_plugin/info_dialog.dart';
import 'package:acuant_flutter_plugin/config_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Acuant SDK Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isInitializing = false;
  String? _frontImagePath;
  String? _backImagePath;
  String? _faceImagePath;
  Map<String, dynamic>? _documentData;
  Map<String, dynamic>? _authenticationResult;
  double? _faceMatchScore;
  bool? _isFaceMatched;
  bool _isProcessing = false;
  bool _isMatching = false;
  
  // Add a list to store logs
  List<String> _logs = [];
  bool _showLogs = false;
  
  // Method to add logs
  void _addLog(String log) {
    setState(() {
      _logs.add("${DateTime.now().toString().split('.').first}: $log");
      // Keep only the last 100 logs to prevent memory issues
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasConfig = prefs.getString('acuant_username') != null &&
          prefs.getString('acuant_password') != null &&
          prefs.getString('acuant_subscription') != null;

      if (!hasConfig) {
        // Show configuration screen if no configuration exists
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConfigScreen(),
          ),
        );

        if (result == true) {
          await _initializeSDK();
        }
      } else {
        await _initializeSDK();
      }
    } catch (e) {
      print('Error checking configuration: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeSDK() async {
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
    });
    
    _addLog("Initializing Acuant SDK...");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final initResult = await AcuantFlutterPlugin.initialize(
        username: prefs.getString('acuant_username') ?? '',
        password: prefs.getString('acuant_password') ?? '',
        subscription: prefs.getString('acuant_subscription') ?? '',
        endpoints: {
          'frm_endpoint': prefs.getString('frm_endpoint') ?? 'https://frm.acuant.net',
          'passive_liveness_endpoint': prefs.getString('passive_liveness_endpoint') ?? 'https://us.passlive.acuant.net',
          'med_endpoint': prefs.getString('med_endpoint') ?? 'https://medicscan.acuant.net',
          'assureid_endpoint': prefs.getString('assureid_endpoint') ?? 'https://services.assureid.net',
          'acas_endpoint': prefs.getString('acas_endpoint') ?? 'https://acas.acuant.net',
          'ozone_endpoint': prefs.getString('ozone_endpoint') ?? 'https://ozone.acuant.net',
        },
      );

      setState(() {
        _isInitializing = false;
        _isInitialized = initResult['success'] == true;
      });
      
      _addLog("SDK Initialization result: ${initResult['success'] ? 'Success' : 'Failed'} - ${initResult['message']}");
      
      if (initResult['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SDK initialized successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize SDK: ${initResult['message']}')),
        );
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      _addLog("SDK Initialization error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openConfiguration() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfigScreen(),
      ),
    );

    if (result == true) {
      await _initializeSDK();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acuant SDK Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openConfiguration,
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => InfoDialog(),
              );
            },
          ),
          IconButton(
            icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showLogs = !_showLogs;
              });
            },
            tooltip: _showLogs ? 'Hide Logs' : 'Show Logs',
          ),
        ],
      ),
      body: _showLogs 
          ? _buildLogsView() 
          : _isLoading
              ? Center(child: CircularProgressIndicator())
              : _isInitialized
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Acuant SDK Initialized',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DocumentVerificationScreen(),
                                ),
                              );
                            },
                            child: Text('Start Document Verification'),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Acuant SDK Not Initialized',
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _openConfiguration,
                            child: Text('Configure SDK'),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLogsView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text(
                  _logs[index],
                  style: TextStyle(fontSize: 12, fontFamily: 'Courier'),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
            child: Text('Clear Logs'),
          ),
        ),
      ],
    );
  }
}

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
  
  void _addLog(String log) {
    if (context.findAncestorStateOfType<_HomeScreenState>() != null) {
      context.findAncestorStateOfType<_HomeScreenState>()!._addLog(log);
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
      body: SingleChildScrollView(
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
      _addLog("Starting front document capture...");
      final frontResult = await AcuantFlutterPlugin.captureFrontDocument();
      _addLog("Front document capture result: ${frontResult['success'] ? 'Success' : 'Failed'}");
      
      if (frontResult['success'] == true) {
        setState(() {
          _frontImagePath = frontResult['imagePath'];
        });
        _addLog("Front image saved at: ${frontResult['imagePath']}");
      } else {
        _addLog("Failed to capture front document: ${frontResult['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture front of document')),
        );
      }
    } catch (e) {
      _addLog("Front document capture error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _captureBackOfDocument() async {
    try {
      _addLog("Starting back document capture...");
      final backResult = await AcuantFlutterPlugin.captureBackDocument();
      _addLog("Back document capture result: ${backResult['success'] ? 'Success' : 'Failed'}");
      
      if (backResult['success'] == true) {
        setState(() {
          _backImagePath = backResult['imagePath'];
        });
        _addLog("Back image saved at: ${backResult['imagePath']}");
      } else {
        _addLog("Failed to capture back document: ${backResult['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture back of document')),
        );
      }
    } catch (e) {
      _addLog("Back document capture error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _captureFace() async {
    try {
      _addLog("Starting face capture...");
      final faceResult = await AcuantFlutterPlugin.captureFace();
      _addLog("Face capture result: ${faceResult['success'] ? 'Success' : 'Failed'}");
      
      if (faceResult['success'] == true) {
        setState(() {
          _faceImagePath = faceResult['imagePath'];
        });
        _addLog("Face image saved at: ${faceResult['imagePath']}");
      } else {
        _addLog("Failed to capture face: ${faceResult['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture face')),
        );
      }
    } catch (e) {
      _addLog("Face capture error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _processDocument() async {
    if (_frontImagePath == null || _backImagePath == null) {
      _addLog("Cannot process document: Missing front or back images");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Both front and back images must be captured first')),
      );
      return;
    }
    
    try {
      setState(() {
        _isProcessing = true;
      });
      
      _addLog("Starting document processing...");
      _addLog("Front image: $_frontImagePath");
      _addLog("Back image: $_backImagePath");
      
      final processResult = await AcuantFlutterPlugin.processDocument(
        frontImagePath: _frontImagePath!,
        backImagePath: _backImagePath!,
      );
      
      setState(() {
        _isProcessing = false;
      });
      
      _addLog("Document processing result: ${processResult['success'] ? 'Success' : 'Failed'}");
      
      if (processResult['success'] == true) {
        setState(() {
          _documentData = processResult['fields'];
          _authenticationResult = processResult['authenticationResult'];
        });
        
        _addLog("Document data received: ${_documentData?.keys.join(', ')}");
        _addLog("Authentication result: ${_authenticationResult?['result']} (Score: ${_authenticationResult?['score']})");
      } else {
        _addLog("Failed to process document: ${processResult['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process document')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _addLog("Document processing error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _performFaceMatch() async {
    if (_faceImagePath == null || _documentData == null) {
      _addLog("Cannot perform face match: Missing face image or document data");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Face image and document data must be available first')),
      );
      return;
    }
    
    try {
      setState(() {
        _isMatching = true;
      });
      
      _addLog("Starting face matching...");
      _addLog("Face image: $_faceImagePath");
      _addLog("Document image: ${_documentData?['photoPath'] ?? 'null'}");
      
      final matchResult = await AcuantFlutterPlugin.matchFace(
        faceImagePath: _faceImagePath!,
        documentImagePath: _documentData!['photoPath'] ?? "null",
      );
      
      setState(() {
        _isMatching = false;
      });
      
      _addLog("Face matching result: ${matchResult['success'] ? 'Success' : 'Failed'}");
      
      if (matchResult['success'] == true) {
        setState(() {
          _faceMatchScore = matchResult['score'];
          _isFaceMatched = matchResult['isMatch'];
        });
        
        _addLog("Face match score: $_faceMatchScore");
        _addLog("Is face matched: $_isFaceMatched");
      } else {
        _addLog("Failed to match face: ${matchResult['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to match face')),
        );
      }
    } catch (e) {
      setState(() {
        _isMatching = false;
      });
      _addLog("Face matching error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

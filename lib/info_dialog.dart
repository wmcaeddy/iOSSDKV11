import 'package:flutter/material.dart';
import 'package:acuant_flutter_plugin/acuant_flutter_plugin.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InfoDialog extends StatefulWidget {
  const InfoDialog({Key? key}) : super(key: key);

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  bool _isLoading = true;
  String _flutterVersion = '';
  String _dartVersion = '';
  String _sdkVersion = '';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      // Get Flutter package info
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Get SDK version through plugin
      final sdkVersionInfo = await AcuantFlutterPlugin.getSdkVersion();
      
      setState(() {
        // Hard-coded Flutter and Dart versions
        _flutterVersion = '3.29.3';
        _dartVersion = '3.7.2';
        
        // App and SDK versions
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _sdkVersion = sdkVersionInfo['sdkVersion'] ?? 'Unknown';
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _flutterVersion = 'Error: ${e.message}';
        _dartVersion = 'Error: ${e.message}';
        _appVersion = 'Error: ${e.message}';
        _sdkVersion = 'Error: ${e.message}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('App Information'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Flutter Version', _flutterVersion),
                const SizedBox(height: 8),
                _buildInfoRow('Dart Version', _dartVersion),
                const SizedBox(height: 8),
                _buildInfoRow('App Version', _appVersion),
                const SizedBox(height: 8),
                _buildInfoRow('SDK Version', _sdkVersion),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value),
        ),
      ],
    );
  }
} 
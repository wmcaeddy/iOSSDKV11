import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigScreen extends StatefulWidget {
  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subscriptionController = TextEditingController();
  final _frmEndpointController = TextEditingController();
  final _passiveLivenessEndpointController = TextEditingController();
  final _medEndpointController = TextEditingController();
  final _assureidEndpointController = TextEditingController();
  final _acasEndpointController = TextEditingController();
  final _ozoneEndpointController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _subscriptionController.dispose();
    _frmEndpointController.dispose();
    _passiveLivenessEndpointController.dispose();
    _medEndpointController.dispose();
    _assureidEndpointController.dispose();
    _acasEndpointController.dispose();
    _ozoneEndpointController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _usernameController.text = prefs.getString('acuant_username') ?? '';
        _passwordController.text = prefs.getString('acuant_password') ?? '';
        _subscriptionController.text = prefs.getString('acuant_subscription') ?? '';
        _frmEndpointController.text = prefs.getString('frm_endpoint') ?? 'https://frm.acuant.net';
        _passiveLivenessEndpointController.text = prefs.getString('passive_liveness_endpoint') ?? 'https://us.passlive.acuant.net';
        _medEndpointController.text = prefs.getString('med_endpoint') ?? 'https://medicscan.acuant.net';
        _assureidEndpointController.text = prefs.getString('assureid_endpoint') ?? 'https://services.assureid.net';
        _acasEndpointController.text = prefs.getString('acas_endpoint') ?? 'https://acas.acuant.net';
        _ozoneEndpointController.text = prefs.getString('ozone_endpoint') ?? 'https://ozone.acuant.net';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading configuration: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('acuant_username', _usernameController.text);
      await prefs.setString('acuant_password', _passwordController.text);
      await prefs.setString('acuant_subscription', _subscriptionController.text);
      await prefs.setString('frm_endpoint', _frmEndpointController.text);
      await prefs.setString('passive_liveness_endpoint', _passiveLivenessEndpointController.text);
      await prefs.setString('med_endpoint', _medEndpointController.text);
      await prefs.setString('assureid_endpoint', _assureidEndpointController.text);
      await prefs.setString('acas_endpoint', _acasEndpointController.text);
      await prefs.setString('ozone_endpoint', _ozoneEndpointController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration saved successfully')),
      );
      
      Navigator.of(context).pop(true); // Return true to indicate successful save
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configuration: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acuant SDK Configuration'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveConfig,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection(
                      'Credentials',
                      [
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _subscriptionController,
                          label: 'Subscription',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your subscription';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    _buildSection(
                      'Endpoints',
                      [
                        _buildTextField(
                          controller: _frmEndpointController,
                          label: 'FRM Endpoint',
                          validator: _validateUrl,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _passiveLivenessEndpointController,
                          label: 'Passive Liveness Endpoint',
                          validator: _validateUrl,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _medEndpointController,
                          label: 'Med Endpoint',
                          validator: _validateUrl,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _assureidEndpointController,
                          label: 'AssureID Endpoint',
                          validator: _validateUrl,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _acasEndpointController,
                          label: 'ACAS Endpoint',
                          validator: _validateUrl,
                        ),
                        SizedBox(height: 16),
                        _buildTextField(
                          controller: _ozoneEndpointController,
                          label: 'Ozone Endpoint',
                          validator: _validateUrl,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveConfig,
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Save Configuration'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a URL';
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }
    return null;
  }
} 
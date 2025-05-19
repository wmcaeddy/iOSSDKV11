import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    
    _usernameController.text = prefs.getString('username') ?? '';
    _passwordController.text = prefs.getString('password') ?? '';
    _subscriptionController.text = prefs.getString('subscription') ?? '';
    _frmEndpointController.text = prefs.getString('frm_endpoint') ?? 'https://frm.acuant.net';
    _passiveLivenessEndpointController.text = prefs.getString('passive_liveness_endpoint') ?? 'https://us.passlive.acuant.net';
    _medEndpointController.text = prefs.getString('med_endpoint') ?? 'https://medicscan.acuant.net';
    _assureidEndpointController.text = prefs.getString('assureid_endpoint') ?? 'https://services.assureid.net';
    _acasEndpointController.text = prefs.getString('acas_endpoint') ?? 'https://acas.acuant.net';
    _ozoneEndpointController.text = prefs.getString('ozone_endpoint') ?? 'https://ozone.acuant.net';

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('username', _usernameController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setString('subscription', _subscriptionController.text);
      await prefs.setString('frm_endpoint', _frmEndpointController.text);
      await prefs.setString('passive_liveness_endpoint', _passiveLivenessEndpointController.text);
      await prefs.setString('med_endpoint', _medEndpointController.text);
      await prefs.setString('assureid_endpoint', _assureidEndpointController.text);
      await prefs.setString('acas_endpoint', _acasEndpointController.text);
      await prefs.setString('ozone_endpoint', _ozoneEndpointController.text);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      
      Navigator.pop(context, true); // Return true to indicate settings were saved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SDK Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acuant SDK Credentials',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subscriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Subscription ID',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter subscription ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Endpoints Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _frmEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'FRM Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter FRM endpoint';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passiveLivenessEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'Passive Liveness Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter passive liveness endpoint';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _medEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'MED Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter MED endpoint';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _assureidEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'AssureID Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter AssureID endpoint';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _acasEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'ACAS Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter ACAS endpoint';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ozoneEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'Ozone Endpoint',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter Ozone endpoint';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 
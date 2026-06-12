import 'package:flutter/material.dart';

import '../../models/drone_connection.dart';
import '../../services/drone_api_client.dart';

class DjiConnectionDialog extends StatefulWidget {
  const DjiConnectionDialog({
    required this.droneClient,
    required this.onSaved,
    super.key,
  });

  final DroneApiClient droneClient;
  final VoidCallback onSaved;

  @override
  State<DjiConnectionDialog> createState() => _DjiConnectionDialogState();
}

class _DjiConnectionDialogState extends State<DjiConnectionDialog> {
  late Future<DjiConnectionConfig> _configFuture;
  final _formKey = GlobalKey<FormState>();
  final _ingestToken = TextEditingController();
  final _operatorLabel = TextEditingController();
  final _cloudHost = TextEditingController();
  final _cloudPort = TextEditingController(text: '8883');
  final _cloudUsername = TextEditingController();
  final _cloudPassword = TextEditingController();
  final _cloudClientId = TextEditingController(text: 'firedrone-web-connector');
  final _cloudAppId = TextEditingController();
  final _cloudAppKey = TextEditingController();
  final _cloudAppLicense = TextEditingController();
  final _workspaceId = TextEditingController();
  String _mode = 'cloud-api';
  bool _saving = false;
  bool _generatingToken = false;
  bool _advancedOpen = false;
  bool _seeded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _configFuture = widget.droneClient.fetchConnectionConfig();
  }

  @override
  void dispose() {
    _ingestToken.dispose();
    _operatorLabel.dispose();
    _cloudHost.dispose();
    _cloudPort.dispose();
    _cloudUsername.dispose();
    _cloudPassword.dispose();
    _cloudClientId.dispose();
    _cloudAppId.dispose();
    _cloudAppKey.dispose();
    _cloudAppLicense.dispose();
    _workspaceId.dispose();
    super.dispose();
  }

  void _seed(DjiConnectionConfig config) {
    if (_seeded) return;
    _seeded = true;
    if (config.mode == 'cloud-api' || config.mode == 'mobile-sdk') {
      _mode = config.mode;
    }
    _operatorLabel.text = config.operatorLabel;
    if (config.cloudMqttClientId.isNotEmpty) {
      _cloudClientId.text = config.cloudMqttClientId;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.droneClient.saveConnectionConfig(
        DjiConnectionRequest(
          mode: _mode,
          ingestToken: _ingestToken.text.trim(),
          operatorLabel: _operatorLabel.text.trim(),
          cloudMqttHost: _cloudHost.text.trim(),
          cloudMqttPort: int.tryParse(_cloudPort.text.trim()) ?? 8883,
          cloudMqttUsername: _cloudUsername.text.trim(),
          cloudMqttPassword: _cloudPassword.text,
          cloudMqttClientId: _cloudClientId.text.trim(),
          cloudApiAppId: _cloudAppId.text.trim(),
          cloudApiAppKey: _cloudAppKey.text,
          cloudApiAppLicense: _cloudAppLicense.text,
          workspaceId: _workspaceId.text.trim(),
        ),
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  Future<void> _generateToken() async {
    setState(() {
      _generatingToken = true;
      _error = null;
    });
    try {
      final token = await widget.droneClient.generateConnectionToken();
      if (!mounted) return;
      setState(() {
        _ingestToken.text = token;
        _generatingToken = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _generatingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: FutureBuilder<DjiConnectionConfig>(
          future: _configFuture,
          builder: (context, snapshot) {
            final config = snapshot.data;
            if (config != null) _seed(config);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Connect DJI',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'cloud-api',
                          icon: Icon(Icons.cloud_queue),
                          label: Text('Cloud API'),
                        ),
                        ButtonSegment(
                          value: 'mobile-sdk',
                          icon: Icon(Icons.phone_android),
                          label: Text('Mobile SDK'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _saving
                          ? null
                          : (value) => setState(() => _mode = value.first),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ingestToken,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Backend ingest token',
                              hintText: config?.ingestTokenConfigured ?? false
                                  ? 'Leave blank to keep saved token'
                                  : 'Generate a secure bridge token',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((config?.ingestTokenConfigured ?? false) ||
                                  (value?.trim().isNotEmpty ?? false)) {
                                return null;
                              }
                              return 'Generate or enter an ingest token';
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _generatingToken ? null : _generateToken,
                            icon: _generatingToken
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_fix_high),
                            label: Text(
                              _generatingToken
                                  ? 'Generating'
                                  : 'Generate token',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This token protects the backend ingest endpoint. Save it, then use the same token in the Cloud API worker or Mobile SDK bridge.',
                      style: TextStyle(color: Color(0xff64736d), height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _operatorLabel,
                      decoration: const InputDecoration(
                        labelText: 'Operator label',
                        hintText: 'Incident command laptop, RC Pro, Station 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_mode == 'cloud-api')
                      _CloudApiFields(
                        cloudHost: _cloudHost,
                        cloudPort: _cloudPort,
                        cloudUsername: _cloudUsername,
                        cloudPassword: _cloudPassword,
                        cloudClientId: _cloudClientId,
                        cloudAppId: _cloudAppId,
                        cloudAppKey: _cloudAppKey,
                        cloudAppLicense: _cloudAppLicense,
                        workspaceId: _workspaceId,
                        config: config,
                        advancedOpen: _advancedOpen,
                        onAdvancedChanged: (value) =>
                            setState(() => _advancedOpen = value),
                      )
                    else
                      _MobileSdkInstructions(config: config),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xffb3261e),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.link),
                            label: Text(
                              _saving ? 'Saving...' : 'Save connection',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CloudApiFields extends StatelessWidget {
  const _CloudApiFields({
    required this.cloudHost,
    required this.cloudPort,
    required this.cloudUsername,
    required this.cloudPassword,
    required this.cloudClientId,
    required this.cloudAppId,
    required this.cloudAppKey,
    required this.cloudAppLicense,
    required this.workspaceId,
    required this.config,
    required this.advancedOpen,
    required this.onAdvancedChanged,
  });

  final TextEditingController cloudHost;
  final TextEditingController cloudPort;
  final TextEditingController cloudUsername;
  final TextEditingController cloudPassword;
  final TextEditingController cloudClientId;
  final TextEditingController cloudAppId;
  final TextEditingController cloudAppKey;
  final TextEditingController cloudAppLicense;
  final TextEditingController workspaceId;
  final DjiConnectionConfig? config;
  final bool advancedOpen;
  final ValueChanged<bool> onAdvancedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: cloudHost,
          decoration: InputDecoration(
            labelText: 'DJI Cloud MQTT host',
            hintText: config?.cloudMqttHostConfigured ?? false
                ? 'Leave blank to keep saved host'
                : 'mqtt.example.com',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if ((config?.cloudMqttHostConfigured ?? false) ||
                (value?.trim().isNotEmpty ?? false)) {
              return null;
            }
            return 'Enter the DJI Cloud MQTT host';
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cloudUsername,
          decoration: InputDecoration(
            labelText: 'MQTT username',
            hintText: config?.cloudMqttUsernameConfigured ?? false
                ? 'Saved'
                : 'DJI Cloud username',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cloudPassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'MQTT password',
            hintText: 'Leave blank to keep saved password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: advancedOpen,
          onChanged: onAdvancedChanged,
          title: const Text(
            'Advanced settings',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Port, Client ID, workspace, app key, license'),
        ),
        if (advancedOpen) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: cloudPort,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'MQTT port',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: cloudClientId,
                  decoration: const InputDecoration(
                    labelText: 'Client ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: workspaceId,
            decoration: InputDecoration(
              labelText: 'Workspace ID',
              hintText: config?.workspaceIdConfigured ?? false
                  ? 'Saved'
                  : 'DJI workspace identifier',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cloudAppId,
            decoration: InputDecoration(
              labelText: 'Cloud API App ID',
              hintText: config?.appIdConfigured ?? false ? 'Saved' : 'Optional',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cloudAppKey,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Cloud API App Key',
              hintText: 'Leave blank to keep saved key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: cloudAppLicense,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Cloud API App License',
              hintText: 'Leave blank to keep saved license',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }
}

class _MobileSdkInstructions extends StatelessWidget {
  const _MobileSdkInstructions({required this.config});

  final DjiConnectionConfig? config;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffeef4f1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd2d8d5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mobile SDK bridge',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this endpoint in the Android DJI Mobile SDK app after saving.',
          ),
          const SizedBox(height: 10),
          SelectableText(
            config?.mobileBridgeEndpoint.isNotEmpty ?? false
                ? config!.mobileBridgeEndpoint
                : 'http://<backend-host>:5000/api/dji/ingest/mobile-sdk',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

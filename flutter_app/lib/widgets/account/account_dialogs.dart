import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_api_client.dart';
import '../../services/browser_redirect.dart';

class AccountAuthDialog extends StatefulWidget {
  const AccountAuthDialog({
    required this.accountClient,
    required this.onSignedIn,
    super.key,
  });

  final AccountApiClient accountClient;
  final ValueChanged<AccountSession> onSignedIn;

  @override
  State<AccountAuthDialog> createState() => _AccountAuthDialogState();
}

class _AccountAuthDialogState extends State<AccountAuthDialog> {
  final _email = TextEditingController(text: 'pilot@example.com');
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _organization = TextEditingController();
  late Future<GoogleOAuthStatus> _googleStatusFuture;
  bool _registerMode = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _googleStatusFuture = widget.accountClient.fetchGoogleOAuthStatus();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    _organization.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = _registerMode
          ? await widget.accountClient.register(
              email: _email.text,
              password: _password.text,
              displayName: _displayName.text,
              organization: _organization.text,
            )
          : await widget.accountClient.login(
              email: _email.text,
              password: _password.text,
            );
      widget.onSignedIn(session);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final authorizationUrl = await widget.accountClient.startGoogleOAuth(
        returnUrl: currentAppUrl(),
      );
      redirectToExternalUrl(authorizationUrl);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _openGoogleSetup(GoogleOAuthStatus status) async {
    final saved = await showDialog<GoogleOAuthStatus>(
      context: context,
      builder: (context) => GoogleOAuthSetupDialog(
        status: status,
        accountClient: widget.accountClient,
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      _googleStatusFuture = Future.value(saved);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_registerMode ? 'Create account' : 'Sign in'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Sign in'),
                    icon: Icon(Icons.login),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Create account'),
                    icon: Icon(Icons.person_add_alt),
                  ),
                ],
                selected: {_registerMode},
                onSelectionChanged: (value) {
                  setState(() => _registerMode = value.first);
                },
              ),
              const SizedBox(height: 14),
              FutureBuilder<GoogleOAuthStatus>(
                future: _googleStatusFuture,
                builder: (context, snapshot) {
                  final status = snapshot.data;
                  final configured = status?.configured ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: configured && !_submitting
                            ? _continueWithGoogle
                            : null,
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Continue with Google'),
                      ),
                      if (status != null && !configured) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Google login not configured',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xff8a4b00),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.missingConfiguration.join(', '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xff6f625b)),
                        ),
                        const SizedBox(height: 10),
                        if (status.setupAllowed)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _submitting
                                  ? null
                                  : () => _openGoogleSetup(status),
                              icon: const Icon(Icons.tune),
                              label: const Text('Configure Google login'),
                            ),
                          )
                        else
                          Text(
                            'Local setup required',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xff6f625b),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('account-email-field'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('account-password-field'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (_registerMode) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('account-display-name-field'),
                  controller: _displayName,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('account-organization-field'),
                  controller: _organization,
                  decoration: const InputDecoration(
                    labelText: 'Organization',
                    prefixIcon: Icon(Icons.business_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xffb3261e)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_registerMode ? Icons.person_add_alt : Icons.login),
          label: Text(_registerMode ? 'Create workspace' : 'Sign in'),
        ),
      ],
    );
  }
}

class GoogleOAuthSetupDialog extends StatefulWidget {
  const GoogleOAuthSetupDialog({
    required this.status,
    required this.accountClient,
    super.key,
  });

  final GoogleOAuthStatus status;
  final AccountApiClient accountClient;

  @override
  State<GoogleOAuthSetupDialog> createState() => _GoogleOAuthSetupDialogState();
}

class _GoogleOAuthSetupDialogState extends State<GoogleOAuthSetupDialog> {
  static const _googleCloudCredentialsUrl =
      'https://console.cloud.google.com/apis/credentials';

  late final TextEditingController _clientId;
  late final TextEditingController _clientSecret;
  late final TextEditingController _redirectUri;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientId = TextEditingController();
    _clientSecret = TextEditingController();
    _redirectUri = TextEditingController(text: widget.status.redirectUri);
  }

  @override
  void dispose() {
    _clientId.dispose();
    _clientSecret.dispose();
    _redirectUri.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final status = await widget.accountClient.saveGoogleOAuthConfig(
        clientId: _clientId.text,
        clientSecret: _clientSecret.text,
        redirectUri: _redirectUri.text,
      );
      if (mounted) {
        Navigator.of(context).pop(status);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _copyRedirectUri() async {
    await Clipboard.setData(ClipboardData(text: _redirectUri.text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Redirect URI copied')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Google OAuth setup'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('google-client-id-field'),
                controller: _clientId,
                decoration: const InputDecoration(
                  labelText: 'OAuth Client ID',
                  prefixIcon: Icon(Icons.key_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('google-client-secret-field'),
                controller: _clientSecret,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'OAuth Client Secret',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('google-redirect-uri-field'),
                controller: _redirectUri,
                decoration: const InputDecoration(
                  labelText: 'Authorized redirect URI',
                  prefixIcon: Icon(Icons.route_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        openExternalUrl(_googleCloudCredentialsUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Google Cloud'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _copyRedirectUri,
                    icon: const Icon(Icons.content_copy),
                    label: const Text('Copy redirect URI'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                'Scope: ${widget.status.scope}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xff62716c)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xffb3261e))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save Google config'),
        ),
      ],
    );
  }
}

class AccountDataDialog extends StatefulWidget {
  const AccountDataDialog({
    required this.session,
    required this.accountClient,
    required this.onSaved,
    required this.onSignOut,
    super.key,
  });

  final AccountSession session;
  final AccountApiClient accountClient;
  final ValueChanged<AccountData> onSaved;
  final VoidCallback onSignOut;

  @override
  State<AccountDataDialog> createState() => _AccountDataDialogState();
}

class _AccountDataDialogState extends State<AccountDataDialog> {
  late final TextEditingController _workspaceId;
  late final TextEditingController _operatorLabel;
  late final TextEditingController _defaultScenario;
  late String _mapBasemap;
  late bool _safetyChecklistRequired;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final data = widget.session.account.data;
    _workspaceId = TextEditingController(text: data.djiConnection.workspaceId);
    _operatorLabel = TextEditingController(
      text: data.djiConnection.operatorLabel,
    );
    _defaultScenario = TextEditingController(
      text: data.missionPreferences.defaultScenario,
    );
    _mapBasemap = data.missionPreferences.mapBasemap;
    _safetyChecklistRequired = data.missionPreferences.safetyChecklistRequired;
  }

  @override
  void dispose() {
    _workspaceId.dispose();
    _operatorLabel.dispose();
    _defaultScenario.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    final current = widget.session.account.data;
    final data = current.copyWith(
      djiConnection: current.djiConnection.copyWith(
        mode: _workspaceId.text.trim().isEmpty ? 'not-configured' : 'cloud-api',
        operatorLabel: _operatorLabel.text.trim(),
        workspaceId: _workspaceId.text.trim(),
      ),
      missionPreferences: current.missionPreferences.copyWith(
        defaultScenario: _defaultScenario.text.trim().isEmpty
            ? 'Canyon Ridge Fire'
            : _defaultScenario.text.trim(),
        mapBasemap: _mapBasemap,
        safetyChecklistRequired: _safetyChecklistRequired,
      ),
    );
    try {
      final saved = await widget.accountClient.updateAccountData(
        token: widget.session.token,
        data: data,
      );
      widget.onSaved(saved);
      if (mounted) {
        setState(() => _saved = true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Account Data'),
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actionsOverflowButtonSpacing: 8,
      actionsOverflowDirection: VerticalDirection.down,
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account-bound mission data',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('account-workspace-field'),
                controller: _workspaceId,
                decoration: const InputDecoration(
                  labelText: 'Workspace ID',
                  prefixIcon: Icon(Icons.cloud_queue),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _operatorLabel,
                decoration: const InputDecoration(
                  labelText: 'Operator label',
                  prefixIcon: Icon(Icons.groups_2_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _defaultScenario,
                decoration: const InputDecoration(
                  labelText: 'Default scenario',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _mapBasemap,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Default map',
                  prefixIcon: Icon(Icons.layers_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'satellite',
                    child: Text('Satellite imagery'),
                  ),
                  DropdownMenuItem(value: 'streets', child: Text('Street map')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _mapBasemap = value);
                  }
                },
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require safety checklist'),
                value: _safetyChecklistRequired,
                onChanged: (value) {
                  setState(() => _safetyChecklistRequired = value);
                },
              ),
              if (_saved)
                const Text(
                  'Saved to account',
                  style: TextStyle(
                    color: Color(0xff12805c),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Color(0xffb3261e))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onSignOut();
                },
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save account data'),
        ),
      ],
    );
  }
}

class AccountAccessPanel extends StatelessWidget {
  const AccountAccessPanel({
    required this.session,
    required this.onSignIn,
    required this.onAccountData,
    required this.onSignOut,
    this.dark = false,
    super.key,
  });

  final AccountSession? session;
  final VoidCallback onSignIn;
  final VoidCallback onAccountData;
  final VoidCallback onSignOut;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : const Color(0xff12231e);
    final subtle = dark ? const Color(0xff9fb3ad) : const Color(0xff66756f);
    if (session == null) {
      return OutlinedButton.icon(
        onPressed: onSignIn,
        icon: const Icon(Icons.account_circle_outlined),
        label: const Text('Sign in'),
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? Colors.white : const Color(0xff0b6f55),
          side: BorderSide(
            color: dark ? const Color(0xff44645a) : const Color(0xffb7cbc3),
          ),
        ),
      );
    }

    final account = session!.account;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xff101b1f) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dark ? const Color(0xff20333a) : const Color(0xffd5e4df),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: dark ? const Color(0xffb7f1d8) : const Color(0xff12805c),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  account.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            account.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAccountData,
                icon: const Icon(Icons.dataset_linked_outlined),
                label: const Text('Account Data'),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                color: dark ? Colors.white : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

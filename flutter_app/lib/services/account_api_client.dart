import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

abstract class AccountApiClient {
  Future<AccountSession> register({
    required String email,
    required String password,
    required String displayName,
    required String organization,
  });

  Future<AccountSession> login({
    required String email,
    required String password,
  });

  Future<AccountSession> currentAccount(String token);

  Future<void> logout(String token);

  Future<AccountSession> completeLoginCode(String loginCode);

  Future<GoogleOAuthStatus> fetchGoogleOAuthStatus();

  Future<GoogleOAuthStatus> saveGoogleOAuthConfig({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  });

  Future<String> startGoogleOAuth({required String returnUrl});

  Future<AccountData> fetchAccountData(String token);

  Future<AccountData> updateAccountData({
    required String token,
    required AccountData data,
  });
}

class HttpAccountApiClient implements AccountApiClient {
  HttpAccountApiClient({Uri? baseUri, http.Client? client})
    : baseUri = baseUri ?? defaultApiBaseUri(),
      _client = client ?? http.Client();

  final Uri baseUri;
  final http.Client _client;

  Uri _uri(String path) => apiUri(baseUri, path);

  Map<String, String> _headers([String? token]) {
    return {
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw StateError(json['error'] as String? ?? 'Account request failed');
    }
    return json;
  }

  @override
  Future<AccountSession> register({
    required String email,
    required String password,
    required String displayName,
    required String organization,
  }) async {
    final response = await _client.post(
      _uri('/accounts/register'),
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'displayName': displayName,
        'organization': organization,
      }),
    );
    return AccountSession.fromJson(await _decode(response));
  }

  @override
  Future<AccountSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/accounts/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return AccountSession.fromJson(await _decode(response));
  }

  @override
  Future<AccountSession> currentAccount(String token) async {
    final response = await _client.get(
      _uri('/accounts/me'),
      headers: _headers(token),
    );
    final json = await _decode(response);
    return AccountSession(
      token: token,
      tokenType: 'Bearer',
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> logout(String token) async {
    final response = await _client.post(
      _uri('/accounts/logout'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    await _decode(response);
  }

  @override
  Future<AccountSession> completeLoginCode(String loginCode) async {
    final response = await _client.post(
      _uri('/accounts/session/complete'),
      headers: _headers(),
      body: jsonEncode({'loginCode': loginCode}),
    );
    return AccountSession.fromJson(await _decode(response));
  }

  @override
  Future<GoogleOAuthStatus> fetchGoogleOAuthStatus() async {
    final response = await _client.get(_uri('/accounts/google/status'));
    return GoogleOAuthStatus.fromJson(await _decode(response));
  }

  @override
  Future<GoogleOAuthStatus> saveGoogleOAuthConfig({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
  }) async {
    final response = await _client.put(
      _uri('/accounts/google/config'),
      headers: _headers(),
      body: jsonEncode({
        'clientId': clientId,
        'clientSecret': clientSecret,
        'redirectUri': redirectUri,
      }),
    );
    return GoogleOAuthStatus.fromJson(await _decode(response));
  }

  @override
  Future<String> startGoogleOAuth({required String returnUrl}) async {
    final uri = _uri(
      '/accounts/google/start',
    ).replace(queryParameters: {'returnUrl': returnUrl});
    final response = await _client.get(uri);
    final json = await _decode(response);
    return json['authorizationUrl'] as String? ?? '';
  }

  @override
  Future<AccountData> fetchAccountData(String token) async {
    final response = await _client.get(
      _uri('/accounts/data'),
      headers: _headers(token),
    );
    final json = await _decode(response);
    return AccountData.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }

  @override
  Future<AccountData> updateAccountData({
    required String token,
    required AccountData data,
  }) async {
    final response = await _client.put(
      _uri('/accounts/data'),
      headers: _headers(token),
      body: jsonEncode(data.toJson()),
    );
    final json = await _decode(response);
    return AccountData.fromJson(json['data'] as Map<String, dynamic>? ?? {});
  }
}

class AccountSession {
  const AccountSession({
    required this.token,
    required this.tokenType,
    required this.account,
  });

  factory AccountSession.fromJson(Map<String, dynamic> json) {
    return AccountSession(
      token: json['token'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      account: Account.fromJson(json['account'] as Map<String, dynamic>? ?? {}),
    );
  }

  final String token;
  final String tokenType;
  final Account account;
}

class Account {
  const Account({
    required this.accountId,
    required this.email,
    required this.displayName,
    required this.organization,
    required this.role,
    required this.authProvider,
    required this.avatarUrl,
    required this.data,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['accountId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      role: json['role'] as String? ?? 'operator',
      authProvider: json['authProvider'] as String? ?? 'password',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      data: AccountData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  final String accountId;
  final String email;
  final String displayName;
  final String organization;
  final String role;
  final String authProvider;
  final String avatarUrl;
  final AccountData data;

  Account copyWith({AccountData? data}) {
    return Account(
      accountId: accountId,
      email: email,
      displayName: displayName,
      organization: organization,
      role: role,
      authProvider: authProvider,
      avatarUrl: avatarUrl,
      data: data ?? this.data,
    );
  }
}

class GoogleOAuthStatus {
  const GoogleOAuthStatus({
    required this.configured,
    required this.missingConfiguration,
    required this.redirectUri,
    required this.scope,
    required this.clientIdConfigured,
    required this.clientSecretConfigured,
    required this.setupAllowed,
    required this.updatedAt,
  });

  factory GoogleOAuthStatus.fromJson(Map<String, dynamic> json) {
    return GoogleOAuthStatus(
      configured: json['configured'] as bool? ?? false,
      missingConfiguration:
          (json['missingConfiguration'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      redirectUri: json['redirectUri'] as String? ?? '',
      scope: json['scope'] as String? ?? 'openid email profile',
      clientIdConfigured: json['clientIdConfigured'] as bool? ?? false,
      clientSecretConfigured: json['clientSecretConfigured'] as bool? ?? false,
      setupAllowed: json['setupAllowed'] as bool? ?? false,
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  final bool configured;
  final List<String> missingConfiguration;
  final String redirectUri;
  final String scope;
  final bool clientIdConfigured;
  final bool clientSecretConfigured;
  final bool setupAllowed;
  final String updatedAt;
}

class AccountData {
  const AccountData({
    required this.profile,
    required this.djiConnection,
    required this.missionPreferences,
    required this.savedMissions,
  });

  factory AccountData.defaults({String organization = ''}) {
    return AccountData(
      profile: AccountProfile(
        organization: organization,
        roleLabel: 'Mission operator',
      ),
      djiConnection: const AccountDjiConnection(
        mode: 'not-configured',
        operatorLabel: '',
        workspaceId: '',
      ),
      missionPreferences: const AccountMissionPreferences(
        defaultScenario: 'Canyon Ridge Fire',
        mapBasemap: 'satellite',
        safetyChecklistRequired: true,
      ),
      savedMissions: const [],
    );
  }

  factory AccountData.fromJson(Map<String, dynamic> json) {
    return AccountData(
      profile: AccountProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? {},
      ),
      djiConnection: AccountDjiConnection.fromJson(
        json['djiConnection'] as Map<String, dynamic>? ?? {},
      ),
      missionPreferences: AccountMissionPreferences.fromJson(
        json['missionPreferences'] as Map<String, dynamic>? ?? {},
      ),
      savedMissions: (json['savedMissions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(),
    );
  }

  final AccountProfile profile;
  final AccountDjiConnection djiConnection;
  final AccountMissionPreferences missionPreferences;
  final List<Map<String, dynamic>> savedMissions;

  AccountData copyWith({
    AccountProfile? profile,
    AccountDjiConnection? djiConnection,
    AccountMissionPreferences? missionPreferences,
    List<Map<String, dynamic>>? savedMissions,
  }) {
    return AccountData(
      profile: profile ?? this.profile,
      djiConnection: djiConnection ?? this.djiConnection,
      missionPreferences: missionPreferences ?? this.missionPreferences,
      savedMissions: savedMissions ?? this.savedMissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'djiConnection': djiConnection.toJson(),
      'missionPreferences': missionPreferences.toJson(),
      'savedMissions': savedMissions,
    };
  }
}

class AccountProfile {
  const AccountProfile({required this.organization, required this.roleLabel});

  factory AccountProfile.fromJson(Map<String, dynamic> json) {
    return AccountProfile(
      organization: json['organization'] as String? ?? '',
      roleLabel: json['roleLabel'] as String? ?? 'Mission operator',
    );
  }

  final String organization;
  final String roleLabel;

  AccountProfile copyWith({String? organization, String? roleLabel}) {
    return AccountProfile(
      organization: organization ?? this.organization,
      roleLabel: roleLabel ?? this.roleLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {'organization': organization, 'roleLabel': roleLabel};
  }
}

class AccountDjiConnection {
  const AccountDjiConnection({
    required this.mode,
    required this.operatorLabel,
    required this.workspaceId,
  });

  factory AccountDjiConnection.fromJson(Map<String, dynamic> json) {
    return AccountDjiConnection(
      mode: json['mode'] as String? ?? 'not-configured',
      operatorLabel: json['operatorLabel'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? '',
    );
  }

  final String mode;
  final String operatorLabel;
  final String workspaceId;

  AccountDjiConnection copyWith({
    String? mode,
    String? operatorLabel,
    String? workspaceId,
  }) {
    return AccountDjiConnection(
      mode: mode ?? this.mode,
      operatorLabel: operatorLabel ?? this.operatorLabel,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'operatorLabel': operatorLabel,
      'workspaceId': workspaceId,
    };
  }
}

class AccountMissionPreferences {
  const AccountMissionPreferences({
    required this.defaultScenario,
    required this.mapBasemap,
    required this.safetyChecklistRequired,
  });

  factory AccountMissionPreferences.fromJson(Map<String, dynamic> json) {
    return AccountMissionPreferences(
      defaultScenario:
          json['defaultScenario'] as String? ?? 'Canyon Ridge Fire',
      mapBasemap: json['mapBasemap'] as String? ?? 'satellite',
      safetyChecklistRequired: json['safetyChecklistRequired'] as bool? ?? true,
    );
  }

  final String defaultScenario;
  final String mapBasemap;
  final bool safetyChecklistRequired;

  AccountMissionPreferences copyWith({
    String? defaultScenario,
    String? mapBasemap,
    bool? safetyChecklistRequired,
  }) {
    return AccountMissionPreferences(
      defaultScenario: defaultScenario ?? this.defaultScenario,
      mapBasemap: mapBasemap ?? this.mapBasemap,
      safetyChecklistRequired:
          safetyChecklistRequired ?? this.safetyChecklistRequired,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultScenario': defaultScenario,
      'mapBasemap': mapBasemap,
      'safetyChecklistRequired': safetyChecklistRequired,
    };
  }
}

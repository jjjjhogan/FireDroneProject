String? _storedAccountToken;

String currentAppUrl() => 'http://127.0.0.1:8151/';

String? pendingAccountLoginCode() => null;

String? pendingAccountError() => null;

void clearAccountLoginQuery() {}

void redirectToExternalUrl(String url) {}

void openExternalUrl(String url) {}

String? storedAccountToken() => _storedAccountToken;

void saveAccountToken(String token) {
  _storedAccountToken = token;
}

void clearStoredAccountToken() {
  _storedAccountToken = null;
}

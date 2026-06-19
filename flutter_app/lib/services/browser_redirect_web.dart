import 'package:web/web.dart' as web;

String currentAppUrl() => web.window.location.href;

String? pendingAccountLoginCode() {
  return Uri.base.queryParameters['accountLoginCode'];
}

String? pendingAccountError() {
  return Uri.base.queryParameters['accountError'];
}

void clearAccountLoginQuery() {
  final uri = Uri.base;
  final params = Map<String, String>.from(uri.queryParameters)
    ..remove('accountLoginCode')
    ..remove('accountError')
    ..remove('provider');
  final next = uri.replace(queryParameters: params.isEmpty ? null : params);
  web.window.history.replaceState(null, web.document.title, next.toString());
}

void redirectToExternalUrl(String url) {
  web.window.location.assign(url);
}

void openExternalUrl(String url) {
  web.window.open(url, '_blank');
}

String? storedAccountToken() {
  return web.window.localStorage.getItem('aeroscout.accountToken');
}

void saveAccountToken(String token) {
  web.window.localStorage.setItem('aeroscout.accountToken', token);
}

void clearStoredAccountToken() {
  web.window.localStorage.removeItem('aeroscout.accountToken');
}

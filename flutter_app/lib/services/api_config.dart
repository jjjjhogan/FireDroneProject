const _defaultApiBase = 'http://127.0.0.1:5000/api';

Uri defaultApiBaseUri() {
  const configured = String.fromEnvironment(
    'FIRE_DRONE_API_BASE',
    defaultValue: _defaultApiBase,
  );
  return Uri.parse(configured);
}

Uri apiUri(Uri baseUri, String path, {Map<String, String>? queryParameters}) {
  final basePath = switch (baseUri.path) {
    '/' => '',
    final value when value.endsWith('/') => value.substring(
      0,
      value.length - 1,
    ),
    final value => value,
  };
  final apiPath = path.startsWith('/') ? path : '/$path';
  return baseUri.replace(
    path: '$basePath$apiPath',
    queryParameters: queryParameters,
  );
}

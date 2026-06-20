import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/audit_log_entry.dart';
import '../models/command.dart';
import '../models/fire_detection_event.dart';
import '../models/operations_enums.dart';
import 'api_config.dart';

abstract class OperationsApiClient {
  Future<BackendIntegrationStatus> fetchIntegrationStatus();
  Future<MapProviderConfig> fetchMapConfig();
  Future<GeofenceLayer> fetchGeofenceLayer();
  Future<MapMissionLayer> fetchMapMissionLayer();
  Future<List<MapSearchResult>> searchMap(String query);
  Future<SafetyChecklist> fetchSafetyChecklist();
  Future<List<FireDetectionEvent>> fetchAlerts();
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  });
  Future<List<AuditLogEntry>> fetchAuditEntries();
  Future<CommandResult> simulateCommand(CommandRequest request);
}

class BackendIntegrationStatus {
  const BackendIntegrationStatus({
    required this.available,
    required this.rbacEnabled,
    required this.persistenceEngine,
    required this.auditPersistence,
    required this.alertPersistence,
    required this.mapProvider,
    required this.mapConfigured,
    required this.px4Sitl,
    required this.mavlink,
    required this.ardupilot,
    required this.yoloThermal,
    required this.hardwareCommandsEnabled,
  });

  factory BackendIntegrationStatus.fromJson(Map<String, dynamic> json) {
    final auth = json['auth'] as Map<String, dynamic>? ?? const {};
    final persistence =
        json['persistence'] as Map<String, dynamic>? ?? const {};
    final map = json['map'] as Map<String, dynamic>? ?? const {};
    final adapters = json['adapters'] as Map<String, dynamic>? ?? const {};
    final safety = json['safety'] as Map<String, dynamic>? ?? const {};
    return BackendIntegrationStatus(
      available: true,
      rbacEnabled: auth['rbacEnabled'] as bool? ?? false,
      persistenceEngine: persistence['engine'] as String? ?? 'unknown',
      auditPersistence: persistence['audit'] as String? ?? 'unknown',
      alertPersistence: persistence['alerts'] as String? ?? 'unknown',
      mapProvider: map['provider'] as String? ?? 'unknown',
      mapConfigured: map['configured'] as bool? ?? false,
      px4Sitl: adapters['px4Sitl'] as String? ?? 'not configured',
      mavlink: adapters['mavlink'] as String? ?? 'not configured',
      ardupilot: adapters['arduPilot'] as String? ?? 'not configured',
      yoloThermal: adapters['yoloThermal'] as String? ?? 'not configured',
      hardwareCommandsEnabled:
          safety['hardwareCommandsEnabled'] as bool? ?? false,
    );
  }

  factory BackendIntegrationStatus.unavailable() {
    return const BackendIntegrationStatus(
      available: false,
      rbacEnabled: false,
      persistenceEngine: 'offline',
      auditPersistence: 'local fallback',
      alertPersistence: 'local fallback',
      mapProvider: 'local placeholder',
      mapConfigured: false,
      px4Sitl: 'backend offline',
      mavlink: 'backend offline',
      ardupilot: 'backend offline',
      yoloThermal: 'backend offline',
      hardwareCommandsEnabled: false,
    );
  }

  final bool available;
  final bool rbacEnabled;
  final String persistenceEngine;
  final String auditPersistence;
  final String alertPersistence;
  final String mapProvider;
  final bool mapConfigured;
  final String px4Sitl;
  final String mavlink;
  final String ardupilot;
  final String yoloThermal;
  final bool hardwareCommandsEnabled;
}

class MapProviderConfig {
  const MapProviderConfig({
    required this.provider,
    required this.tileUrlTemplate,
    required this.attribution,
    required this.configured,
    required this.tilePolicyStatus,
    required this.tilePolicyMessage,
    required this.tileProductionReady,
    required this.searchProvider,
    required this.defaultBasemap,
    required this.basemaps,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  factory MapProviderConfig.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as Map<String, dynamic>? ?? const {};
    final tilePolicy = json['tilePolicy'] as Map<String, dynamic>? ?? const {};
    return MapProviderConfig(
      provider: json['provider'] as String? ?? 'unknown',
      tileUrlTemplate: json['tileUrlTemplate'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
      configured: json['configured'] as bool? ?? false,
      tilePolicyStatus: tilePolicy['status'] as String? ?? 'unknown',
      tilePolicyMessage: tilePolicy['message'] as String? ?? '',
      tileProductionReady: tilePolicy['productionReady'] as bool? ?? false,
      searchProvider: json['searchProvider'] as String? ?? 'nominatim',
      defaultBasemap: json['defaultBasemap'] as String? ?? 'streets',
      basemaps: (json['basemaps'] as List<dynamic>? ?? const [])
          .map((item) => MapBasemap.fromJson(item as Map<String, dynamic>))
          .toList(),
      centerLat: (center['lat'] as num?)?.toDouble() ?? 34.6234,
      centerLng: (center['lng'] as num?)?.toDouble() ?? -119.7196,
      zoom: (center['zoom'] as num?)?.toInt() ?? 13,
    );
  }

  factory MapProviderConfig.unavailable() {
    return const MapProviderConfig(
      provider: 'openstreetmap',
      tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: 'OpenStreetMap contributors',
      configured: false,
      tilePolicyStatus: 'development-only',
      tilePolicyMessage:
          'Public OpenStreetMap tile servers are for development previews; use a dedicated provider for production.',
      tileProductionReady: false,
      searchProvider: 'nominatim',
      defaultBasemap: 'satellite',
      basemaps: [
        MapBasemap(
          id: 'satellite',
          label: 'Satellite imagery',
          provider: 'arcgis-world-imagery',
          tileUrlTemplate:
              'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          attribution:
              'Powered by Esri | Sources: Esri, Maxar, Earthstar Geographics, and the GIS User Community',
          configured: true,
          requiresApiKey: false,
          policyStatus: 'development-imagery',
          policyMessage:
              'ArcGIS World Imagery gives a realistic satellite basemap for development previews.',
          productionReady: false,
        ),
        MapBasemap(
          id: 'streets',
          label: 'Street map',
          provider: 'openstreetmap',
          tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          attribution: 'OpenStreetMap contributors',
          configured: false,
          requiresApiKey: false,
          policyStatus: 'development-only',
          policyMessage:
              'Public OpenStreetMap tile servers are for development previews; use a dedicated provider for production.',
          productionReady: false,
        ),
      ],
      centerLat: 34.6234,
      centerLng: -119.7196,
      zoom: 13,
    );
  }

  final String provider;
  final String tileUrlTemplate;
  final String attribution;
  final bool configured;
  final String tilePolicyStatus;
  final String tilePolicyMessage;
  final bool tileProductionReady;
  final String searchProvider;
  final String defaultBasemap;
  final List<MapBasemap> basemaps;
  final double centerLat;
  final double centerLng;
  final int zoom;

  List<MapBasemap> get availableBasemaps {
    if (basemaps.isNotEmpty) return basemaps;
    return [
      MapBasemap(
        id: 'streets',
        label: providerLabel,
        provider: provider,
        tileUrlTemplate: tileUrlTemplate,
        attribution: attribution,
        configured: configured,
        requiresApiKey: false,
        policyStatus: tilePolicyStatus,
        policyMessage: tilePolicyMessage,
        productionReady: tileProductionReady,
      ),
    ];
  }

  MapBasemap basemapById(String id) {
    for (final basemap in availableBasemaps) {
      if (basemap.id == id) return basemap;
    }
    for (final basemap in availableBasemaps) {
      if (basemap.id == defaultBasemap) return basemap;
    }
    return availableBasemaps.first;
  }

  String get providerLabel {
    return switch (provider.toLowerCase()) {
      'openstreetmap' => 'OpenStreetMap tiles',
      'mapbox' => 'Mapbox tiles',
      'arcgis' => 'ArcGIS tiles',
      _ => '$provider tiles',
    };
  }

  String get tilePolicyLabel {
    final label = tilePolicyStatus.replaceAll('-', ' ').trim();
    if (label.isEmpty) return 'Unknown';
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }

  String get searchProviderLabel {
    return switch (searchProvider.toLowerCase()) {
      'nominatim' => 'Nominatim',
      _ =>
        searchProvider
            .split(RegExp(r'[-_\s]+'))
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
    };
  }
}

class MapBasemap {
  const MapBasemap({
    required this.id,
    required this.label,
    required this.provider,
    required this.tileUrlTemplate,
    required this.attribution,
    required this.configured,
    required this.requiresApiKey,
    required this.policyStatus,
    required this.policyMessage,
    required this.productionReady,
  });

  factory MapBasemap.fromJson(Map<String, dynamic> json) {
    final policy = json['policy'] as Map<String, dynamic>? ?? const {};
    return MapBasemap(
      id: json['id'] as String? ?? 'streets',
      label: json['label'] as String? ?? 'Map tiles',
      provider: json['provider'] as String? ?? 'unknown',
      tileUrlTemplate: json['tileUrlTemplate'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
      configured: json['configured'] as bool? ?? false,
      requiresApiKey: json['requiresApiKey'] as bool? ?? false,
      policyStatus: policy['status'] as String? ?? 'unknown',
      policyMessage: policy['message'] as String? ?? '',
      productionReady: policy['productionReady'] as bool? ?? false,
    );
  }

  final String id;
  final String label;
  final String provider;
  final String tileUrlTemplate;
  final String attribution;
  final bool configured;
  final bool requiresApiKey;
  final String policyStatus;
  final String policyMessage;
  final bool productionReady;

  String get policyLabel {
    final normalized = policyStatus.replaceAll('-', ' ').trim();
    if (normalized.isEmpty) return 'Unknown';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

class GeofenceLayer {
  const GeofenceLayer({
    required this.source,
    required this.updatedAt,
    required this.features,
  });

  factory GeofenceLayer.fromJson(Map<String, dynamic> json) {
    return GeofenceLayer(
      source: json['source'] as String? ?? 'unknown',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      features: (json['features'] as List<dynamic>? ?? const [])
          .map((item) => GeofenceFeature.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory GeofenceLayer.unavailable() {
    return const GeofenceLayer(
      source: 'local-fallback',
      updatedAt: null,
      features: [
        GeofenceFeature(
          id: 'local-mission-geofence',
          name: 'Mission geofence',
          layerType: 'mission_geofence',
          status: 'backend_offline',
          strokeColor: '#22b7ae',
          fillColor: '#22b7ae',
          fillOpacity: 0.10,
          coordinates: [
            [
              MapCoordinate(lat: 34.6515, lng: -119.7598),
              MapCoordinate(lat: 34.6497, lng: -119.6836),
              MapCoordinate(lat: 34.5904, lng: -119.6812),
              MapCoordinate(lat: 34.5893, lng: -119.7609),
              MapCoordinate(lat: 34.6515, lng: -119.7598),
            ],
          ],
        ),
      ],
    );
  }

  final String source;
  final DateTime? updatedAt;
  final List<GeofenceFeature> features;
}

class GeofenceFeature {
  const GeofenceFeature({
    required this.id,
    required this.name,
    required this.layerType,
    required this.status,
    required this.strokeColor,
    required this.fillColor,
    required this.fillOpacity,
    required this.coordinates,
  });

  factory GeofenceFeature.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? const {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? const {};
    return GeofenceFeature(
      id: properties['id'] as String? ?? '',
      name: properties['name'] as String? ?? 'Unnamed layer',
      layerType: properties['layerType'] as String? ?? 'unknown',
      status: properties['status'] as String? ?? 'unknown',
      strokeColor: properties['strokeColor'] as String? ?? '#ffffff',
      fillColor: properties['fillColor'] as String? ?? '#ffffff',
      fillOpacity: (properties['fillOpacity'] as num?)?.toDouble() ?? 0.12,
      coordinates: _parsePolygonCoordinates(geometry['coordinates']),
    );
  }

  final String id;
  final String name;
  final String layerType;
  final String status;
  final String strokeColor;
  final String fillColor;
  final double fillOpacity;
  final List<List<MapCoordinate>> coordinates;
}

class MapCoordinate {
  const MapCoordinate({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class MapMissionLayer {
  const MapMissionLayer({
    required this.source,
    required this.updatedAt,
    required this.bounds,
    required this.route,
    required this.alerts,
    required this.drones,
  });

  factory MapMissionLayer.fromJson(Map<String, dynamic> json) {
    return MapMissionLayer(
      source: json['source'] as String? ?? 'unknown',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      bounds: MapBounds.fromJson(json['bounds']),
      route: MapMissionRoute.fromJson(json['route']),
      alerts: (json['alerts'] as List<dynamic>? ?? const [])
          .map((item) => MapAlertPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      drones: (json['drones'] as List<dynamic>? ?? const [])
          .map((item) => MapDroneMarker.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory MapMissionLayer.unavailable() {
    return const MapMissionLayer(
      source: 'local-mission-fallback',
      updatedAt: null,
      bounds: MapBounds(
        source: 'computed-from-map-layers',
        north: 34.6376,
        south: 34.6098,
        east: -119.7104,
        west: -119.7444,
      ),
      route: MapMissionRoute(
        id: 'local-canyon-ridge-route',
        name: 'Local Canyon Ridge route',
        source: 'local-fallback',
        points: [
          MapRoutePoint(
            label: 'LZ',
            lat: 34.6368,
            lng: -119.7334,
            altitudeM: 92,
            action: 'Launch and link check',
          ),
          MapRoutePoint(
            label: 'WP1',
            lat: 34.6282,
            lng: -119.7104,
            altitudeM: 118,
            action: 'Thermal scan north ridge',
          ),
          MapRoutePoint(
            label: 'WP2',
            lat: 34.6098,
            lng: -119.7192,
            altitudeM: 122,
            action: 'Inspect southern perimeter',
          ),
          MapRoutePoint(
            label: 'WP3',
            lat: 34.6214,
            lng: -119.7444,
            altitudeM: 110,
            action: 'Check containment line',
          ),
          MapRoutePoint(
            label: 'RTL',
            lat: 34.6368,
            lng: -119.7334,
            altitudeM: 92,
            action: 'Return to launch',
          ),
        ],
      ),
      alerts: [
        MapAlertPoint(
          id: 'local-hotspot',
          label: 'Local hotspot seed',
          type: 'thermal',
          severity: 'high',
          confidence: 0.87,
          lat: 34.6308,
          lng: -119.7294,
          source: 'local-fallback',
          status: 'Unconfirmed',
        ),
        MapAlertPoint(
          id: 'local-smoke',
          label: 'Local smoke seed',
          type: 'smoke',
          severity: 'medium',
          confidence: 0.78,
          lat: 34.6234,
          lng: -119.7196,
          source: 'local-fallback',
          status: 'Unconfirmed',
        ),
        MapAlertPoint(
          id: 'local-fire-edge',
          label: 'Local fire edge seed',
          type: 'fire',
          severity: 'critical',
          confidence: 0.91,
          lat: 34.6162,
          lng: -119.7336,
          source: 'local-fallback',
          status: 'Unconfirmed',
        ),
      ],
      drones: [
        MapDroneMarker(
          id: 'planned-launch-zone',
          name: 'Planned launch zone',
          model: 'Operator-selected aircraft',
          connection: 'planned',
          live: false,
          lat: 34.6376,
          lng: -119.7340,
          altitudeM: 0,
          source: 'local-fallback',
          warnings: ['No live aircraft position has been ingested.'],
        ),
      ],
    );
  }

  final String source;
  final DateTime? updatedAt;
  final MapBounds bounds;
  final MapMissionRoute route;
  final List<MapAlertPoint> alerts;
  final List<MapDroneMarker> drones;
}

class MapBounds {
  const MapBounds({
    required this.source,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory MapBounds.fromJson(Object? json) {
    final data = json is Map<String, dynamic> ? json : const {};
    return MapBounds(
      source: data['source'] as String? ?? 'unknown',
      north: (data['north'] as num?)?.toDouble() ?? 34.6234,
      south: (data['south'] as num?)?.toDouble() ?? 34.6234,
      east: (data['east'] as num?)?.toDouble() ?? -119.7196,
      west: (data['west'] as num?)?.toDouble() ?? -119.7196,
    );
  }

  final String source;
  final double north;
  final double south;
  final double east;
  final double west;

  bool get hasArea => north > south && east > west;

  String get label {
    return switch (source) {
      'computed-from-map-layers' => 'Backend bounds',
      'configured-center' => 'Configured center',
      _ =>
        source
            .replaceAll('-', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
    };
  }
}

class MapMissionRoute {
  const MapMissionRoute({
    required this.id,
    required this.name,
    required this.source,
    required this.points,
  });

  factory MapMissionRoute.fromJson(Object? json) {
    final data = json is Map<String, dynamic> ? json : const {};
    return MapMissionRoute(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? 'Mission route',
      source: data['source'] as String? ?? 'unknown',
      points: (data['points'] as List<dynamic>? ?? const [])
          .map((item) => MapRoutePoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String source;
  final List<MapRoutePoint> points;
}

class MapRoutePoint {
  const MapRoutePoint({
    required this.label,
    required this.lat,
    required this.lng,
    required this.altitudeM,
    required this.action,
  });

  factory MapRoutePoint.fromJson(Map<String, dynamic> json) {
    return MapRoutePoint(
      label: json['label'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      altitudeM: (json['altitudeM'] as num?)?.toDouble() ?? 0,
      action: json['action'] as String? ?? '',
    );
  }

  final String label;
  final double lat;
  final double lng;
  final double altitudeM;
  final String action;
}

class MapAlertPoint {
  const MapAlertPoint({
    required this.id,
    required this.label,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.lat,
    required this.lng,
    required this.source,
    required this.status,
  });

  factory MapAlertPoint.fromJson(Map<String, dynamic> json) {
    return MapAlertPoint(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Map alert',
      type: json['type'] as String? ?? 'alert',
      severity: json['severity'] as String? ?? 'medium',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'Unconfirmed',
    );
  }

  final String id;
  final String label;
  final String type;
  final String severity;
  final double confidence;
  final double lat;
  final double lng;
  final String source;
  final String status;
}

class MapDroneMarker {
  const MapDroneMarker({
    required this.id,
    required this.name,
    required this.model,
    required this.connection,
    required this.live,
    required this.lat,
    required this.lng,
    required this.altitudeM,
    required this.source,
    required this.warnings,
  });

  factory MapDroneMarker.fromJson(Map<String, dynamic> json) {
    return MapDroneMarker(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Aircraft',
      model: json['model'] as String? ?? 'aircraft',
      connection: json['connection'] as String? ?? 'unknown',
      live: json['live'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      altitudeM: (json['altitudeM'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'unknown',
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String id;
  final String name;
  final String model;
  final String connection;
  final bool live;
  final double lat;
  final double lng;
  final double altitudeM;
  final String source;
  final List<String> warnings;
}

class MapSearchResult {
  const MapSearchResult({
    required this.id,
    required this.displayName,
    required this.lat,
    required this.lng,
    required this.category,
    required this.type,
    this.boundingBox,
  });

  factory MapSearchResult.fromJson(Map<String, dynamic> json) {
    return MapSearchResult(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Unnamed place',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'place',
      type: json['type'] as String? ?? 'unknown',
      boundingBox: json['boundingBox'] == null
          ? null
          : MapBounds.fromJson({
              'source': 'search-result',
              ...(json['boundingBox'] as Map<String, dynamic>),
            }),
    );
  }

  final String id;
  final String displayName;
  final double lat;
  final double lng;
  final String category;
  final String type;
  final MapBounds? boundingBox;

  String get shortLabel {
    final firstPart = displayName.split(',').first.trim();
    return firstPart.isEmpty ? displayName : firstPart;
  }
}

class SafetyChecklist {
  const SafetyChecklist({
    required this.geofence,
    required this.remoteId,
    required this.airspaceApproval,
    required this.emergencyStop,
  });

  factory SafetyChecklist.fromJson(Map<String, dynamic> json) {
    return SafetyChecklist(
      geofence: SafetyChecklistItem.fromJson(json['geofence']),
      remoteId: SafetyChecklistItem.fromJson(json['remoteId']),
      airspaceApproval: SafetyChecklistItem.fromJson(json['airspaceApproval']),
      emergencyStop: SafetyChecklistItem.fromJson(json['emergencyStop']),
    );
  }

  factory SafetyChecklist.unavailable() {
    const unavailable = SafetyChecklistItem(
      status: 'backend_offline',
      notes: 'Backend safety checklist unavailable.',
      engaged: false,
    );
    return const SafetyChecklist(
      geofence: unavailable,
      remoteId: unavailable,
      airspaceApproval: unavailable,
      emergencyStop: unavailable,
    );
  }

  final SafetyChecklistItem geofence;
  final SafetyChecklistItem remoteId;
  final SafetyChecklistItem airspaceApproval;
  final SafetyChecklistItem emergencyStop;
}

class SafetyChecklistItem {
  const SafetyChecklistItem({
    required this.status,
    required this.notes,
    required this.engaged,
    this.updatedAt,
    this.updatedBy,
  });

  factory SafetyChecklistItem.fromJson(Object? json) {
    final data = json is Map<String, dynamic> ? json : const {};
    return SafetyChecklistItem(
      status: data['status'] as String? ?? 'not_verified',
      notes: data['notes'] as String? ?? '',
      engaged: data['engaged'] as bool? ?? false,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  final String status;
  final String notes;
  final bool engaged;
  final DateTime? updatedAt;
  final String? updatedBy;

  String get label {
    return switch (status) {
      'not_verified' => 'Not verified',
      'pending' => 'Pending review',
      'verified' => 'Verified',
      'blocked' => 'Blocked',
      'ready' => 'Ready',
      'engaged' => 'Engaged',
      'backend_offline' => 'Backend offline',
      _ =>
        status
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
    };
  }

  String get commandPanelValue {
    if (engaged) return '$label active';
    return label;
  }
}

class HttpOperationsApiClient implements OperationsApiClient {
  HttpOperationsApiClient({
    Uri? baseUri,
    http.Client? client,
    String? authToken,
  }) : baseUri = baseUri ?? defaultApiBaseUri(),
       _client = client ?? http.Client(),
       authToken =
           authToken ??
           const String.fromEnvironment(
             'PUBLIC_SAFETY_TOKEN',
             defaultValue: '',
           );

  final Uri baseUri;
  final http.Client _client;
  final String authToken;

  Uri _uri(String path) => apiUri(baseUri, path);

  Uri _uriWithQuery(String path, Map<String, String> queryParameters) {
    return apiUri(baseUri, path, queryParameters: queryParameters);
  }

  Map<String, String> get _headers {
    final headers = {'content-type': 'application/json'};
    if (authToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${authToken.trim()}';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(_uri(path), headers: _headers);
    if (response.statusCode >= 400) {
      throw StateError('Operations API request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 500) {
      throw StateError('Operations API request failed: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  @override
  Future<BackendIntegrationStatus> fetchIntegrationStatus() async {
    return BackendIntegrationStatus.fromJson(
      await _getJson('/integrations/status'),
    );
  }

  @override
  Future<MapProviderConfig> fetchMapConfig() async {
    return MapProviderConfig.fromJson(await _getJson('/map/config'));
  }

  @override
  Future<GeofenceLayer> fetchGeofenceLayer() async {
    return GeofenceLayer.fromJson(await _getJson('/map/geofence'));
  }

  @override
  Future<MapMissionLayer> fetchMapMissionLayer() async {
    return MapMissionLayer.fromJson(await _getJson('/map/mission'));
  }

  @override
  Future<List<MapSearchResult>> searchMap(String query) async {
    final response = await _client.get(
      _uriWithQuery('/map/search', {'q': query}),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw StateError('Operations API request failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['results'] as List<dynamic>? ?? const [])
        .map((item) => MapSearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SafetyChecklist> fetchSafetyChecklist() async {
    return SafetyChecklist.fromJson(await _getJson('/safety/checklist'));
  }

  @override
  Future<List<FireDetectionEvent>> fetchAlerts() async {
    final json = await _getJson('/alerts');
    return (json['alerts'] as List<dynamic>? ?? const [])
        .map((item) => _alertFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  }) async {
    final json = await _postJson('/alerts/${event.eventId}/review', {
      'status': _alertStatusLabel(status),
      'notes': notes,
    });
    if (json['accepted'] != true) {
      throw StateError(json['error'] as String? ?? 'Alert review rejected');
    }
    return _alertFromJson(json['alert'] as Map<String, dynamic>);
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditEntries() async {
    final json = await _getJson('/audit');
    return (json['entries'] as List<dynamic>? ?? const [])
        .map((item) => _auditFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CommandResult> simulateCommand(CommandRequest request) async {
    final json = await _postJson('/commands/simulate', {
      'commandType': request.commandType.label,
      'targetDroneId': request.targetDroneId,
      'confirmationProvided': request.confirmationProvided,
      'notes': request.notes,
    });
    return CommandResult(
      accepted: json['accepted'] as bool? ?? false,
      commandType: request.commandType,
      targetDroneId: json['targetDroneId'] as String? ?? request.targetDroneId,
      message: json['message'] as String? ?? '',
      blockedReason: json['blockedReason'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class ResilientOperationsApiClient implements OperationsApiClient {
  ResilientOperationsApiClient({
    OperationsApiClient? primary,
    OperationsApiClient? fallback,
  }) : _primary = primary ?? HttpOperationsApiClient(),
       _fallback = fallback ?? const UnavailableOperationsApiClient();

  final OperationsApiClient _primary;
  final OperationsApiClient _fallback;

  Future<T> _fromPrimary<T>(
    Future<T> Function(OperationsApiClient client) request,
  ) async {
    try {
      return await request(_primary);
    } catch (_) {
      return request(_fallback);
    }
  }

  @override
  Future<BackendIntegrationStatus> fetchIntegrationStatus() {
    return _fromPrimary((client) => client.fetchIntegrationStatus());
  }

  @override
  Future<MapProviderConfig> fetchMapConfig() {
    return _fromPrimary((client) => client.fetchMapConfig());
  }

  @override
  Future<GeofenceLayer> fetchGeofenceLayer() {
    return _fromPrimary((client) => client.fetchGeofenceLayer());
  }

  @override
  Future<MapMissionLayer> fetchMapMissionLayer() {
    return _fromPrimary((client) => client.fetchMapMissionLayer());
  }

  @override
  Future<List<MapSearchResult>> searchMap(String query) {
    return _fromPrimary((client) => client.searchMap(query));
  }

  @override
  Future<SafetyChecklist> fetchSafetyChecklist() {
    return _fromPrimary((client) => client.fetchSafetyChecklist());
  }

  @override
  Future<List<FireDetectionEvent>> fetchAlerts() {
    return _fromPrimary((client) => client.fetchAlerts());
  }

  @override
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  }) {
    return _fromPrimary(
      (client) =>
          client.reviewAlert(event: event, status: status, notes: notes),
    );
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditEntries() {
    return _fromPrimary((client) => client.fetchAuditEntries());
  }

  @override
  Future<CommandResult> simulateCommand(CommandRequest request) {
    return _fromPrimary((client) => client.simulateCommand(request));
  }
}

class UnavailableOperationsApiClient implements OperationsApiClient {
  const UnavailableOperationsApiClient();

  @override
  Future<BackendIntegrationStatus> fetchIntegrationStatus() async {
    return BackendIntegrationStatus.unavailable();
  }

  @override
  Future<MapProviderConfig> fetchMapConfig() async {
    return MapProviderConfig.unavailable();
  }

  @override
  Future<GeofenceLayer> fetchGeofenceLayer() async {
    return GeofenceLayer.unavailable();
  }

  @override
  Future<MapMissionLayer> fetchMapMissionLayer() async {
    return MapMissionLayer.unavailable();
  }

  @override
  Future<List<MapSearchResult>> searchMap(String query) async {
    return const [];
  }

  @override
  Future<SafetyChecklist> fetchSafetyChecklist() async {
    return SafetyChecklist.unavailable();
  }

  @override
  Future<List<FireDetectionEvent>> fetchAlerts() async {
    return const [];
  }

  @override
  Future<FireDetectionEvent> reviewAlert({
    required FireDetectionEvent event,
    required AlertStatus status,
    required String notes,
  }) async {
    throw StateError('Operations backend unavailable');
  }

  @override
  Future<List<AuditLogEntry>> fetchAuditEntries() async {
    return const [];
  }

  @override
  Future<CommandResult> simulateCommand(CommandRequest request) async {
    throw StateError('Operations backend unavailable');
  }
}

FireDetectionEvent _alertFromJson(Map<String, dynamic> json) {
  return FireDetectionEvent(
    eventId: json['eventId'] as String? ?? '',
    detectionType: _detectionType(json['detectionType']),
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    severity: _severity(json['severity']),
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lon: (json['lon'] as num?)?.toDouble() ?? 0,
    sourceDroneId: json['sourceDroneId'] as String? ?? 'unknown',
    imagePlaceholder:
        json['thermalUri'] as String? ??
        json['imageUri'] as String? ??
        'backend alert frame',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ??
        DateTime.now().toUtc(),
    status: _alertStatus(json['status']),
    reviewer: json['reviewer'] as String?,
    reviewTimestamp: DateTime.tryParse(
      json['reviewTimestamp'] as String? ?? '',
    ),
    notes: json['notes'] as String? ?? '',
  );
}

AuditLogEntry _auditFromJson(Map<String, dynamic> json) {
  return AuditLogEntry(
    entryId: json['entryId'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ??
        DateTime.now().toUtc(),
    actor: json['actor'] as String? ?? 'backend',
    action: json['action'] as String? ?? '',
    targetId: json['targetId'] as String? ?? '',
    details: json['details'] as String? ?? '',
  );
}

DetectionType _detectionType(Object? value) {
  return switch (value?.toString().toLowerCase()) {
    'fire' => DetectionType.fire,
    _ => DetectionType.smoke,
  };
}

AlertSeverity _severity(Object? value) {
  return switch (value?.toString().toLowerCase()) {
    'low' => AlertSeverity.low,
    'high' => AlertSeverity.high,
    'critical' => AlertSeverity.critical,
    _ => AlertSeverity.medium,
  };
}

AlertStatus _alertStatus(Object? value) {
  final text = value?.toString().toLowerCase() ?? '';
  if (text.contains('false')) return AlertStatus.falsePositive;
  if (text.contains('resolved')) return AlertStatus.resolved;
  if (text.contains('confirmed')) return AlertStatus.confirmed;
  return AlertStatus.unconfirmed;
}

String _alertStatusLabel(AlertStatus status) {
  return switch (status) {
    AlertStatus.unconfirmed => 'Unconfirmed',
    AlertStatus.confirmed => 'Confirmed',
    AlertStatus.falsePositive => 'False Positive',
    AlertStatus.resolved => 'Resolved',
  };
}

List<List<MapCoordinate>> _parsePolygonCoordinates(Object? coordinates) {
  if (coordinates is! List) return const [];
  return coordinates
      .whereType<List>()
      .map((ring) {
        return ring
            .whereType<List>()
            .where((point) => point.length >= 2)
            .map(
              (point) => MapCoordinate(
                lng: (point[0] as num).toDouble(),
                lat: (point[1] as num).toDouble(),
              ),
            )
            .toList();
      })
      .where((ring) => ring.length >= 3)
      .toList();
}

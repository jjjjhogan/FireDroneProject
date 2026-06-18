import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/operations_api_client.dart';

class MissionCommandMap extends StatefulWidget {
  const MissionCommandMap({
    required this.missionAvailable,
    required this.mapConfig,
    required this.geofenceLayer,
    required this.mapMissionLayer,
    required this.operationsClient,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    super.key,
  });

  final bool missionAvailable;
  final MapProviderConfig mapConfig;
  final GeofenceLayer geofenceLayer;
  final MapMissionLayer mapMissionLayer;
  final OperationsApiClient operationsClient;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;

  @override
  State<MissionCommandMap> createState() => _MissionCommandMapState();
}

class _MissionCommandMapState extends State<MissionCommandMap> {
  late final MapController _mapController;
  late final TextEditingController _searchController;
  late LatLng _center;
  late double _zoom;
  bool _mapReady = false;
  bool _geofenceVisible = true;
  bool _routeVisible = true;
  bool _alertsVisible = true;
  bool _droneVisible = true;
  bool _infoVisible = false;
  late String _activeBasemapId;
  bool _boundsFitApplied = false;
  bool _searching = false;
  List<MapSearchResult> _searchResults = const [];
  MapSearchResult? _searchFocus;
  String? _searchError;
  String _activeTool = 'Tool: Pan and inspect';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchController = TextEditingController();
    _activeBasemapId = widget.mapConfig.defaultBasemap;
    _center = _configuredCenter;
    _zoom = widget.mapConfig.zoom.toDouble();
  }

  @override
  void didUpdateWidget(covariant MissionCommandMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapConfig.centerLat != widget.mapConfig.centerLat ||
        oldWidget.mapConfig.centerLng != widget.mapConfig.centerLng ||
        oldWidget.mapConfig.zoom != widget.mapConfig.zoom) {
      _center = _configuredCenter;
      _zoom = widget.mapConfig.zoom.toDouble();
      if (_mapReady) {
        _mapController.move(_center, _zoom, id: 'backend-map-config');
      }
    }
    if (oldWidget.mapConfig.defaultBasemap != widget.mapConfig.defaultBasemap) {
      _activeBasemapId = widget.mapConfig.defaultBasemap;
    }
    if (_mapReady && _boundsChanged(oldWidget.mapMissionLayer.bounds)) {
      _fitMissionBounds();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _configuredCenter =>
      LatLng(widget.mapConfig.centerLat, widget.mapConfig.centerLng);

  List<LatLng> get _routePoints => [
    for (final point in widget.mapMissionLayer.route.points)
      LatLng(point.lat, point.lng),
  ];

  MapBasemap get _activeBasemap =>
      widget.mapConfig.basemapById(_activeBasemapId);

  String get _tileTemplate {
    final template = _activeBasemap.tileUrlTemplate.trim();
    return template.isEmpty
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : template;
  }

  bool _boundsChanged(MapBounds oldBounds) {
    final bounds = widget.mapMissionLayer.bounds;
    return bounds.north != oldBounds.north ||
        bounds.south != oldBounds.south ||
        bounds.east != oldBounds.east ||
        bounds.west != oldBounds.west;
  }

  void _fitMissionBounds() {
    final bounds = widget.mapMissionLayer.bounds;
    if (!bounds.hasArea) {
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(bounds.south, bounds.west),
          LatLng(bounds.north, bounds.east),
        ),
        padding: const EdgeInsets.fromLTRB(96, 96, 96, 128),
      ),
    );
    if (mounted) {
      setState(() {
        _boundsFitApplied = true;
        _activeTool = 'Tool: Backend bounds fit';
      });
    }
  }

  void _zoomBy(double delta) {
    final nextZoom = (_zoom + delta).clamp(10.0, 18.0).toDouble();
    setState(() {
      _zoom = nextZoom;
      _activeTool = delta > 0 ? 'Tool: Zoom in' : 'Tool: Zoom out';
    });
    if (_mapReady) {
      _mapController.move(_center, nextZoom, id: 'zoom-control');
    }
  }

  void _recenter() {
    setState(() {
      _center = _configuredCenter;
      _zoom = widget.mapConfig.zoom.toDouble();
      _activeTool = 'Tool: Incident center';
    });
    if (_mapReady) {
      _mapController.move(_center, _zoom, id: 'incident-center');
    }
  }

  void _focusRoute() {
    final routePoints = _routePoints;
    setState(() {
      _routeVisible = true;
      _activeTool = 'Tool: Mission route focus';
    });
    if (_mapReady && routePoints.length >= 2) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(routePoints),
          padding: const EdgeInsets.fromLTRB(88, 88, 88, 118),
        ),
      );
    }
  }

  Future<void> _searchRealPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchError = 'Enter a place or address';
        _searchResults = const [];
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
      _activeTool = 'Tool: Place search';
    });

    try {
      final results = await widget.operationsClient.searchMap(query);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchResults = results;
        _searchError = results.isEmpty ? 'No matching place found' : null;
      });
      if (results.isNotEmpty) {
        _focusSearchResult(results.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchResults = const [];
        _searchError = 'Map search unavailable';
      });
    }
  }

  void _focusSearchResult(MapSearchResult result) {
    final resultCenter = LatLng(result.lat, result.lng);
    setState(() {
      _searchFocus = result;
      _center = resultCenter;
      _activeTool = 'Tool: Search result focus';
    });
    if (!_mapReady) {
      return;
    }

    final bounds = result.boundingBox;
    if (bounds != null && bounds.hasArea) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(bounds.south, bounds.west),
            LatLng(bounds.north, bounds.east),
          ),
          padding: const EdgeInsets.fromLTRB(78, 78, 78, 118),
        ),
      );
    } else {
      _mapController.move(resultCenter, 13, id: 'free-map-search');
    }
  }

  void _toggleRoute() {
    setState(() {
      _routeVisible = !_routeVisible;
      _activeTool = _routeVisible
          ? 'Tool: Route visible'
          : 'Tool: Route hidden';
    });
  }

  void _toggleGeofence() {
    setState(() {
      _geofenceVisible = !_geofenceVisible;
      _activeTool = _geofenceVisible
          ? 'Tool: Geofence visible'
          : 'Tool: Geofence hidden';
    });
  }

  void _toggleOverlays() {
    final showAny = !(_geofenceVisible && _routeVisible && _alertsVisible);
    setState(() {
      _geofenceVisible = showAny;
      _routeVisible = showAny;
      _alertsVisible = showAny;
      _activeTool = showAny
          ? 'Tool: GIS overlays on'
          : 'Tool: GIS overlays off';
    });
  }

  void _toggleInfo() {
    setState(() {
      _infoVisible = !_infoVisible;
      _activeTool = _infoVisible
          ? 'Tool: Source info open'
          : 'Tool: Source info';
    });
  }

  void _toggleBasemap() {
    final basemaps = widget.mapConfig.availableBasemaps;
    if (basemaps.length < 2) {
      setState(() => _activeTool = 'Tool: Basemap unavailable');
      return;
    }
    final currentIndex = basemaps.indexWhere(
      (basemap) => basemap.id == _activeBasemapId,
    );
    final next = basemaps[(currentIndex + 1) % basemaps.length];
    setState(() {
      _activeBasemapId = next.id;
      _activeTool = 'Tool: ${next.label} basemap';
    });
  }

  void _toggleDrone() {
    setState(() {
      _droneVisible = !_droneVisible;
      _activeTool = _droneVisible
          ? 'Tool: Drone marker on'
          : 'Tool: Drone hidden';
    });
  }

  Widget _buildInteractiveMissionMap() {
    final routePoints = _routePoints;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: _zoom,
        minZoom: 10,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.pinchMove |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.scrollWheelZoom,
        ),
        onMapReady: () {
          setState(() => _mapReady = true);
          _fitMissionBounds();
        },
        onPositionChanged: (camera, hasGesture) {
          if (!mounted) return;
          setState(() {
            _center = camera.center;
            _zoom = camera.zoom;
            if (hasGesture) {
              _activeTool = 'Tool: Manual map pan/zoom';
            }
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _tileTemplate,
          userAgentPackageName: 'fire_drone_app',
          panBuffer: 2,
          errorTileCallback: (_, _, _) {},
        ),
        if (_geofenceVisible)
          PolygonLayer(polygons: _geofencePolygons(widget.geofenceLayer)),
        if (_routeVisible && routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.5,
                color: const Color(0xff13b7aa),
                borderStrokeWidth: 2,
                borderColor: Colors.white.withValues(alpha: 0.38),
              ),
            ],
          ),
        if (_alertsVisible)
          CircleLayer(
            circles: [
              for (final alert in widget.mapMissionLayer.alerts)
                CircleMarker(
                  point: LatLng(alert.lat, alert.lng),
                  radius: _alertRadius(alert),
                  color: _alertColor(alert).withValues(alpha: 0.88),
                  borderColor: const Color(0xffffd66b),
                  borderStrokeWidth: 2,
                ),
            ],
          ),
        if (_droneVisible)
          MarkerLayer(
            markers: [
              for (final drone in widget.mapMissionLayer.drones)
                Marker(
                  point: LatLng(drone.lat, drone.lng),
                  width: 46,
                  height: 46,
                  child: DroneMapMarker(live: drone.live),
                ),
              for (
                var i = 0;
                i < widget.mapMissionLayer.route.points.length;
                i++
              )
                Marker(
                  point: LatLng(
                    widget.mapMissionLayer.route.points[i].lat,
                    widget.mapMissionLayer.route.points[i].lng,
                  ),
                  width: 30,
                  height: 30,
                  child: RouteWaypointMarker(
                    label:
                        widget.mapMissionLayer.route.points[i].label
                            .trim()
                            .isEmpty
                        ? '${i + 1}'
                        : widget.mapMissionLayer.route.points[i].label,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  double _alertRadius(MapAlertPoint alert) {
    return switch (alert.severity.toLowerCase()) {
      'critical' => 11,
      'high' => 10,
      'low' => 7,
      _ => 8,
    };
  }

  Color _alertColor(MapAlertPoint alert) {
    return switch (alert.severity.toLowerCase()) {
      'critical' => const Color(0xffff3b30),
      'high' => const Color(0xffff754f),
      'low' => const Color(0xffffb45c),
      _ => const Color(0xffff914d),
    };
  }

  List<Polygon> _geofencePolygons(GeofenceLayer layer) {
    return [
      for (final feature in layer.features)
        for (final ring in feature.coordinates)
          if (ring.length >= 3)
            Polygon(
              points: [for (final point in ring) LatLng(point.lat, point.lng)],
              color: _hexColor(
                feature.fillColor,
              ).withValues(alpha: _geofenceFillOpacity(feature)),
              borderColor: _hexColor(feature.strokeColor),
              borderStrokeWidth: feature.layerType == 'mission_geofence'
                  ? 3
                  : 2,
              label: feature.layerType == 'mission_geofence'
                  ? feature.name
                  : null,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
    ];
  }

  double _geofenceFillOpacity(GeofenceFeature feature) {
    final defaultOpacity = feature.fillOpacity.clamp(0.05, 0.42).toDouble();
    if (_activeBasemap.id != 'satellite') {
      return defaultOpacity;
    }
    return switch (feature.layerType) {
      'mission_geofence' => 0.055,
      'incident_perimeter' => 0.065,
      _ => 0.045,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 410,
      decoration: BoxDecoration(
        color: const Color(0xff0c1715),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffd2d8d5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Stack(
            children: [
              Positioned.fill(child: _buildInteractiveMissionMap()),
              Positioned(
                left: 16,
                top: 14,
                child: MapTitlePill(missionAvailable: widget.missionAvailable),
              ),
              Positioned(
                left: compact ? 84 : 260,
                right: 78,
                top: compact ? 96 : 14,
                child: MapSearchPanel(
                  controller: _searchController,
                  compact: compact,
                  searching: _searching,
                  results: _searchResults,
                  searchFocus: _searchFocus,
                  error: _searchError,
                  onSearch: _searchRealPlace,
                  onSelectResult: _focusSearchResult,
                ),
              ),
              Positioned(
                left: 16,
                top: compact ? 96 : 72,
                child: MapToolRail(
                  compact: compact,
                  routeVisible: _routeVisible,
                  geofenceVisible: _geofenceVisible,
                  infoVisible: _infoVisible,
                  onFocusRoute: _focusRoute,
                  onRecenter: _recenter,
                  onToggleRoute: _toggleRoute,
                  onToggleGeofence: _toggleGeofence,
                  onToggleInfo: _toggleInfo,
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: MapLayerRail(
                  overlaysVisible:
                      _geofenceVisible || _routeVisible || _alertsVisible,
                  satelliteBasemap: _activeBasemap.id == 'satellite',
                  droneVisible: _droneVisible,
                  onToggleOverlays: _toggleOverlays,
                  onToggleBasemap: _toggleBasemap,
                  onToggleDrone: _toggleDrone,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 78,
                child: MapZoomRail(
                  onZoomIn: () => _zoomBy(1),
                  onZoomOut: () => _zoomBy(-1),
                ),
              ),
              if (!compact && !_infoVisible)
                Positioned(
                  left: 84,
                  bottom: 82,
                  child: GeofenceStatusChip(
                    featureCount: widget.geofenceLayer.features.length,
                    geofenceVisible: _geofenceVisible,
                    boundsFitApplied: _boundsFitApplied,
                    activeTool: _activeTool,
                  ),
                ),
              if (!compact && _infoVisible)
                Positioned(
                  left: 84,
                  bottom: 82,
                  child: GeofenceLayerSummary(
                    layer: widget.geofenceLayer,
                    missionLayer: widget.mapMissionLayer,
                    basemap: _activeBasemap,
                    geofenceVisible: _geofenceVisible,
                    sourceVisible: true,
                    activeTool: _activeTool,
                    boundsFitApplied: _boundsFitApplied,
                    maxWidth: 280,
                  ),
                ),
              Positioned(
                right: 14,
                bottom: compact ? 172 : 82,
                child: MapProviderBadge(basemap: _activeBasemap, zoom: _zoom),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: MapCommandControls(
                  missionAvailable: widget.missionAvailable,
                  onStartMission: widget.onStartMission,
                  onPause: widget.onPause,
                  onAbort: widget.onAbort,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DroneMapMarker extends StatelessWidget {
  const DroneMapMarker({required this.live, super.key});

  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (live ? const Color(0xff163f32) : const Color(0xff384841))
            .withValues(alpha: 0.82),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: (live ? const Color(0xff22b7ae) : const Color(0xffffd66b))
                .withValues(alpha: 0.42),
            blurRadius: 18,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        live ? Icons.memory : Icons.add_location_alt,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class RouteWaypointMarker extends StatelessWidget {
  const RouteWaypointMarker({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff22b7ae),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class MapSearchPanel extends StatelessWidget {
  const MapSearchPanel({
    required this.controller,
    required this.compact,
    required this.searching,
    required this.results,
    required this.onSearch,
    required this.onSelectResult,
    this.searchFocus,
    this.error,
    super.key,
  });

  final TextEditingController controller;
  final bool compact;
  final bool searching;
  final List<MapSearchResult> results;
  final MapSearchResult? searchFocus;
  final String? error;
  final VoidCallback onSearch;
  final ValueChanged<MapSearchResult> onSelectResult;

  @override
  Widget build(BuildContext context) {
    final focus = searchFocus;
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    key: const ValueKey('map-search-field'),
                    controller: controller,
                    onSubmitted: (_) => onSearch(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    cursorColor: const Color(0xff22b7ae),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.10),
                      labelText: compact ? 'Place' : 'Search real place',
                      labelStyle: const TextStyle(color: Color(0xffd8e7e1)),
                      prefixIcon: const Icon(
                        Icons.travel_explore,
                        color: Color(0xffbdf9ef),
                        size: 18,
                      ),
                      prefixIconConstraints: BoxConstraints.tightFor(
                        width: compact ? 30 : 38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xff22b7ae)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 38,
                height: 38,
                child: IconButton.filled(
                  key: const ValueKey('map-search-button'),
                  onPressed: searching ? null : onSearch,
                  icon: searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xff22b7ae),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xff4d655f),
                  ),
                ),
              ),
            ],
          ),
          if (focus != null) ...[
            const SizedBox(height: 6),
            Text(
              'Search focus: ${focus.shortLabel}',
              style: const TextStyle(
                color: Color(0xffffd66b),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: const TextStyle(color: Color(0xffffb45c), fontSize: 11),
            ),
          ],
          if (results.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < results.take(2).length; i++)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: ValueKey('map-search-result-$i'),
                  onPressed: () => onSelectResult(results[i]),
                  icon: const Icon(Icons.place, size: 14),
                  label: Text(
                    results[i].displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class GeofenceStatusChip extends StatelessWidget {
  const GeofenceStatusChip({
    required this.featureCount,
    required this.geofenceVisible,
    required this.boundsFitApplied,
    required this.activeTool,
    super.key,
  });

  final int featureCount;
  final bool geofenceVisible;
  final bool boundsFitApplied;
  final String activeTool;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 172),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xff22b7ae).withValues(alpha: 0.68),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            geofenceVisible ? 'Geofence on' : 'Geofence hidden',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            featureCount == 1 ? '1 GIS layer' : '$featureCount GIS layers',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            boundsFitApplied ? 'Bounds fit' : activeTool,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xffffd66b), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class GeofenceLayerSummary extends StatelessWidget {
  const GeofenceLayerSummary({
    required this.layer,
    required this.missionLayer,
    required this.basemap,
    required this.geofenceVisible,
    required this.sourceVisible,
    required this.activeTool,
    required this.boundsFitApplied,
    this.maxWidth = 250,
    super.key,
  });

  final GeofenceLayer layer;
  final MapMissionLayer missionLayer;
  final MapBasemap basemap;
  final bool geofenceVisible;
  final bool sourceVisible;
  final String activeTool;
  final bool boundsFitApplied;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    GeofenceFeature? missionFeature;
    for (final feature in layer.features) {
      if (feature.layerType == 'mission_geofence') {
        missionFeature = feature;
        break;
      }
    }
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff22b7ae)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GEOFENCE LAYER',
            style: TextStyle(
              color: Color(0xffbdf9ef),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            missionFeature?.name ?? 'Mission geofence',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            geofenceVisible
                ? 'Layer: Mission geofence on'
                : 'Layer: Geofence hidden',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            '${layer.features.length} backend GIS features',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            'Route source: ${missionLayer.source}',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            'Viewport: ${missionLayer.bounds.label}',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            boundsFitApplied ? 'Bounds fit: Applied' : 'Bounds fit: Pending',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            'Route points: ${missionLayer.route.points.length}',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            'Map alerts: ${missionLayer.alerts.length}',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            'Attribution: ${basemap.attribution.isEmpty ? 'Not provided' : basemap.attribution}',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          Text(
            'Tile policy: ${basemap.policyLabel}',
            style: const TextStyle(color: Color(0xffd8e7e1), fontSize: 11),
          ),
          if (sourceVisible) ...[
            const SizedBox(height: 4),
            Text(
              'Map source: ${layer.source}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            activeTool,
            style: const TextStyle(color: Color(0xffffd66b), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class MapProviderBadge extends StatelessWidget {
  const MapProviderBadge({
    required this.basemap,
    required this.zoom,
    super.key,
  });

  final MapBasemap basemap;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            basemap.label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff10231d),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Zoom ${zoom.round()}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff10231d),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MapTitlePill extends StatelessWidget {
  const MapTitlePill({required this.missionAvailable, super.key});

  final bool missionAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLANNING MAP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Interactive GIS map',
            style: TextStyle(color: Color(0xffbdf9ef), fontSize: 12),
          ),
          Text(
            missionAvailable
                ? 'DJI bridge connected, mission preview ready'
                : 'No live DJI/fire feed connected',
            style: const TextStyle(color: Color(0xffd8e7e1)),
          ),
        ],
      ),
    );
  }
}

class MapToolRail extends StatelessWidget {
  const MapToolRail({
    required this.compact,
    required this.routeVisible,
    required this.geofenceVisible,
    required this.infoVisible,
    required this.onFocusRoute,
    required this.onRecenter,
    required this.onToggleRoute,
    required this.onToggleGeofence,
    required this.onToggleInfo,
    super.key,
  });

  final bool compact;
  final bool routeVisible;
  final bool geofenceVisible;
  final bool infoVisible;
  final VoidCallback onFocusRoute;
  final VoidCallback onRecenter;
  final VoidCallback onToggleRoute;
  final VoidCallback onToggleGeofence;
  final VoidCallback onToggleInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MapToolButton(
          icon: Icons.navigation,
          buttonKey: const ValueKey('map-focus-route'),
          tooltip: 'Focus mission route',
          selected: false,
          compact: compact,
          onPressed: onFocusRoute,
        ),
        MapToolButton(
          icon: Icons.location_on,
          buttonKey: const ValueKey('map-recenter'),
          tooltip: 'Recenter incident map',
          selected: false,
          compact: compact,
          onPressed: onRecenter,
        ),
        MapToolButton(
          icon: Icons.polyline,
          buttonKey: const ValueKey('map-toggle-route'),
          tooltip: 'Toggle route layer',
          selected: routeVisible,
          compact: compact,
          onPressed: onToggleRoute,
        ),
        MapToolButton(
          icon: Icons.hexagon_outlined,
          buttonKey: const ValueKey('map-toggle-geofence'),
          tooltip: 'Toggle geofence layer',
          selected: geofenceVisible,
          compact: compact,
          onPressed: onToggleGeofence,
        ),
        MapToolButton(
          icon: Icons.info_outline,
          buttonKey: const ValueKey('map-source-info'),
          tooltip: 'Show map source information',
          selected: infoVisible,
          compact: compact,
          onPressed: onToggleInfo,
        ),
      ],
    );
  }
}

class MapLayerRail extends StatelessWidget {
  const MapLayerRail({
    required this.overlaysVisible,
    required this.satelliteBasemap,
    required this.droneVisible,
    required this.onToggleOverlays,
    required this.onToggleBasemap,
    required this.onToggleDrone,
    super.key,
  });

  final bool overlaysVisible;
  final bool satelliteBasemap;
  final bool droneVisible;
  final VoidCallback onToggleOverlays;
  final VoidCallback onToggleBasemap;
  final VoidCallback onToggleDrone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MapToolButton(
          icon: Icons.layers,
          buttonKey: const ValueKey('map-toggle-overlays'),
          tooltip: 'Toggle GIS overlays',
          selected: overlaysVisible,
          onPressed: onToggleOverlays,
        ),
        MapToolButton(
          label: satelliteBasemap ? 'MAP' : 'SAT',
          buttonKey: const ValueKey('map-toggle-terrain'),
          tooltip: satelliteBasemap
              ? 'Switch to street map'
              : 'Switch to satellite imagery',
          selected: satelliteBasemap,
          onPressed: onToggleBasemap,
        ),
        MapToolButton(
          icon: Icons.my_location,
          buttonKey: const ValueKey('map-toggle-drone'),
          tooltip: 'Toggle drone marker',
          selected: droneVisible,
          onPressed: onToggleDrone,
        ),
      ],
    );
  }
}

class MapZoomRail extends StatelessWidget {
  const MapZoomRail({
    required this.onZoomIn,
    required this.onZoomOut,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MapToolButton(
          icon: Icons.add,
          buttonKey: const ValueKey('map-zoom-in'),
          tooltip: 'Zoom in map',
          selected: false,
          onPressed: onZoomIn,
        ),
        MapToolButton(
          icon: Icons.remove,
          buttonKey: const ValueKey('map-zoom-out'),
          tooltip: 'Zoom out map',
          selected: false,
          onPressed: onZoomOut,
        ),
      ],
    );
  }
}

class MapToolButton extends StatelessWidget {
  const MapToolButton({
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    this.compact = false,
    this.buttonKey,
    this.icon,
    this.label,
    super.key,
  });

  final IconData? icon;
  final String? label;
  final Key? buttonKey;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final side = compact ? 40.0 : 44.0;
    return Container(
      width: side,
      height: side,
      margin: EdgeInsets.only(bottom: compact ? 5 : 7),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xff22b7ae).withValues(alpha: 0.88)
            : Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          key: buttonKey,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: icon != null
              ? Icon(icon, color: Colors.white, size: 21)
              : Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class MapCommandControls extends StatelessWidget {
  const MapCommandControls({
    required this.missionAvailable,
    required this.onStartMission,
    required this.onPause,
    required this.onAbort,
    super.key,
  });

  final bool missionAvailable;
  final VoidCallback onStartMission;
  final VoidCallback onPause;
  final VoidCallback onAbort;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: compact ? 3 : 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff16845f),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: missionAvailable ? onStartMission : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    compact ? 'START\nMISSION' : 'START MISSION',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (compact) ...[
                SizedBox(
                  width: 48,
                  child: Tooltip(
                    message: 'Pause mission preview',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xff314046)),
                        minimumSize: const Size.fromHeight(46),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onPause,
                      child: const Icon(Icons.pause),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Tooltip(
                    message: 'Abort mission preview',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffff6157),
                        side: const BorderSide(color: Color(0xffff6157)),
                        minimumSize: const Size.fromHeight(46),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: onAbort,
                      child: const Icon(Icons.stop),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xff314046)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('PAUSE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffff6157),
                      side: const BorderSide(color: Color(0xffff6157)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: onAbort,
                    icon: const Icon(Icons.stop),
                    label: const Text('ABORT'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Color _hexColor(String value) {
  final sanitized = value.replaceFirst('#', '');
  final parsed = int.tryParse(sanitized, radix: 16);
  if (parsed == null) return Colors.white;
  return Color(0xff000000 | parsed);
}

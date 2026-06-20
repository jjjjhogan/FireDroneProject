import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/drone_connection.dart';

class MapViewport {
  const MapViewport({
    required this.centerLat,
    required this.centerLng,
    this.zoom = 11,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;

  static const defaultCenterLat = 37.211;
  static const defaultCenterLng = -119.54;

  factory MapViewport.fromFleet(List<DroneSummary> fleet) {
    final positioned = fleet
        .where((drone) => drone.lat.abs() > 0.001 && drone.lng.abs() > 0.001)
        .toList();
    if (positioned.isEmpty) {
      return const MapViewport(
        centerLat: defaultCenterLat,
        centerLng: defaultCenterLng,
      );
    }

    final lat =
        positioned.map((drone) => drone.lat).reduce((a, b) => a + b) /
        positioned.length;
    final lng =
        positioned.map((drone) => drone.lng).reduce((a, b) => a + b) /
        positioned.length;
    return MapViewport(centerLat: lat, centerLng: lng);
  }
}

int mapTileX(double lng, int zoom) {
  return (((lng + 180) / 360) * math.pow(2, zoom)).floor();
}

int mapTileY(double lat, int zoom) {
  final latRad = lat * math.pi / 180;
  return ((1 -
              math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
          2 *
          math.pow(2, zoom))
      .floor();
}

double mapWorldX(double lng, int zoom) {
  return (lng + 180) / 360 * math.pow(2, zoom);
}

double mapWorldY(double lat, int zoom) {
  final latRad = lat * math.pi / 180;
  return (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
      2 *
      math.pow(2, zoom);
}

Offset latLngToMapOffset({
  required double lat,
  required double lng,
  required double width,
  required double height,
  required MapViewport viewport,
}) {
  final centerTileX = mapTileX(viewport.centerLng, viewport.zoom);
  final centerTileY = mapTileY(viewport.centerLat, viewport.zoom);
  final left = centerTileX - 2.0;
  final top = centerTileY - 1.0;
  final worldX = mapWorldX(lng, viewport.zoom);
  final worldY = mapWorldY(lat, viewport.zoom);

  return Offset(
    ((worldX - left) / 4.0) * width,
    ((worldY - top) / 3.0) * height,
  );
}

bool hasMapPosition(DroneSummary drone) {
  return drone.lat.abs() > 0.001 && drone.lng.abs() > 0.001;
}

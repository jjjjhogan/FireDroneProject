import 'package:flutter/material.dart';

class RegionProfile {
  const RegionProfile({
    required this.id,
    required this.label,
    required this.summary,
    required this.terrainTraits,
    required this.flightChallenges,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String label;
  final String summary;
  final List<String> terrainTraits;
  final List<String> flightChallenges;
  final IconData icon;
  final Color accent;
}

const regionProfiles = [
  RegionProfile(
    id: 'mountain',
    label: 'Mountain',
    summary: 'Steep ridgelines, smoke-filled saddles, and narrow utility corridors.',
    terrainTraits: ['Ridge thermal', 'Valley inversion', 'Mutual-aid staging'],
    flightChallenges: ['Obstacle clearance', 'Wind shear', 'Limited landing zones'],
    icon: Icons.terrain,
    accent: Color(0xff315241),
  ),
  RegionProfile(
    id: 'coastal',
    label: 'Coastal',
    summary: 'Marine layer, salt air, and low-ceiling patrol along the wildland interface.',
    terrainTraits: ['Marine fog', 'Cliff escarpments', 'Harbor relay points'],
    flightChallenges: ['Visibility swings', 'Corrosion exposure', 'Tidal wind shifts'],
    icon: Icons.waves,
    accent: Color(0xff2f7d9a),
  ),
  RegionProfile(
    id: 'boreal',
    label: 'Boreal',
    summary: 'Dense conifer canopy, cold uplifts, and long-range perimeter sweeps.',
    terrainTraits: ['Canopy cover', 'Peat pockets', 'Remote relay lines'],
    flightChallenges: ['GPS multipath', 'Battery cold soak', 'Extended transit'],
    icon: Icons.park,
    accent: Color(0xff0e7656),
  ),
  RegionProfile(
    id: 'plateau',
    label: 'Plateau',
    summary: 'Open mesa tops, canyon cuts, and afternoon wind corridors.',
    terrainTraits: ['Mesa benches', 'Slot canyons', 'Dust plumes'],
    flightChallenges: ['Crosswind exposure', 'Thermal gusts', 'Relay handoffs'],
    icon: Icons.landscape,
    accent: Color(0xffc2542d),
  ),
  RegionProfile(
    id: 'desert',
    label: 'Desert',
    summary: 'Arid scrub, extreme heat, and monsoon-driven gust fronts.',
    terrainTraits: ['Arroyo networks', 'Heat shimmer', 'Sparse fuel breaks'],
    flightChallenges: ['Overheating risk', 'Mirage distortion', 'Dust-out landings'],
    icon: Icons.wb_sunny_outlined,
    accent: Color(0xffb45309),
  ),
  RegionProfile(
    id: 'grassland',
    label: 'Grassland',
    summary: 'Fast-moving grass and chaparral fires across open rolling terrain.',
    terrainTraits: ['Open range', 'Fence lines', 'Cattle guard corridors'],
    flightChallenges: ['Rate-of-spread tracking', 'Low contrast smoke', 'Long racetrack legs'],
    icon: Icons.grass,
    accent: Color(0xff4d7c0f),
  ),
  RegionProfile(
    id: 'urban-wildland',
    label: 'Urban-Wildland',
    summary: 'Structure protection at the wildland-urban interface with congested airspace.',
    terrainTraits: ['Roof clusters', 'Power corridors', 'Evacuation routes'],
    flightChallenges: ['Airspace coordination', 'EMBER spotting', 'Night ops noise'],
    icon: Icons.location_city_outlined,
    accent: Color(0xff475569),
  ),
  RegionProfile(
    id: 'subtropical',
    label: 'Subtropical',
    summary: 'Humid fuels, hurricane remnants, and heavy canopy moisture gradients.',
    terrainTraits: ['Palmetto understory', 'Swamp margins', 'Storm outflow'],
    flightChallenges: ['High humidity drift', 'Rotor wash', 'Degraded IR contrast'],
    icon: Icons.thunderstorm_outlined,
    accent: Color(0xff0369a1),
  ),
  RegionProfile(
    id: 'alpine',
    label: 'Alpine',
    summary: 'High-elevation basins, thin air, and seasonal snow-line transitions.',
    terrainTraits: ['Talus slopes', 'Glacial moraines', 'Alpine meadows'],
    flightChallenges: ['Reduced lift margin', 'Whiteout smoke', 'Rapid temp drop'],
    icon: Icons.ac_unit,
    accent: Color(0xff0f766e),
  ),
  RegionProfile(
    id: 'wetland',
    label: 'Wetland',
    summary: 'Peat smolder, standing water, and persistent low-level smoke layers.',
    terrainTraits: ['Peat bogs', 'Mangrove edges', 'Shallow thermals'],
    flightChallenges: ['Soft landing surfaces', 'Mosquito swarms', 'Smoke pooling'],
    icon: Icons.water,
    accent: Color(0xff155e75),
  ),
];

final regions = <String>[
  'All',
  for (final profile in regionProfiles) profile.label,
];

RegionProfile? regionProfileFor(String label) {
  for (final profile in regionProfiles) {
    if (profile.label == label) {
      return profile;
    }
  }
  return null;
}

RegionProfile regionProfileForScenario(String regionLabel) {
  return regionProfileFor(regionLabel) ?? regionProfiles.first;
}

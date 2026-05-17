import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class BusStop {
  BusStop({required this.id, required this.name, required this.lat, required this.lng});

  final String id;
  final String name;
  final double lat;
  final double lng;

  factory BusStop.fromJson(Map<String, dynamic> j) => BusStop(
        id: j['_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
      );
}

class StopsService {
  static List<BusStop>? _cache;

  static Future<List<BusStop>> fetchStops({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    final response = await http.get(Uri.parse('$apiBaseUrl/api/routes'));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    final List<BusStop> allStops = [];
    final Set<String> seenNames = {};

    final routes = data['routes'] as List<dynamic>? ?? [];
    for (var route in routes) {
      final stops = route['stops'] as List<dynamic>? ?? [];
      for (var s in stops) {
        final name = s['name']?.toString() ?? '';
        if (name.isNotEmpty && !seenNames.contains(name)) {
          seenNames.add(name);
          allStops.add(BusStop(
            id: s['_id']?.toString() ?? name,
            name: name,
            lat: (s['lat'] as num?)?.toDouble() ?? 0,
            lng: (s['lng'] as num?)?.toDouble() ?? 0,
          ));
        }
      }
    }

    allStops.sort((a, b) => a.name.compareTo(b.name));
    _cache = allStops;
    return _cache!;
  }

  static void clearCache() => _cache = null;
}

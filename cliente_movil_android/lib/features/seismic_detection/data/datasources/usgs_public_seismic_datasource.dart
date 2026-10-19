import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UsgsEarthquakeRecord {

  UsgsEarthquakeRecord({
    required this.id,
    required this.place,
    required this.magnitude,
    required this.latitude,
    required this.longitude,
    required this.time,
  });
  final String id;
  final String place;
  final double magnitude;
  final double latitude;
  final double longitude;
  final DateTime time;
}

/// Integrador de la Red Sismológica Pública Global (USGS)
class UsgsPublicSeismicDatasource {
  static const String usgsHourFeed =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson';

  Future<List<UsgsEarthquakeRecord>> getRecentEarthquakes() async {
    try {
      final res = await http.get(Uri.parse(usgsHourFeed)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
        final List<dynamic> features = (data['features'] as List<dynamic>?) ?? [];

        return features.take(15).map((dynamic item) {
          final Map<String, dynamic> f = item as Map<String, dynamic>;
          final Map<String, dynamic> props = f['properties'] as Map<String, dynamic>;
          final Map<String, dynamic> geom = f['geometry'] as Map<String, dynamic>;
          final List<dynamic> coords = geom['coordinates'] as List<dynamic>;

          return UsgsEarthquakeRecord(
            id: (f['id'] as String?) ?? 'USGS_EVT',
            place: (props['place'] as String?) ?? 'Estación Oficial USGS',
            magnitude: (props['mag'] as num?)?.toDouble() ?? 0.0,
            longitude: (coords[0] as num).toDouble(),
            latitude: (coords[1] as num).toDouble(),
            time: DateTime.fromMillisecondsSinceEpoch(props['time'] as int),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error consultando USGS: $e');
    }
    return [];
  }
}

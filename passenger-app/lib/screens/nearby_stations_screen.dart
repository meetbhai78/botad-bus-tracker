import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/stops_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stop_search_sheet.dart';
import 'find_bus_screen.dart';
import '../services/ad_service.dart';

/// Browse all stops — tap opens find-bus with that stop pre-selected as "from".
class NearbyStationsScreen extends StatefulWidget {
  const NearbyStationsScreen({super.key});

  @override
  State<NearbyStationsScreen> createState() => _NearbyStationsScreenState();
}

class _NearbyStationsScreenState extends State<NearbyStationsScreen> {
  final _query = TextEditingController();
  List<BusStop> _stops = [];
  bool _loading = true;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stops = await StopsService.fetchStops();
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          _position = await Geolocator.getCurrentPosition();
        }
      } catch (_) {}
      if (mounted) setState(() {
        _stops = stops;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BusStop> get _filtered {
    final q = _query.text.trim().toLowerCase();
    var list = _stops;
    if (q.isNotEmpty) list = list.where((s) => s.name.toLowerCase().contains(q)).toList();
    if (_position != null) {
      list = [...list]..sort((a, b) {
          final da = Geolocator.distanceBetween(_position!.latitude, _position!.longitude, a.lat, a.lng);
          final db = Geolocator.distanceBetween(_position!.latitude, _position!.longitude, b.lat, b.lng);
          return da.compareTo(db);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All bus stops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search stops',
            onPressed: () async {
              final stop = await showStopSearchSheet(context, title: 'Search stop');
              if (stop != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FindBusScreen(initialFrom: stop)),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search stop name...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No stops — admin panel se stops add karein'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final stop = _filtered[i];
                          double? km;
                          if (_position != null) {
                            km = Geolocator.distanceBetween(
                                  _position!.latitude,
                                  _position!.longitude,
                                  stop.lat,
                                  stop.lng,
                                ) /
                                1000;
                          }
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: const Icon(Icons.location_on, color: AppColors.primary),
                            ),
                            title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(km != null ? '${km.toStringAsFixed(1)} km away' : 'Botad'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => FindBusScreen(initialFrom: stop)),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AdService.getBannerAd(),
    );
  }
}

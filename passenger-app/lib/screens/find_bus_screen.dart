import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';
import '../services/stops_service.dart';
import '../widgets/stop_search_sheet.dart';
import 'bus_track_screen.dart';

/// Main flow: pick stops → see buses on route → tap bus → live location.
class FindBusScreen extends StatefulWidget {
  const FindBusScreen({super.key, this.embedded = false, this.initialFrom});

  final bool embedded;
  final BusStop? initialFrom;

  @override
  State<FindBusScreen> createState() => _FindBusScreenState();
}

class _FindBusScreenState extends State<FindBusScreen> {
  late BusStop? _from = widget.initialFrom;
  BusStop? _to;
  List<dynamic> _buses = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _pickFrom() async {
    final stop = await showStopSearchSheet(context, title: 'Select boarding stop');
    if (stop != null) {
      setState(() {
        _from = stop;
        if (_to?.name == stop.name) _to = null;
        _searched = false;
        _buses = [];
      });
    }
  }

  Future<void> _pickTo() async {
    if (_from == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle boarding stop select karein')),
      );
      return;
    }
    final stop = await showStopSearchSheet(
      context,
      title: 'Select destination stop',
      excludeStopName: _from!.name,
    );
    if (stop != null) {
      setState(() {
        _to = stop;
        _searched = false;
        _buses = [];
      });
    }
  }

  Future<void> _findBuses() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dono stops select karein')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
    });

    try {
      final fromQ = Uri.encodeComponent(_from!.name);
      final toQ = Uri.encodeComponent(_to!.name);
      final response = await http.get(Uri.parse('$apiBaseUrl/api/buses?from=$fromQ&to=$toQ'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _buses = data['buses'] ?? []);
      } else {
        setState(() => _buses = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openBus(Map<String, dynamic> bus) {
    final id = bus['_id']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusTrackScreen(
          busId: id,
          busName: bus['busName']?.toString() ?? 'Bus',
          busNumber: bus['busNumber']?.toString() ?? '',
          routeName: bus['route']?['routeName']?.toString() ?? '',
          fromStop: _from!.name,
          toStop: _to!.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'Find your bus',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Stop choose karein, route ki buses dekhein, bus par tap karke live location.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.embedded ? 16 : 16, 20, 8),
          child: Card(
            child: Column(
              children: [
                _StopRow(
                  label: 'From',
                  value: _from?.name,
                  hint: 'Tap to select boarding stop',
                  icon: Icons.trip_origin_rounded,
                  color: AppColors.primary,
                  onTap: _pickFrom,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _StopRow(
                  label: 'To',
                  value: _to?.name,
                  hint: 'Tap to select destination',
                  icon: Icons.place_rounded,
                  color: AppColors.accent,
                  onTap: _pickTo,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton.icon(
            onPressed: _loading ? null : _findBuses,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.directions_bus_rounded),
            label: Text(_loading ? 'Searching...' : 'Show buses on this route'),
          ),
        ),
        if (_from != null && _to != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              '${_from!.name} → ${_to!.name}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        Expanded(child: _buildResults()),
      ],
    );

    if (widget.embedded) {
      return SafeArea(child: body);
    }
    return Scaffold(appBar: AppBar(title: const Text('Find bus')), body: body);
  }

  Widget _buildResults() {
    if (!_searched) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Stops select karke "Show buses" dabayein.\nSaari stops list mein search bhi kar sakte hain.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_buses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Is route par abhi koi bus nahi mili.\nDriver trip start kare tab live dikhegi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _buses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final bus = _buses[i] as Map<String, dynamic>;
        final isLive = bus['isLive'] == true;
        final route = bus['route'];
        return Card(
          child: InkWell(
            onTap: () => _openBus(bus),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (isLive ? AppColors.primary : Colors.grey).withValues(alpha: 0.15),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: isLive ? AppColors.primary : Colors.grey,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bus['busName']} · ${bus['busNumber']}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          route?['routeName']?.toString() ?? 'Route',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Chip(
                              label: isLive ? 'LIVE' : 'Offline',
                              color: isLive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            _Chip(label: bus['status']?.toString() ?? '—', color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String hint;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      subtitle: Text(
        value ?? hint,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.unfold_more_rounded, color: AppColors.textSecondary),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

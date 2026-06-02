import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';
import '../services/stops_service.dart';
import '../widgets/stop_search_sheet.dart';
import 'bus_track_screen.dart';
import '../services/ad_service.dart';

/// Main flow: pick stops → search daily timetables & active buses → see all schedules → live track.
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
  List<dynamic> _allTimetables = [];
  bool _loading = false;
  bool _searched = false;
  final Set<String> _expandedTripIds = {};

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
      _expandedTripIds.clear();
    });

    try {
      final fromQ = Uri.encodeComponent(_from!.name);
      final toQ = Uri.encodeComponent(_to!.name);
      
      // Fetch both buses and all timetables parallelly for lightning fast loading
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/buses?from=$fromQ&to=$toQ')),
        http.get(Uri.parse('$apiBaseUrl/api/timetable')),
      ]);
      
      if (!mounted) return;
      
      List<dynamic> fetchedBuses = [];
      List<dynamic> fetchedTimetables = [];
      
      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        fetchedBuses = data['buses'] ?? [];
      }
      
      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body);
        fetchedTimetables = data['timetables'] ?? [];
      }
      
      setState(() {
        _buses = fetchedBuses;
        _allTimetables = fetchedTimetables;
      });
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

  int _parseTimeToMinutes(String hhmm) {
    try {
      final parts = hhmm.trim().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return h * 60 + m;
      }
    } catch (_) {}
    return 0;
  }

  String _formatTimeStr(String hhmm) {
    try {
      final parts = hhmm.trim().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final period = h >= 12 ? 'PM' : 'AM';
        final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        return '${displayHour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return hhmm;
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
              'Stops choose karein aur poore din ke schedules ke sath live tracking payein.',
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
    return Scaffold(
      appBar: AppBar(title: const Text('Find bus')),
      body: body,
      bottomNavigationBar: AdService.getBannerAd(),
    );
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

    // Search and match matching trips from daily timetables client-side
    final List<Map<String, dynamic>> matchingTrips = [];
    
    if (_from != null && _to != null) {
      final fromName = _from!.name.trim().toLowerCase();
      final toName = _to!.name.trim().toLowerCase();
      
      for (var tt in _allTimetables) {
        final schedule = tt['schedule'] as List<dynamic>? ?? [];
        
        final sourceIndex = schedule.indexWhere(
          (s) => s['stopName']?.toString().trim().toLowerCase() == fromName
        );
        final destIndex = schedule.indexWhere(
          (s) => s['stopName']?.toString().trim().toLowerCase() == toName
        );
        
        if (sourceIndex != -1 && destIndex != -1 && sourceIndex < destIndex) {
          matchingTrips.add({
            'timetable': tt,
            'sourceStop': schedule[sourceIndex],
            'destStop': schedule[destIndex],
            'stopsCount': destIndex - sourceIndex,
            'intermediateSchedule': schedule.sublist(sourceIndex, destIndex + 1),
          });
        }
      }
    }

    if (matchingTrips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Is route par koi scheduled timetables nahi mile.\nKripya dusra boarding ya destination select karein.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      );
    }

    // Sort matched trips chronologically by boarding stop departure time
    matchingTrips.sort((a, b) {
      final String depA = a['sourceStop']['arrivalTime']?.toString() ?? '00:00';
      final String depB = b['sourceStop']['arrivalTime']?.toString() ?? '00:00';
      return depA.compareTo(depB);
    });

    final DateTime now = DateTime.now();

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: matchingTrips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final trip = matchingTrips[i];
        final tt = trip['timetable'] as Map<String, dynamic>;
        final ttId = tt['_id']?.toString() ?? i.toString();
        
        final sourceStop = trip['sourceStop'];
        final destStop = trip['destStop'];
        final stopsCount = trip['stopsCount'] as int;
        final intermediateSchedule = trip['intermediateSchedule'] as List<dynamic>;
        
        final boardingTime = sourceStop['arrivalTime']?.toString() ?? '00:00';
        final arrivalTime = destStop['arrivalTime']?.toString() ?? '00:00';
        
        // Calculate journey duration
        final int startMin = _parseTimeToMinutes(boardingTime);
        final int endMin = _parseTimeToMinutes(arrivalTime);
        int diffMin = endMin - startMin;
        if (diffMin < 0) diffMin += 24 * 60;
        
        // BUG-2 fix: type-safe null lookup via try/catch instead of orElse: () => null
        final ttBus = tt['bus'];
        Map<String, dynamic>? activeBus;
        if (ttBus != null) {
          final ttBusId = ttBus is Map ? ttBus['_id']?.toString() : ttBus.toString();
          try {
            activeBus = _buses.firstWhere(
              (b) => b['_id']?.toString() == ttBusId,
            ) as Map<String, dynamic>;
          } catch (_) {
            activeBus = null;
          }
        }
        
        final bool isLive = activeBus != null && activeBus['isLive'] == true;
        
        // WARN-5 fix: compare minutes (int) instead of HH:mm strings
        // Prevents midnight-crossing buses (e.g. 01:00) being wrongly marked Completed at 23:45
        final int nowMin = now.hour * 60 + now.minute;
        final int boardMin = _parseTimeToMinutes(boardingTime);
        final int arrMin = _parseTimeToMinutes(arrivalTime);

        String status = 'Upcoming';
        Color statusColor = const Color(0xFF0D9488);
        if (isLive) {
          status = 'Running';
          statusColor = Colors.green;
        } else if (nowMin > arrMin && (arrMin >= boardMin || nowMin - arrMin < 60)) {
          // Completed: current time is past arrival AND it's not a midnight-wrap case
          status = 'Completed';
          statusColor = Colors.grey.shade600;
        } else {
          status = 'Upcoming';
          statusColor = const Color(0xFF0F766E);
        }
        
        final bool isExpanded = _expandedTripIds.contains(ttId);
        
        final busObj = tt['bus'];
        final String busNumber = busObj is Map 
            ? (busObj['busNumber']?.toString() ?? 'GJ-11-BT-Unassigned') 
            : 'GJ-11-BT-Unassigned';
        final String busName = busObj is Map 
            ? (busObj['busName']?.toString() ?? 'Scheduled Bus') 
            : 'Scheduled Bus';

        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isLive ? Colors.green.withValues(alpha: 0.25) : Colors.transparent,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top Info Row: Bus Details & Trip Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isLive ? Colors.green.withValues(alpha: 0.05) : Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          color: isLive ? Colors.green.shade700 : Colors.grey.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$busName · $busNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLive ? Colors.green.shade900 : AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    
                    // Live Blinking dot + Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            const _PulseBeacon(),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Transit times and journey path segment
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedTripIds.remove(ttId);
                    } else {
                      _expandedTripIds.add(ttId);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // Boarding departure details
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTimeStr(boardingTime),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _from!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Duration flow arrow indicator
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Text(
                              '$diffMin min',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$stopsCount stops',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Destination arrival details
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimeStr(arrivalTime),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _to!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expandable Stop timeline drawer
              if (isExpanded) ...[
                const Divider(height: 1, thickness: 1),
                Container(
                  color: Colors.grey.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: _buildStopsTimeline(intermediateSchedule),
                ),
              ],
              
              // Track button panel for running buses
              if (isLive) ...[
                const Divider(height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.speed_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Speed: ${((activeBus['currentLocation'] as Map?)?['speed'] as num? ?? 0.0).toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      ElevatedButton.icon(
                        onPressed: () => _openBus(activeBus!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                        label: const Text(
                          'Track Live Location',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopsTimeline(List<dynamic> stops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'STOPS TIMELINE:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...List.generate(stops.length, (idx) {
          final s = stops[idx];
          final sName = s['stopName']?.toString() ?? 'Stop';
          final sTime = s['arrivalTime']?.toString() ?? '—';
          final isFirst = idx == 0;
          final isLast = idx == stops.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 2,
                    height: 8,
                    color: isFirst ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isFirst || isLast ? AppColors.accent : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 18,
                    color: isLast ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    sName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                      color: isFirst || isLast ? AppColors.textPrimary : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _formatTimeStr(sTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isFirst || isLast ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
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

class _PulseBeacon extends StatefulWidget {
  const _PulseBeacon();

  @override
  State<_PulseBeacon> createState() => _PulseBeaconState();
}

class _PulseBeaconState extends State<_PulseBeacon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

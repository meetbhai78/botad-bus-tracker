import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';
import 'bus_track_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, this.initialFromStop});

  final String? initialFromStop;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allTimetables = [];
  List<dynamic> _activeBuses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _expandedRouteId;

  @override
  void initState() {
    super.initState();
    if (widget.initialFromStop != null) {
      _searchQuery = widget.initialFromStop!;
      _searchController.text = widget.initialFromStop!;
    }
    _fetchTimetables();
  }

  Future<void> _fetchTimetables() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/api/timetable')),
        http.get(Uri.parse('$apiBaseUrl/api/buses')),
      ]);

      if (!mounted) return;

      List<dynamic> fetchedTimetables = [];
      List<dynamic> fetchedBuses = [];

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        fetchedTimetables = data['timetables'] ?? [];
      }

      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body);
        fetchedBuses = data['buses'] ?? [];
      }

      setState(() {
        _allTimetables = fetchedTimetables;
        _activeBuses = fetchedBuses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading timetables: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedules load nahi ho sake: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, List<dynamic>> _groupTimetablesByRoute() {
    final Map<String, List<dynamic>> groups = {};
    for (var tt in _allTimetables) {
      final route = tt['route'];
      if (route == null) continue;
      final routeId = route['_id']?.toString() ?? 'unknown';
      if (!groups.containsKey(routeId)) {
        groups[routeId] = [];
      }
      groups[routeId]!.add(tt);
    }

    // Sort each group's schedules chronologically by departureTime ascending
    groups.forEach((routeId, list) {
      list.sort((a, b) {
        final String depA = a['departureTime']?.toString() ?? '00:00';
        final String depB = b['departureTime']?.toString() ?? '00:00';
        return depA.compareTo(depB);
      });
    });

    return groups;
  }

  List<String> _getFilteredRouteIds(Map<String, List<dynamic>> grouped) {
    if (_searchQuery.isEmpty) {
      return grouped.keys.toList();
    }

    final query = _searchQuery.toLowerCase().trim();
    final List<String> filteredIds = [];

    grouped.forEach((routeId, timetables) {
      if (timetables.isEmpty) return;
      final firstTt = timetables.first;
      final route = firstTt['route'] ?? {};
      final routeNumber = (route['routeNumber']?.toString() ?? '').toLowerCase();
      final routeName = (route['routeName']?.toString() ?? '').toLowerCase();

      // Check route number or route name
      if (routeNumber.contains(query) || routeName.contains(query)) {
        filteredIds.add(routeId);
        return;
      }

      // Check stops name inside schedules
      final schedule = firstTt['schedule'] as List<dynamic>? ?? [];
      for (var s in schedule) {
        final stopName = (s['stopName']?.toString() ?? '').toLowerCase();
        if (stopName.contains(query)) {
          filteredIds.add(routeId);
          return;
        }
      }
    });

    return filteredIds;
  }

  List<dynamic> _getSortedSchedule(List<dynamic> schedule) {
    final sorted = List.from(schedule);
    sorted.sort((a, b) {
      final int orderA = a['order'] is int ? a['order'] : 0;
      final int orderB = b['order'] is int ? b['order'] : 0;
      return orderA.compareTo(orderB);
    });
    return sorted;
  }

  bool _isRouteLive(String routeId) {
    return _activeBuses.any((bus) {
      final route = bus['route'];
      if (route == null) return false;
      final busRouteId = route is Map ? route['_id']?.toString() : route.toString();
      return busRouteId == routeId && bus['isLive'] == true;
    });
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
    final grouped = _groupTimetablesByRoute();
    final filteredRouteIds = _getFilteredRouteIds(grouped);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Bus Schedule & Timetable',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTimetables,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by stop, route or number...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredRouteIds.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredRouteIds.length,
                          itemBuilder: (context, index) {
                            final routeId = filteredRouteIds[index];
                            final timetables = grouped[routeId] ?? [];
                            if (timetables.isEmpty) return const SizedBox();

                            final firstTt = timetables.first;
                            final route = firstTt['route'] ?? {};
                            final routeNumber = route['routeNumber']?.toString() ?? 'R';

                            final schedule = firstTt['schedule'] as List<dynamic>? ?? [];
                            final sortedSchedule = _getSortedSchedule(schedule);

                            final firstStopName = sortedSchedule.isNotEmpty
                                ? sortedSchedule.first['stopName']?.toString() ?? 'Start'
                                : 'Start';
                            final lastStopName = sortedSchedule.isNotEmpty
                                ? sortedSchedule.last['stopName']?.toString() ?? 'End'
                                : 'End';

                            final isExpanded = _expandedRouteId == routeId;
                            final bool isRouteLiveNow = _isRouteLive(routeId);

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 14),
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: isRouteLiveNow
                                      ? Colors.green.withValues(alpha: 0.25)
                                      : (isExpanded ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  // Route Header Row
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _expandedRouteId = isExpanded ? null : routeId;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          // Route Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              routeNumber,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Destination Path Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '$firstStopName ➔ $lastStopName',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Total scheduled trips: ${timetables.length}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      width: 4,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade400,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${schedule.length} stops',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          
                                          // Pulse live banner if route has an active bus
                                          if (isRouteLiveNow) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                children: [
                                                  _PulseBeacon(),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'LIVE',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            color: Colors.grey,
                                            size: 26,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Expanded Scheduled Timetables details
                                  if (isExpanded) ...[
                                    const Divider(height: 1, thickness: 1),
                                    Container(
                                      color: Colors.grey.shade50,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4, bottom: 12),
                                            child: Text(
                                              'AVAILABLE BUSES & DEPARTURE TIMES:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF64748B),
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                          ...timetables.map((tt) {
                                            final departureTime = tt['departureTime']?.toString() ?? '00:00';
                                            final busObj = tt['bus'];
                                            final String busNumber = busObj is Map 
                                                ? (busObj['busNumber']?.toString() ?? 'Unassigned') 
                                                : 'Unassigned';
                                            final String busName = busObj is Map 
                                                ? (busObj['busName']?.toString() ?? '') 
                                                : '';
                                            final ttSchedule = tt['schedule'] as List<dynamic>? ?? [];
                                            final sortedTtSchedule = _getSortedSchedule(ttSchedule);

                                            // Check if this specific bus is active
                                            final String? busId = busObj is Map ? busObj['_id']?.toString() : (busObj is String ? busObj : null);
                                            final activeBus = _activeBuses.firstWhere(
                                              (b) => b['_id']?.toString() == busId,
                                              orElse: () => null,
                                            );
                                            final bool isLiveTrip = activeBus != null && activeBus['isLive'] == true;

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: isLiveTrip ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade200,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Top Time & Bus Row
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.access_time_filled_rounded,
                                                              color: AppColors.primary, size: 20),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            _formatTimeStr(departureTime),
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w900,
                                                              color: AppColors.primary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: isLiveTrip ? Colors.green.withValues(alpha: 0.08) : Colors.orange.shade50,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: isLiveTrip ? Colors.green.withValues(alpha: 0.25) : Colors.orange.shade200,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            if (isLiveTrip) ...[
                                                              const _PulseBeacon(),
                                                              const SizedBox(width: 6),
                                                            ],
                                                            Icon(
                                                              Icons.directions_bus_rounded,
                                                              color: isLiveTrip ? Colors.green.shade700 : Colors.orange.shade700,
                                                              size: 14,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              busNumber,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: isLiveTrip ? Colors.green.shade800 : Colors.orange.shade800,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (busName.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'Bus Details: $busName',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                  
                                                  // Track option for live runs in timetable
                                                  if (isLiveTrip && activeBus != null) ...[
                                                    const SizedBox(height: 10),
                                                    Align(
                                                      alignment: Alignment.centerRight,
                                                      child: TextButton.icon(
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) => BusTrackScreen(
                                                                busId: activeBus['_id']?.toString() ?? '',
                                                                busName: activeBus['busName']?.toString() ?? 'Bus',
                                                                busNumber: activeBus['busNumber']?.toString() ?? '',
                                                                routeName: route['routeName']?.toString() ?? '',
                                                                fromStop: firstStopName,
                                                                toStop: lastStopName,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Colors.green.shade800,
                                                          backgroundColor: Colors.green.withValues(alpha: 0.08),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        ),
                                                        icon: const Icon(Icons.gps_fixed_rounded, size: 14),
                                                        label: const Text(
                                                          'Live Tracking',
                                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ],

                                                  const SizedBox(height: 14),
                                                  // Interactive Timeline of stops
                                                  const Text(
                                                    'STOPS TIMELINE:',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.grey,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildTimeline(sortedTtSchedule),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<dynamic> schedule) {
    return Column(
      children: List.generate(schedule.length, (idx) {
        final stop = schedule[idx];
        final stopName = stop['stopName']?.toString() ?? 'Stop';
        final arrivalTime = stop['arrivalTime']?.toString() ?? '—';
        final isFirst = idx == 0;
        final isLast = idx == schedule.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line & Bullet indicators
            Column(
              children: [
                Container(
                  width: 2,
                  height: 10,
                  color: isFirst ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isFirst || isLast ? AppColors.accent : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 20,
                  color: isLast ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Stop Name
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  stopName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                    color: isFirst || isLast ? AppColors.textPrimary : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            // Time
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTimeStr(arrivalTime),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isFirst || isLast ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Schedules nahi mile!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Kripya koi dusra stop ya route search karein.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

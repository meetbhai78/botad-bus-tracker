import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, this.initialFromStop});

  final String? initialFromStop;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allTimetables = [];
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
      final response = await http.get(Uri.parse('$apiBaseUrl/api/timetable'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allTimetables = data['timetables'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allTimetables = [];
            _isLoading = false;
          });
        }
      }
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

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 14),
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: isExpanded ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
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
                                              color: AppColors.primary.withOpacity(0.1),
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
                                                Text(
                                                  'Total scheduled trips: ${timetables.length}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                                            final busObj = tt['bus'] ?? {};
                                            final busNumber = busObj['busNumber']?.toString() ?? 'Unassigned';
                                            final busName = busObj['busName']?.toString() ?? '';
                                            final ttSchedule = tt['schedule'] as List<dynamic>? ?? [];
                                            final sortedTtSchedule = _getSortedSchedule(ttSchedule);

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: Colors.grey.shade200),
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
                                                            departureTime,
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
                                                          color: Colors.orange.shade50,
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: Colors.orange.shade200),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.directions_bus_rounded,
                                                                color: Colors.orange.shade700, size: 14),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              busNumber,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.orange.shade800,
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
                  color: isFirst ? Colors.transparent : AppColors.primary.withOpacity(0.3),
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
                  color: isLast ? Colors.transparent : AppColors.primary.withOpacity(0.3),
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
                arrivalTime,
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

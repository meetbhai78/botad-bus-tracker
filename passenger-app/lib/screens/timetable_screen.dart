import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../theme/app_colors.dart';
import '../widgets/stop_search_sheet.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key, this.initialFromStop});

  final String? initialFromStop;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  List<dynamic> timetableList = [];
  bool isLoading = false;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFromStop != null) {
      _fromController.text = widget.initialFromStop!;
    }
  }

  Future<void> _fetchRoutes({bool viewAll = false}) async {
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      String url = '$apiBaseUrl/api/timetable';
      if (!viewAll && (_fromController.text.isNotEmpty || _toController.text.isNotEmpty)) {
        final fromQuery = Uri.encodeComponent(_fromController.text.trim());
        final toQuery = Uri.encodeComponent(_toController.text.trim());
        url = '$apiBaseUrl/api/timetable/search?from=$fromQuery&to=$toQuery';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => timetableList = data['timetables'] ?? []);
      } else {
        setState(() => timetableList = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routes & Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final stop = await showStopSearchSheet(context, title: 'Select from stop');
                        if (stop != null) {
                          setState(() => _fromController.text = stop.name);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'From stop (optional)',
                          prefixIcon: Icon(Icons.trip_origin, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _fromController.text.isEmpty ? 'Tap to select' : _fromController.text,
                          style: TextStyle(
                            color: _fromController.text.isEmpty ? Colors.grey : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final stop = await showStopSearchSheet(context, title: 'Select to stop');
                        if (stop != null) {
                          setState(() => _toController.text = stop.name);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'To stop (optional)',
                          prefixIcon: Icon(Icons.place, color: AppColors.accent),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _toController.text.isEmpty ? 'Tap to select' : _toController.text,
                          style: TextStyle(
                            color: _toController.text.isEmpty ? Colors.grey : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => _fetchRoutes(viewAll: true),
                            child: const Text('View All Timetables'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isLoading ? null : () => _fetchRoutes(viewAll: false),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Search'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !hasSearched
                  ? const Center(child: Text('Search or view all timetables', style: TextStyle(color: AppColors.textSecondary)))
                  : timetableList.isEmpty
                      ? const Center(child: Text('No timetables found.'))
                      : ListView.builder(
                          itemCount: timetableList.length,
                          itemBuilder: (context, index) {
                            final tt = timetableList[index];
                            final route = tt['route'] ?? {};
                            final schedule = tt['schedule'] as List<dynamic>? ?? [];
                            final label = tt['label']?.toString() ?? 'Scheduled Trip';
                            final direction = tt['direction']?.toString() ?? '';
                            
                            return Card(
                              child: ExpansionTile(
                                leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.schedule, color: Colors.white)),
                                title: Text(
                                  '${route['routeNumber'] ?? ''} - $label',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Departs at ${tt['departureTime']}' + (direction.isNotEmpty ? ' • Towards $direction' : '')),
                                children: schedule
                                    .map(
                                      (s) => ListTile(
                                        dense: true,
                                        leading: const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                        title: Text(s['stopName']?.toString() ?? ''),
                                        trailing: Text(
                                          s['arrivalTime']?.toString() ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                        ),
                                      ),
                                    )
                                    .toList(),
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
}

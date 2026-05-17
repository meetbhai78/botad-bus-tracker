import 'package:flutter/material.dart';
import '../services/stops_service.dart';
import '../theme/app_colors.dart';

/// Searchable list of all bus stops — tap to select.
Future<BusStop?> showStopSearchSheet(
  BuildContext context, {
  required String title,
  String? excludeStopName,
}) async {
  return showModalBottomSheet<BusStop>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _StopSearchSheet(title: title, excludeStopName: excludeStopName),
  );
}

class _StopSearchSheet extends StatefulWidget {
  const _StopSearchSheet({required this.title, this.excludeStopName});

  final String title;
  final String? excludeStopName;

  @override
  State<_StopSearchSheet> createState() => _StopSearchSheetState();
}

class _StopSearchSheetState extends State<_StopSearchSheet> {
  final _query = TextEditingController();
  List<BusStop> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stops = await StopsService.fetchStops();
    if (mounted) {
      setState(() {
        _all = stops;
        _loading = false;
      });
    }
  }

  List<BusStop> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _all.where((s) {
      if (widget.excludeStopName != null && s.name == widget.excludeStopName) return false;
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.85;
    return Container(
      height: maxH,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _query,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search stop name...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No stops found', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final stop = _filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                            ),
                            title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${stop.lat.toStringAsFixed(4)}, ${stop.lng.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 11)),
                            onTap: () => Navigator.pop(context, stop),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

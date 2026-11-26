import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/departments.dart';
import '../../models/complaint.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/feedback_states.dart';
import 'admin_complaint_detail_screen.dart';

/// The segregated complaint queue: filter by category, zone, priority,
/// status and date range — combinable.
class AdminQueueScreen extends StatefulWidget {
  /// Department to show; null = the signed-in admin's own scope.
  final String? dept;
  const AdminQueueScreen({super.key, this.dept});

  @override
  State<AdminQueueScreen> createState() => AdminQueueScreenState();
}

class AdminQueueScreenState extends State<AdminQueueScreen> {
  static const categories = [
    'Cleanliness', 'Electrical', 'Plumbing', 'Furniture',
    'Academics', 'Hostel', 'Other',
  ];
  static const zones = [
    'Block A', 'Block B', 'Block C', 'Library',
    'Canteen', 'Hostel', 'Parking', 'Grounds', 'Campus',
  ];
  static const priorities = ['Critical', 'High', 'Medium', 'Low'];
  static const statuses = [
    'submitted', 'assigned', 'in_progress', 'resolved', 'rejected',
    'cancelled',
  ];

  String? category;
  String? zone;
  String? priority;
  String? status;
  int? lastDays;
  String query = '';
  final _search = TextEditingController();

  /// Pure filter logic — exercised directly by widget tests.
  static List<Complaint> applyFilters(
    List<Complaint> items, {
    String? category,
    String? zone,
    String? priority,
    String? status,
    int? lastDays,
    String? query,
    DateTime? now,
  }) {
    final cutoff = lastDays == null
        ? null
        : (now ?? DateTime.now()).subtract(Duration(days: lastDays));
    final q = query?.trim().toLowerCase();
    return items.where((c) {
      if (category != null && c.ai?.category != category) return false;
      if (zone != null && c.location.zoneName != zone) return false;
      if (priority != null && c.ai?.priority != priority) return false;
      if (status != null && c.status != status) return false;
      if (cutoff != null && c.submittedAt.isBefore(cutoff)) return false;
      if (q != null && q.isNotEmpty) {
        final haystack = [
          c.description,
          c.aliasName,
          c.location.zoneName,
          c.ai?.tagline ?? '',
          c.ai?.category ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppState>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.md, Space.md, Space.md, Space.sm),
            child: Text(
                (widget.dept ?? app.profile?.adminDept) == null
                    ? 'Complaint Queue'
                    : '${Department.nameOf(widget.dept ?? app.profile?.adminDept)} Queue',
                style: theme.textTheme.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.md, 0, Space.md, Space.sm),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: 'Search description, alias, zone…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() {
                          query = '';
                          _search.clear();
                        }),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              children: [
                _FilterChip(
                  label: category ?? 'Category',
                  active: category != null,
                  options: categories,
                  onSelected: (v) => setState(() => category = v),
                ),
                _FilterChip(
                  label: zone ?? 'Zone',
                  active: zone != null,
                  options: zones,
                  onSelected: (v) => setState(() => zone = v),
                ),
                _FilterChip(
                  label: priority ?? 'Priority',
                  active: priority != null,
                  options: priorities,
                  onSelected: (v) => setState(() => priority = v),
                ),
                _FilterChip(
                  label: status == null ? 'Status' : statusLabel(status!),
                  active: status != null,
                  options: statuses,
                  display: statusLabel,
                  onSelected: (v) => setState(() => status = v),
                ),
                _FilterChip(
                  label: lastDays == null ? 'Date' : 'Last $lastDays days',
                  active: lastDays != null,
                  options: const ['7', '30', '90'],
                  display: (v) => 'Last $v days',
                  onSelected: (v) =>
                      setState(() => lastDays = v == null ? null : int.parse(v)),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: app.complaints
                  .allComplaints(dept: widget.dept ?? app.profile?.adminDept),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SkeletonList();
                }
                if (snap.hasError) {
                  return const ErrorState(
                      message: 'Couldn\'t load the queue.');
                }
                final items = applyFilters(
                  snap.data ?? [],
                  category: category,
                  zone: zone,
                  priority: priority,
                  status: status,
                  lastDays: lastDays,
                  query: query,
                );
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'No matches',
                    message:
                        'No complaints match these filters. Try clearing one.',
                    action: OutlinedButton(
                      onPressed: () => setState(() {
                        category = zone = priority = status = null;
                        lastDays = null;
                      }),
                      child: const Text('Clear all filters'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(Space.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Space.md),
                  itemBuilder: (_, i) => ComplaintCard(
                    complaint: items[i],
                    adminView: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AdminComplaintDetailScreen(
                            complaintId: items[i].id))),
                  ).animate().fadeIn(delay: (i * 40).ms, duration: Motion.fast),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final List<String> options;
  final String Function(String)? display;
  final ValueChanged<String?> onSelected;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.options,
    required this.onSelected,
    this.display,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: Space.sm),
      child: FilterChip(
        selected: active,
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(display != null && active ? label : label),
            Icon(active ? Icons.close_rounded : Icons.expand_more_rounded,
                size: 16),
          ],
        ),
        selectedColor: theme.colorScheme.primaryContainer,
        onSelected: (_) async {
          if (active) {
            onSelected(null);
            return;
          }
          final choice = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(Space.sm),
                children: options
                    .map((o) => ListTile(
                          title: Text(display?.call(o) ?? o),
                          onTap: () => Navigator.of(ctx).pop(o),
                        ))
                    .toList(),
              ),
            ),
          );
          if (choice != null) onSelected(choice);
        },
      ),
    );
  }
}

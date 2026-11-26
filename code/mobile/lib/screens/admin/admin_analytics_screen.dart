import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/departments.dart';
import '../../models/complaint.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/feedback_states.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  /// Department to show; null = the signed-in admin's own scope.
  final String? dept;
  const AdminAnalyticsScreen({super.key, this.dept});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int? _rangeDays; // null = all time

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppState>();

    return SafeArea(
      child: StreamBuilder<List<Complaint>>(
        stream: app.complaints
            .allComplaints(dept: widget.dept ?? app.profile?.adminDept),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(items: 4, height: 180);
          }
          final all = snap.data ?? [];
          final cutoff = _rangeDays == null
              ? null
              : DateTime.now().subtract(Duration(days: _rangeDays!));
          final items = cutoff == null
              ? all
              : all.where((c) => c.submittedAt.isAfter(cutoff)).toList();
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'No data yet',
              message: 'Analytics appear once complaints start coming in.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Space.md),
            children: [
              Text('Analytics', style: theme.textTheme.headlineMedium),
              const SizedBox(height: Space.xs),
              Text(
                  [
                    if ((widget.dept ?? app.profile?.adminDept) != null)
                      Department.nameOf(widget.dept ?? app.profile?.adminDept),
                    '${items.length} complaints in view',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: Space.sm),
              SegmentedButton<int?>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 days')),
                  ButtonSegment(value: 30, label: Text('30 days')),
                  ButtonSegment(value: null, label: Text('All time')),
                ],
                selected: {_rangeDays},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    setState(() => _rangeDays = s.first),
              ),
              const SizedBox(height: Space.md),
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.insights_rounded,
                  title: 'Nothing in this range',
                  message: 'Try a wider date range.',
                )
              else ...[
                _HotspotCard(items: items),
                const SizedBox(height: Space.md),
                _ChartCard(
                  title: 'BY CATEGORY',
                  child: _CategoryBars(items: items),
                ),
                const SizedBox(height: Space.md),
                _ChartCard(
                  title: 'BY ZONE',
                  child: _ZoneBars(items: items),
                ),
                const SizedBox(height: Space.md),
                _ChartCard(
                  title: 'OPEN VS RESOLVED',
                  child: _StatusDonut(items: items),
                ),
                const SizedBox(height: Space.md),
                _ResolutionStats(items: items),
                const SizedBox(height: Space.md),
                _ExportCard(items: items),
              ],
              const SizedBox(height: Space.xl),
            ],
          );
        },
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: Space.md),
            child,
          ],
        ),
      ),
    );
  }
}

Map<String, int> _countBy(
        List<Complaint> items, String Function(Complaint) key) =>
    items.fold({}, (map, c) {
      final k = key(c);
      map[k] = (map[k] ?? 0) + 1;
      return map;
    });

class _CategoryBars extends StatelessWidget {
  final List<Complaint> items;
  const _CategoryBars({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = _countBy(items, (c) => c.ai?.category ?? 'Pending');
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value.toDouble();

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: maxV * 1.2,
          barTouchData: BarTouchData(enabled: true),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entries[i].key.length > 6
                          ? entries[i].key.substring(0, 5)
                          : entries[i].key,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < entries.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  color: theme.colorScheme.primary,
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

class _ZoneBars extends StatelessWidget {
  final List<Complaint> items;
  const _ZoneBars({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = _countBy(items, (c) => c.location.zoneName);
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value;

    return Column(
      children: [
        for (final e in entries.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: Row(
              children: [
                SizedBox(
                    width: 70,
                    child: Text(e.key,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Corners.pill),
                    child: LinearProgressIndicator(
                      value: e.value / maxV,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(
                    width: 32,
                    child: Text('${e.value}',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleSmall)),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusDonut extends StatelessWidget {
  final List<Complaint> items;
  const _StatusDonut({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = _countBy(items, (c) => c.status);
    final sections = [
      ('submitted', StatusColors.submitted),
      ('assigned', StatusColors.assigned),
      ('in_progress', StatusColors.inProgress),
      ('resolved', StatusColors.resolved),
      ('rejected', StatusColors.rejected),
    ].where((s) => (counts[s.$1] ?? 0) > 0).toList();

    return Row(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 3,
              sections: [
                for (final (status, color) in sections)
                  PieChartSectionData(
                    value: counts[status]!.toDouble(),
                    color: color,
                    radius: 30,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (status, color) in sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: Row(
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: Space.sm),
                      Expanded(
                          child: Text(statusLabel(status),
                              style: theme.textTheme.bodySmall)),
                      Text('${counts[status]}',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotspotCard extends StatelessWidget {
  final List<Complaint> items;
  const _HotspotCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final week = items.where((c) =>
        c.isOpen && now.difference(c.submittedAt).inDays <= 7);
    final counts = _countBy(week.toList(), (c) => c.location.zoneName);
    if (counts.isEmpty) return const SizedBox.shrink();
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [BrandColors.accent, Color(0xFFB0A118)]),
        borderRadius: BorderRadius.circular(Corners.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 34),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hotspot this week: ${top.key}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.white)),
                Text('${top.value} open complaints in the last 7 days',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionStats extends StatelessWidget {
  final List<Complaint> items;
  const _ResolutionStats({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = items.where((c) => c.status == 'resolved').toList();

    Duration? avg;
    if (resolved.isNotEmpty) {
      var total = Duration.zero;
      var counted = 0;
      for (final c in resolved) {
        final done = c.statusHistory
            .where((h) => h.status == 'resolved')
            .toList();
        if (done.isNotEmpty) {
          total += done.first.at.difference(c.submittedAt);
          counted++;
        }
      }
      if (counted > 0) avg = total ~/ counted;
    }

    final rated = items.where((c) => c.feedback != null).toList();
    final avgRating = rated.isEmpty
        ? null
        : rated.map((c) => c.feedback!.rating).reduce((a, b) => a + b) /
            rated.length;

    String fmt(Duration d) => d.inHours >= 48
        ? '${(d.inHours / 24).toStringAsFixed(1)} days'
        : '${d.inHours} hrs';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.timer_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(height: Space.xs),
                  Text(avg == null ? '—' : fmt(avg),
                      style: theme.textTheme.titleLarge),
                  Text('Avg. resolution', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Container(
                width: 1, height: 56, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.star_rounded, color: BrandColors.warning),
                  const SizedBox(height: Space.xs),
                  Text(
                      avgRating == null
                          ? '—'
                          : avgRating.toStringAsFixed(1),
                      style: theme.textTheme.titleLarge),
                  Text('Avg. feedback', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CSV export: share as a real file, with clipboard as the fallback.
class _ExportCard extends StatelessWidget {
  final List<Complaint> items;
  const _ExportCard({required this.items});

  Future<void> _shareFile(BuildContext context) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/campuscare-report-$stamp.csv');
    await file.writeAsString(_csv());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'CampusCare complaint report ($stamp)',
    );
  }

  String _csv() {
    final b = StringBuffer(
        'id,alias,category,priority,zone,status,submittedAt,tagline\n');
    for (final c in items) {
      String esc(String? s) =>
          '"${(s ?? '').replaceAll('"', '""')}"';
      b.writeln([
        c.id,
        esc(c.aliasName),
        esc(c.ai?.category),
        esc(c.ai?.priority),
        esc(c.location.zoneName),
        c.status,
        c.submittedAt.toIso8601String(),
        esc(c.ai?.tagline),
      ].join(','));
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.table_view_rounded,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('Export report (CSV)'),
        subtitle: Text('${items.length} rows — share as a file'),
        trailing: IconButton(
          tooltip: 'Copy to clipboard instead',
          icon: const Icon(Icons.copy_rounded, size: 20),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _csv()));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'CSV copied — paste into Sheets/Excel or an email.')));
            }
          },
        ),
        onTap: () => _shareFile(context),
      ),
    );
  }
}

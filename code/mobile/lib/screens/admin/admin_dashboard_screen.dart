import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/departments.dart';
import '../../models/complaint.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/badges.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/feedback_states.dart';
import 'admin_complaint_detail_screen.dart';
import 'department_page.dart';
import 'registrations_screen.dart';

/// The admin home. Unscoped (college-wide admin): every complaint, the
/// seven department dashboards and new registrations. Scoped — a department
/// admin, or the college-wide admin opening one department — the same
/// screen limited to that department.
class AdminDashboardScreen extends StatelessWidget {
  /// Department to show; null = the signed-in admin's own scope.
  final String? dept;
  const AdminDashboardScreen({super.key, this.dept});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.read<AppState>();
    final scope = dept ?? app.profile?.adminDept;

    return SafeArea(
      child: StreamBuilder<List<Complaint>>(
        stream: app.complaints.allComplaints(dept: scope),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SkeletonList(items: 5);
          }
          if (snap.hasError) {
            return const ErrorState(
                message: 'Couldn\'t load the dashboard.');
          }
          final items = snap.data ?? [];
          final now = DateTime.now();
          final newToday = items
              .where((c) =>
                  c.submittedAt.year == now.year &&
                  c.submittedAt.month == now.month &&
                  c.submittedAt.day == now.day)
              .length;
          final open = items.where((c) => c.isOpen).length;
          final critical = items
              .where((c) => c.isOpen && c.ai?.priority == 'Critical')
              .length;
          final resolved =
              items.where((c) => c.status == 'resolved').length;
          final needsAttention = items
              .where((c) => c.isOpen)
              .toList()
            ..sort((a, b) {
              const order = ['Critical', 'High', 'Medium', 'Low'];
              final pa = order.indexOf(a.ai?.priority ?? 'Low');
              final pb = order.indexOf(b.ai?.priority ?? 'Low');
              return pa != pb
                  ? pa.compareTo(pb)
                  : b.submittedAt.compareTo(a.submittedAt);
            });

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(Space.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (dept == null) ...[
                      const GatLogo(height: 34)
                          .animate()
                          .fadeIn(duration: Motion.normal),
                      const SizedBox(height: Space.md),
                    ],
                    Text(
                        scope == null
                            ? 'Operations Dashboard'
                            : '${Department.nameOf(scope)} Dashboard',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: Space.xs),
                    Text(
                        scope == null
                            ? 'All senders are anonymized behind aliases'
                            : 'Only complaints routed to this department · '
                                'senders anonymized',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: Space.lg),
                    Row(children: [
                      Expanded(
                          child: _Tile('New today', newToday,
                              Icons.fiber_new_rounded, StatusColors.submitted)),
                      const SizedBox(width: Space.md),
                      Expanded(
                          child: _Tile('Open', open,
                              Icons.pending_actions_rounded,
                              StatusColors.inProgress)),
                    ]),
                    const SizedBox(height: Space.md),
                    Row(children: [
                      Expanded(
                          child: _Tile('Critical open', critical,
                              Icons.priority_high_rounded,
                              PriorityColors.critical)),
                      const SizedBox(width: Space.md),
                      Expanded(
                          child: _Tile('Resolved', resolved,
                              Icons.task_alt_rounded, StatusColors.resolved)),
                    ]),
                    if (scope == null) ...[
                      const SizedBox(height: Space.md),
                      const _RegistrationsTile(),
                      const SizedBox(height: Space.lg),
                      Text('DEPARTMENTS', style: theme.textTheme.labelMedium),
                      const SizedBox(height: Space.sm),
                      _DepartmentGrid(items: items),
                    ],
                    const SizedBox(height: Space.lg),
                    Text('NEEDS ATTENTION FIRST',
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: Space.sm),
                  ]),
                ),
              ),
              if (needsAttention.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.beach_access_rounded,
                    title: 'All clear!',
                    message: 'No open complaints right now. Enjoy it.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  sliver: SliverList.separated(
                    itemCount:
                        needsAttention.length.clamp(0, 5),
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: Space.md),
                    itemBuilder: (_, i) => ComplaintCard(
                      complaint: needsAttention[i],
                      adminView: true,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AdminComplaintDetailScreen(
                                  complaintId: needsAttention[i].id))),
                    ).animate().fadeIn(delay: (i * 70).ms),
                  ),
                ),
              const SliverPadding(
                  padding: EdgeInsets.only(bottom: Space.xl)),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _Tile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(label,
                        style: theme.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: Space.sm),
            CountUp(value, style: theme.textTheme.displaySmall),
          ],
        ),
      ),
    );
  }
}

/// New sign-ups, for the college-wide admin. Opens the full list.
class _RegistrationsTile extends StatefulWidget {
  const _RegistrationsTile();

  @override
  State<_RegistrationsTile> createState() => _RegistrationsTileState();
}

class _RegistrationsTileState extends State<_RegistrationsTile> {
  // Held so each complaint update doesn't re-subscribe the query.
  late final _count = context.read<AppState>().auth.unseenRegistrationCount();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<int>(
      stream: _count,
      builder: (context, snap) {
        final unseen = snap.data ?? 0;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: Badge(
              isLabelVisible: unseen > 0,
              label: Text('$unseen'),
              child: Icon(Icons.person_add_alt_1_rounded,
                  color: theme.colorScheme.primary),
            ),
            title: const Text('New registrations'),
            subtitle: Text(unseen == 0
                ? 'No new sign-ups'
                : '$unseen new ${unseen == 1 ? 'sign-up' : 'sign-ups'} to review'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const RegistrationsScreen())),
          ),
        );
      },
    );
  }
}

/// One tile per department with its open count; opens that department's
/// dashboard, queue and analytics — the same screens its own admin sees.
class _DepartmentGrid extends StatelessWidget {
  final List<Complaint> items;
  const _DepartmentGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = <String, int>{};
    for (final c in items) {
      if (c.isOpen && c.deptId != null) {
        open[c.deptId!] = (open[c.deptId!] ?? 0) + 1;
      }
    }
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - Space.sm) / 2;
      return Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final d in Department.all)
            SizedBox(
              width: w,
              child: Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DepartmentPage(dept: d.id))),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.sm + 4),
                    child: Row(
                      children: [
                        CategoryIcon(d.category),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall),
                              Text('${open[d.id] ?? 0} open',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

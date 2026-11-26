import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/complaint.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/complaint_card.dart';
import 'capture/camera_screen.dart';
import 'complaint_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    final uid = app.auth.currentUser?.uid;
    final firstName =
        (app.profile?.name.split(' ').firstOrNull ?? 'there');

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(Space.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: Space.sm),
                const GatLogo(height: 34)
                    .animate()
                    .fadeIn(duration: Motion.normal),
                const SizedBox(height: Space.md),
                Text('${L10n.t('hi')} $firstName 👋', style: theme.textTheme.headlineMedium)
                    .animate()
                    .fadeIn(duration: Motion.normal),
                const SizedBox(height: Space.xs),
                Text(L10n.t('spotted'),
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: Space.lg),
                _ReportCta(onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CameraScreen()))),
                const SizedBox(height: Space.lg),
                if (uid != null) _SummaryRow(uid: uid),
                const SizedBox(height: Space.lg),
                Text(L10n.t('recent'), style: theme.textTheme.labelMedium),
                const SizedBox(height: Space.sm),
              ]),
            ),
          ),
          if (uid != null) _RecentList(uid: uid),
          const SliverPadding(padding: EdgeInsets.only(bottom: Space.xl)),
        ],
      ),
    );
  }
}

/// The big "Report a Problem" call-to-action.
class _ReportCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.lg),
        child: Ink(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [BrandColors.primary, BrandColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(Corners.lg),
            boxShadow: Elevations.floating(theme.brightness),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Corners.md),
                ),
                child: const Icon(Icons.photo_camera_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L10n.t('report_title'),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(L10n.t('report_subtitle'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: Motion.normal)
        .slideY(begin: 0.15, duration: Motion.normal, curve: Motion.curve);
  }
}

class _SummaryRow extends StatelessWidget {
  final String uid;
  const _SummaryRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return StreamBuilder<List<Complaint>>(
      stream: app.complaints.myComplaints(uid),
      builder: (context, snap) {
        final items = snap.data ?? [];
        final active = items.where((c) => c.isOpen).length;
        final resolved =
            items.where((c) => c.status == 'resolved').length;
        return Row(
          children: [
            Expanded(
                child: _StatTile(
                    label: L10n.t('active'),
                    value: active,
                    icon: Icons.pending_actions_rounded,
                    color: StatusColors.inProgress)),
            const SizedBox(width: Space.md),
            Expanded(
                child: _StatTile(
                    label: L10n.t('resolved'),
                    value: resolved,
                    icon: Icons.task_alt_rounded,
                    color: StatusColors.resolved)),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: Space.sm + 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: theme.textTheme.headlineMedium),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final String uid;
  const _RecentList({required this.uid});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return StreamBuilder<List<Complaint>>(
      stream: app.complaints.myComplaints(uid),
      builder: (context, snap) {
        final items = (snap.data ?? []).take(3).toList();
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Row(
                    children: [
                      Icon(Icons.eco_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          'No complaints yet — ${AppConfig.campusName} thanks you for keeping an eye out!',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.md),
            itemBuilder: (_, i) => ComplaintCard(
              complaint: items[i],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ComplaintDetailScreen(complaintId: items[i].id))),
            ).animate().fadeIn(delay: (i * 80).ms, duration: Motion.normal),
          ),
        );
      },
    );
  }
}

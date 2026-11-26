import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/feedback_states.dart';

/// Everyone who has signed up, newest first, for the college-wide admin.
/// New ones are marked until the admin taps them (or marks all as seen).
class RegistrationsScreen extends StatelessWidget {
  const RegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return StreamBuilder<List<Registration>>(
      stream: app.auth.registrations(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        final unseen = items.where((r) => !r.seen).toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Registrations'),
            actions: [
              if (unseen.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    for (final r in unseen) {
                      await app.auth.markRegistrationSeen(r.email);
                    }
                  },
                  child: const Text('Mark all seen'),
                ),
            ],
          ),
          body: switch (snap) {
            _ when snap.hasError => const ErrorState(
                message: 'Couldn\'t load registrations.'),
            _ when !snap.hasData => const SkeletonList(items: 6, height: 72),
            _ when items.isEmpty => const EmptyState(
                icon: Icons.person_add_alt_1_rounded,
                title: 'No registrations yet',
                message: 'New sign-ups will appear here.',
              ),
            _ => ListView.separated(
                padding: const EdgeInsets.all(Space.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                itemBuilder: (_, i) => _RegistrationCard(items[i]),
              ),
          },
        );
      },
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final Registration r;
  const _RegistrationCard(this.r);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = r.role.isEmpty
        ? 'Student'
        : r.role[0].toUpperCase() + r.role.substring(1);
    final details = [role, if (r.dept.isNotEmpty) r.dept].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: r.seen
            ? null
            : () => context.read<AppState>().auth.markRegistrationSeen(r.email),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
              r.name.isEmpty ? '?' : r.name.characters.first.toUpperCase(),
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        ),
        title: Text(r.name.isEmpty ? r.email : r.name,
            style: r.seen
                ? theme.textTheme.titleSmall
                : theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(
            '$details\n${r.email} · ${DateFormat('d MMM, h:mm a').format(r.createdAt)}',
            style: theme.textTheme.bodySmall),
        isThreeLine: true,
        trailing: r.seen
            ? null
            : Chip(
                label: const Text('NEW'),
                visualDensity: VisualDensity.compact,
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
      ),
    );
  }
}

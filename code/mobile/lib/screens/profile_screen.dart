import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// "ISE Student" / "CSE Faculty" / "Administrator".
  static String _roleChip(AppUser? p) {
    if (p == null) return 'Student';
    if (p.isAdmin) return 'Administrator';
    final role = p.role.isEmpty ? 'student' : p.role;
    final pretty = role[0].toUpperCase() + role.substring(1);
    return '${p.dept} $pretty'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    final p = app.profile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          const SizedBox(height: Space.md),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (p?.name.isNotEmpty ?? false)
                        ? p!.name.characters.first.toUpperCase()
                        : '?',
                    style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: Space.md),
                Text(p?.name ?? '—', style: theme.textTheme.titleLarge),
                Text(p?.collegeEmail ?? '', style: theme.textTheme.bodySmall),
                const SizedBox(height: Space.xs),
                Chip(label: Text(_roleChip(p))),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined,
                      color: theme.colorScheme.primary),
                  title: const Text('Privacy'),
                  subtitle: const Text(
                      'Admins see a fun random alias on your complaints, never your name.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.location_on_outlined,
                      color: theme.colorScheme.primary),
                  title: const Text('Campus'),
                  subtitle: const Text(AppConfig.campusName),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.translate_rounded,
                      color: theme.colorScheme.primary),
                  title: Text(L10n.t('language')),
                  subtitle: Text(L10n.languages[app.lang] ?? 'English'),
                  trailing: const Icon(Icons.expand_more_rounded),
                  onTap: () async {
                    final choice = await showModalBottomSheet<String>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final e in L10n.languages.entries)
                              ListTile(
                                title: Text(e.value),
                                trailing: app.lang == e.key
                                    ? const Icon(Icons.check_rounded)
                                    : null,
                                onTap: () => Navigator.of(ctx).pop(e.key),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (choice != null) await app.setLang(choice);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('About'),
                  subtitle: const Text(
                      '${AppConfig.appName} v1.0 — AI-Based Student Grievance Management System'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          OutlinedButton.icon(
            onPressed: () async {
              await app.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (_) => false);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/chat_assistant.dart';
import '../../widgets/feedback_states.dart';
import '../profile_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_queue_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              OfflineBanner(online: app.online),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    AdminDashboardScreen(),
                    AdminQueueScreen(),
                    AdminAnalyticsScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
          const ChatAssistant(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              // College-wide admin: a count of new sign-ups on the tab.
              icon: _RegistrationBadge(
                  enabled: app.profile?.adminDept == null,
                  child: const Icon(Icons.dashboard_outlined)),
              selectedIcon: _RegistrationBadge(
                  enabled: app.profile?.adminDept == null,
                  child: const Icon(Icons.dashboard_rounded)),
              label: 'Dashboard'),
          const NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'Queue'),
          const NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Analytics'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _RegistrationBadge extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const _RegistrationBadge({required this.enabled, required this.child});

  @override
  State<_RegistrationBadge> createState() => _RegistrationBadgeState();
}

class _RegistrationBadgeState extends State<_RegistrationBadge> {
  // Held so rebuilds of the shell don't re-subscribe the query.
  late final _count = context.read<AppState>().auth.unseenRegistrationCount();

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (!widget.enabled) return child;
    return StreamBuilder<int>(
      stream: _count,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        return Badge(
            isLabelVisible: n > 0, label: Text('$n'), child: child);
      },
    );
  }
}

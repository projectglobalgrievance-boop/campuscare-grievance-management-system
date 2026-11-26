import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../widgets/chat_assistant.dart';
import '../../widgets/feedback_states.dart';
import '../profile_screen.dart';
import 'home_screen.dart';
import 'my_complaints_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              OfflineBanner(
                  online: app.online,
                  pendingCount: app.offlineQueue.pendingCount),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    HomeScreen(),
                    MyComplaintsScreen(),
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
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: L10n.t('tab_home')),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long_rounded),
              label: L10n.t('tab_complaints')),
          NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: L10n.t('tab_profile')),
        ],
      ),
    );
  }
}

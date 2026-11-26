import 'package:flutter/material.dart';

import '../../config/departments.dart';
import 'admin_analytics_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_queue_screen.dart';

/// One department, as the college-wide admin opens it from the dashboard:
/// the same dashboard, queue and analytics that department's own admin
/// sees, limited to its complaints.
class DepartmentPage extends StatefulWidget {
  final String dept;
  const DepartmentPage({super.key, required this.dept});

  @override
  State<DepartmentPage> createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Department.nameOf(widget.dept))),
      body: IndexedStack(
        index: _index,
        children: [
          AdminDashboardScreen(dept: widget.dept),
          AdminQueueScreen(dept: widget.dept),
          AdminAnalyticsScreen(dept: widget.dept),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'Queue'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Analytics'),
        ],
      ),
    );
  }
}

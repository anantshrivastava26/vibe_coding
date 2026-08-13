import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import '../alerts/alert_history_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Registered here (rather than at startup) so the device token POST
    // happens only once the user is authenticated and synced.
    NotificationService().init();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().profile;
    final isAdmin = profile?.isAdmin ?? false;

    final tabs = <_Tab>[
      _Tab(
        label: 'Alerts',
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        title: 'My Alerts',
        subtitle: profile?.locationLabel ?? 'Alerts for your area',
        body: const AlertHistoryScreen(),
      ),
      if (isAdmin)
        _Tab(
          label: 'Admin',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          title: 'Admin Dashboard',
          subtitle: 'Monitor events and dispatch alerts',
          body: const AdminDashboardScreen(),
        ),
      _Tab(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        title: 'Profile',
        subtitle: profile?.email,
        body: const ProfileScreen(),
      ),
    ];

    final current = tabs[_index.clamp(0, tabs.length - 1)];

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Text(
                              current.title,
                              key: ValueKey(current.title),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (current.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              current.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.crisis_alert, color: Colors.white, size: 28),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(current.label), child: current.body),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.coral300.withValues(alpha: 0.25),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon, color: AppColors.red600),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String? subtitle;
  final Widget body;

  _Tab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

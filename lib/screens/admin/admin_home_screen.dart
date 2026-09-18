import 'package:flutter/material.dart';
import '../../core/state/auth_controller.dart';
import '../../core/routes/app_routes.dart';
import 'admin_dashboard_screen.dart';
import 'admin_rides_screen.dart';
import 'admin_drivers_screen.dart';
import 'admin_riders_screen.dart';
import 'admin_live_ops_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_audit_log_screen.dart';
import 'admin_settings_screen.dart';

/// Root shell for the Admin Control Center.
/// Implements responsive navigation: NavigationRail on wide screens, BottomNav on mobile.
class AdminHomeScreen extends StatefulWidget {
  final AuthController? authController;
  const AdminHomeScreen({super.key, this.authController});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  late final AuthController _auth;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.live_tv_rounded, label: 'Live Ops'),
    _NavItem(icon: Icons.route_rounded, label: 'Rides'),
    _NavItem(icon: Icons.drive_eta_rounded, label: 'Drivers'),
    _NavItem(icon: Icons.people_rounded, label: 'Riders'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Audit Log'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _auth = widget.authController ?? AuthController.instance;
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return const AdminDashboardScreen();
      case 1: return const AdminLiveOpsScreen();
      case 2: return const AdminRidesScreen();
      case 3: return const AdminDriversScreen();
      case 4: return const AdminRidersScreen();
      case 5: return const AdminAnalyticsScreen();
      case 6: return const AdminAuditLogScreen();
      case 7: return const AdminSettingsScreen();
      default: return const AdminDashboardScreen();
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) AppNavigator.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarBg = isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // ─── Sidebar (wide screens) ─────────────────────────────────────────
          if (isWide)
            Container(
              width: 220,
              color: sidebarBg,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                          child: const Icon(Icons.local_taxi_rounded, size: 20, color: Colors.black),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RideSathi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Admin Center', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    ..._navItems.asMap().entries.map((e) => _SidebarItem(
                      icon: e.value.icon,
                      label: e.value.label,
                      selected: _selectedIndex == e.key,
                      onTap: () => setState(() => _selectedIndex = e.key),
                    )),
                    const Spacer(),
                    const Divider(color: Colors.white12, indent: 16, endIndent: 16),
                    _SidebarItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      selected: false,
                      onTap: _logout,
                      isDestructive: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          // ─── Main Content ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top app bar
                Container(
                  height: MediaQuery.of(context).padding.top + 56,
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (!isWide)
                          Builder(builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          )),
                        Text(
                          _navItems[_selectedIndex].label,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('ADMIN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        if (isWide)
                          GestureDetector(
                            onTap: _logout,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      // Mobile drawer
      drawer: isWide ? null : Drawer(
        backgroundColor: sidebarBg,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle), child: const Icon(Icons.local_taxi_rounded, size: 20, color: Colors.black)),
                  const SizedBox(width: 10),
                  const Text('RideSathi Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 20),
              ..._navItems.asMap().entries.map((e) => _SidebarItem(
                icon: e.value.icon,
                label: e.value.label,
                selected: _selectedIndex == e.key,
                onTap: () { setState(() => _selectedIndex = e.key); Navigator.of(context).pop(); },
              )),
              const Spacer(),
              _SidebarItem(icon: Icons.logout_rounded, label: 'Logout', selected: false, onTap: _logout, isDestructive: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: _selectedIndex > 4 ? 4 : _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey,
        items: _navItems.take(5).map((n) => BottomNavigationBarItem(icon: Icon(n.icon), label: n.label)).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade400 : selected ? const Color(0xFFF59E0B) : Colors.white60;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        ]),
      ),
    );
  }
}

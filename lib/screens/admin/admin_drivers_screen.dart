import 'package:flutter/material.dart';
import '../../core/state/admin/admin_drivers_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../models/user_model.dart';

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});
  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  late final AdminDriversController _ctrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AdminDriversController();
    _searchCtrl.addListener(() => _ctrl.setSearch(_searchCtrl.text));
  }

  @override
  void dispose() { _ctrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  String get _adminId => AuthController.instance.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Search + filter bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search drivers...',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            )),
            const SizedBox(width: 8),
            PopupMenuButton<bool?>(
              icon: const Icon(Icons.filter_list_rounded),
              onSelected: _ctrl.setOnlineFilter,
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All')),
                const PopupMenuItem(value: true, child: Text('Online')),
                const PopupMenuItem(value: false, child: Text('Offline')),
              ],
            ),
          ]),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _ctrl,
            builder: (ctx, _) {
              if (_ctrl.drivers.isLoading) return const Center(child: CircularProgressIndicator());
              if (_ctrl.drivers.isError) return Center(child: Text(_ctrl.drivers.message ?? 'Error'));
              final drivers = _ctrl.filteredDrivers;
              if (drivers.isEmpty) return const Center(child: Text('No drivers found.'));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: drivers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) => _DriverTile(
                  driver: drivers[i],
                  onVerify: () => _confirm(ctx, 'Verify ${drivers[i].name}?', 'Mark this driver as union-verified?', () => _ctrl.verifyDriver(drivers[i].id, _adminId)),
                  onSuspend: () => _suspendDialog(ctx, drivers[i]),
                  onReactivate: () => _confirm(ctx, 'Reactivate ${drivers[i].name}?', 'Remove suspension?', () => _ctrl.reactivateDriver(drivers[i].id, _adminId)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext ctx, String title, String msg, Future<void> Function() action) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      title: Text(title), content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))],
    ));
    if (ok != true || !mounted) return;
    try {
      await action();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Done.'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _suspendDialog(BuildContext ctx, UserModel driver) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      title: Text('Suspend ${driver.name}'),
      content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Suspend', style: TextStyle(color: Colors.white)))],
    ));
    if (ok != true || reasonCtrl.text.isEmpty || !mounted) return;
    try {
      await _ctrl.suspendDriver(driver.id, _adminId, reasonCtrl.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver suspended.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
}

class _DriverTile extends StatelessWidget {
  final UserModel driver;
  final VoidCallback onVerify;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  const _DriverTile({required this.driver, required this.onVerify, required this.onSuspend, required this.onReactivate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: driver.isSuspended ? Border.all(color: Colors.red.withValues(alpha: 0.4)) : null,
      ),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: driver.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
          child: Icon(Icons.person_rounded, color: driver.isOnline ? Colors.green : Colors.grey, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(driver.phoneNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (driver.vehicleInfo != null) Text(driver.vehicleInfo!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Row(children: [
            _Chip(driver.isOnline ? 'Online' : 'Offline', driver.isOnline ? Colors.green : Colors.grey),
            const SizedBox(width: 4),
            _Chip(driver.verificationStatus.name, driver.isUnionVerified ? Colors.blue : Colors.orange),
            if (driver.isSuspended) ...[const SizedBox(width: 4), _Chip('Suspended', Colors.red)],
          ]),
        ])),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'verify') {
              onVerify();
            } else if (v == 'suspend') onSuspend();
            else if (v == 'reactivate') onReactivate();
          },
          itemBuilder: (_) => [
            if (!driver.isUnionVerified) const PopupMenuItem(value: 'verify', child: Text('Verify')),
            if (!driver.isSuspended) const PopupMenuItem(value: 'suspend', child: Text('Suspend', style: TextStyle(color: Colors.red))),
            if (driver.isSuspended) const PopupMenuItem(value: 'reactivate', child: Text('Reactivate', style: TextStyle(color: Colors.green))),
          ],
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

import 'package:flutter/material.dart';
import '../../core/state/admin/admin_riders_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../models/user_model.dart';

class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});
  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  late final AdminRidersController _ctrl;
  final _searchCtrl = TextEditingController();
  String get _adminId => AuthController.instance.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _ctrl = AdminRidersController();
    _searchCtrl.addListener(() => _ctrl.setSearch(_searchCtrl.text));
  }

  @override
  void dispose() { _ctrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search riders...',
              prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _ctrl,
            builder: (ctx, _) {
              if (_ctrl.riders.isLoading) return const Center(child: CircularProgressIndicator());
              if (_ctrl.riders.isError) return Center(child: Text(_ctrl.riders.message ?? 'Error'));
              final riders = _ctrl.filteredRiders;
              if (riders.isEmpty) return const Center(child: Text('No riders found.'));
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: riders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) => _RiderTile(
                  rider: riders[i],
                  onSuspend: () => _suspendDialog(ctx, riders[i]),
                  onReactivate: () async {
                    final sm = ScaffoldMessenger.of(context);
                    await _ctrl.reactivateRider(riders[i].id, _adminId);
                    if (mounted) sm.showSnackBar(const SnackBar(content: Text('Rider reactivated.'), backgroundColor: Colors.green));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _suspendDialog(BuildContext ctx, UserModel rider) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      title: Text('Suspend ${rider.name}'),
      content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Suspend', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok != true || reasonCtrl.text.isEmpty || !mounted) return;
    try {
      await _ctrl.suspendRider(rider.id, _adminId, reasonCtrl.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rider suspended.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
}

class _RiderTile extends StatelessWidget {
  final UserModel rider;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  const _RiderTile({required this.rider, required this.onSuspend, required this.onReactivate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: rider.isSuspended ? Border.all(color: Colors.red.withValues(alpha: 0.4)) : null,
      ),
      child: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: Colors.blue.shade50, child: Icon(Icons.person_rounded, color: isDark ? Colors.white : Colors.black, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(rider.phoneNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (rider.email != null) Text(rider.email!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (rider.isSuspended) const Text('SUSPENDED', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          if (rider.createdAt != null) Text('Joined: ${rider.createdAt!.day}/${rider.createdAt!.month}/${rider.createdAt!.year}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ])),
        PopupMenuButton<String>(
          onSelected: (v) { if (v == 'suspend') {
            onSuspend();
          } else if (v == 'reactivate') onReactivate(); },
          itemBuilder: (_) => [
            if (!rider.isSuspended) const PopupMenuItem(value: 'suspend', child: Text('Suspend', style: TextStyle(color: Colors.red))),
            if (rider.isSuspended) const PopupMenuItem(value: 'reactivate', child: Text('Reactivate', style: TextStyle(color: Colors.green))),
          ],
        ),
      ]),
    );
  }
}

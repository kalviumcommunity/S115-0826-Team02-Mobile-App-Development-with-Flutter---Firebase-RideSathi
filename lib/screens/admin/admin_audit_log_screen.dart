import 'package:flutter/material.dart';
import '../../core/state/admin/admin_audit_controller.dart';
import '../../models/admin_audit_log.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});
  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  late final AdminAuditController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = AdminAuditController(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (ctx, _) {
        if (_ctrl.logs.isLoading) return const Center(child: CircularProgressIndicator());
        if (_ctrl.logs.isError) return Center(child: Text(_ctrl.logs.message ?? 'Error'));
        final logs = _ctrl.logs.data ?? [];
        if (logs.isEmpty) return const Center(child: Text('No audit logs yet.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) => _AuditTile(log: logs[i], isDark: isDark),
        );
      },
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AdminAuditLog log;
  final bool isDark;
  const _AuditTile({required this.log, required this.isDark});

  static const _actionColors = {
    'driverVerified': Colors.green,
    'driverSuspended': Colors.orange,
    'driverReactivated': Colors.blue,
    'driverRejected': Colors.red,
    'rideAssigned': Colors.blue,
    'rideReassigned': Colors.purple,
    'rideCancelled': Colors.red,
    'settingChanged': Colors.teal,
    'riderSuspended': Colors.orange,
    'riderReactivated': Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    final color = _actionColors[log.action.name] ?? Colors.grey;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.history_rounded, color: color, size: 18)),
      title: Text(log.action.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Target: ${log.targetId.length > 16 ? log.targetId.substring(0, 16) + '…' : log.targetId}', style: const TextStyle(fontSize: 11)),
        if (log.reason != null) Text('Reason: ${log.reason}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
      trailing: Text(_fmt(log.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';
import '../../core/state/admin/admin_settings_controller.dart';
import '../../core/state/auth_controller.dart';
import '../../models/system_settings.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final AdminSettingsController _ctrl;
  String get _adminId => AuthController.instance.currentUser?.id ?? '';

  @override
  void initState() { super.initState(); _ctrl = AdminSettingsController(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _editSetting(String key, String label, String hint, dynamic currentValue, bool isDouble) async {
    final tc = TextEditingController(text: currentValue.toString());
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Edit $label'),
      content: TextField(controller: tc, decoration: InputDecoration(labelText: label, hintText: hint), keyboardType: isDouble ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
      ],
    ));
    if (ok != true || !mounted) return;
    try {
      final dynamic value = isDouble ? double.parse(tc.text) : int.parse(tc.text);
      final success = await _ctrl.updateSetting(adminId: _adminId, key: key, value: value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? '$label updated.' : 'Unknown setting.'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid value: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (ctx, _) {
        if (_ctrl.settings.isLoading) return const Center(child: CircularProgressIndicator());
        if (_ctrl.settings.isError) return Center(child: Text(_ctrl.settings.message ?? 'Error'));
        final s = _ctrl.settings.data ?? SystemSettings.defaults;
        return ListView(padding: const EdgeInsets.all(16), children: [
          _InfoBanner(),
          const SizedBox(height: 16),
          Text('Matching Configuration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SettingCard(
            isDark: isDark,
            label: 'Ride Request Timeout',
            value: '${s.rideRequestTimeoutSeconds} seconds',
            description: 'Maximum time to find a driver before timing out.',
            onEdit: () => _editSetting('rideRequestTimeoutSeconds', 'Timeout (seconds)', 'e.g. 120', s.rideRequestTimeoutSeconds, false),
          ),
          _SettingCard(
            isDark: isDark,
            label: 'Matching Radius',
            value: '${s.matchingRadiusKm} km',
            description: 'Search radius for finding candidate drivers.',
            onEdit: () => _editSetting('matchingRadiusKm', 'Radius (km)', 'e.g. 5.0', s.matchingRadiusKm, true),
          ),
          _SettingCard(
            isDark: isDark,
            label: 'Max Candidates',
            value: '${s.maxCandidateCount} drivers',
            description: 'Maximum drivers offered a ride before timing out.',
            onEdit: () => _editSetting('maxCandidateCount', 'Max Candidates', 'e.g. 5', s.maxCandidateCount, false),
          ),
          const SizedBox(height: 16),
          Text('Cancellation Policy', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SettingCard(
            isDark: isDark,
            label: 'Cancellation Window',
            value: '${s.cancellationWindowSeconds} seconds',
            description: 'Time window for free ride cancellation.',
            onEdit: () => _editSetting('cancellationWindowSeconds', 'Window (seconds)', 'e.g. 300', s.cancellationWindowSeconds, false),
          ),
          const SizedBox(height: 32),
          if (_ctrl.isSaving) const Center(child: CircularProgressIndicator()),
        ]);
      },
    );
  }
}

class _SettingCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final String description;
  final VoidCallback onEdit;
  const _SettingCard({required this.isDark, required this.label, required this.value, required this.description, required this.onEdit});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600, fontSize: 15)),
      ])),
      IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
    ]),
  );
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withValues(alpha: 0.3))),
    child: const Row(children: [
      Icon(Icons.info_outline, color: Colors.blue, size: 18),
      SizedBox(width: 10),
      Expanded(child: Text('Settings are stored in Firestore and take effect immediately for new ride requests.', style: TextStyle(fontSize: 12, color: Colors.blue))),
    ]),
  );
}

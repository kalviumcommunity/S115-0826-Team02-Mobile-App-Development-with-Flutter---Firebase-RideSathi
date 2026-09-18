import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/location_model.dart';
import '../../services/real_location_service.dart';

class LocationSearchScreen extends StatefulWidget {
  final String locationType;
  const LocationSearchScreen({super.key, required this.locationType});
  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final RealLocationService _locationService = RealLocationService();
  List<LocationModel> _results = [];
  bool _isLoading = false;
  bool _isGettingCurrentLocation = false;
  String? _errorMessage;
  Timer? _debounce;

  bool get _isPickup => widget.locationType == 'pickup';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _results = []; _isLoading = false; _errorMessage = null; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await _locationService.searchLocations(query.trim());
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _errorMessage = results.isEmpty ? 'No results found. Try a different search.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = 'Search failed. Check your connection.'; });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);
    try {
      final loc = await _locationService.getCurrentLocation();
      if (mounted) Navigator.of(context).pop(loc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _isGettingCurrentLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: cardBg,
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: _onQueryChanged,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: _isPickup ? 'Search pickup location' : 'Search destination',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              prefixIcon: Icon(_isPickup ? Icons.my_location_rounded : Icons.search_rounded, color: _isPickup ? Colors.blue : const Color(0xFFF59E0B)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchController.clear(); _onQueryChanged(''); })
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: _isPickup ? Colors.blue : const Color(0xFFF59E0B), shape: BoxShape.circle)),
                      Expanded(child: Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 4), color: theme.colorScheme.outlineVariant)),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                    ],
                  ),
                ],
              ),
            ),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    color: cardBg,
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: _isGettingCurrentLocation
                            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded, color: Colors.blue),
                      ),
                      title: Text('Use current location', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text('GPS detected location', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      onTap: _isGettingCurrentLocation ? null : _useCurrentLocation,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_errorMessage != null && _searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(children: [
                        Icon(Icons.location_off_outlined, size: 52, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                  if (_results.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('RESULTS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    ..._results.asMap().entries.map((e) => Column(children: [
                      ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.location_on_rounded, color: theme.colorScheme.onPrimaryContainer, size: 22),
                        ),
                        title: Text(e.value.displayName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(e.value.address, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.of(context).pop(e.value),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      ),
                      const Divider(height: 1, indent: 80),
                    ])),
                  ],
                  if (_results.isEmpty && _searchController.text.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('QUICK PICKS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    ...<(String, IconData, Color)>[('Home', Icons.home_rounded, Colors.blue), ('Work', Icons.work_rounded, Colors.green), ('Airport', Icons.flight_rounded, Colors.purple), ('Railway Station', Icons.train_rounded, Colors.orange)].map((s) =>
                      ListTile(
                        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: s.$3.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(s.$2, color: s.$3, size: 22)),
                        title: Text(s.$1, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('Tap to search for ${s.$1}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        onTap: () { _searchController.text = s.$1; _onQueryChanged(s.$1); },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      )
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/dispatcher_history_controller.dart';
import '../../models/ride_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/ride_history_card.dart';

class DispatcherHistoryScreen extends StatefulWidget {
  const DispatcherHistoryScreen({super.key});

  @override
  State<DispatcherHistoryScreen> createState() => _DispatcherHistoryScreenState();
}

class _DispatcherHistoryScreenState extends State<DispatcherHistoryScreen> {
  late final DispatcherHistoryController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = DispatcherHistoryController();
    _controller.addListener(_onStateChanged);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadHistory(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_controller.state.isLoading && _controller.hasMore && !_controller.isLoadingMore) {
        _controller.loadHistory();
      }
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    RideStatus? tempStatus = _controller.statusFilter;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter History'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<RideStatus?>(
                    value: tempStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...RideStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        tempStatus = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _controller.clearFilters();
                    _searchController.clear();
                  },
                  child: const Text('Clear All'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _controller.setFilters(status: tempStatus);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search pickup, destination, or ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) => _controller.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: AppConstants.spaceS),
              IconButton.filledTonal(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Filter',
              ),
            ],
          ),
        ),
        Expanded(
          child: state.when(
            initial: () => const SizedBox.shrink(),
            loading: (_) => const Center(child: CircularProgressIndicator()),
            error: (message, _) => ErrorView(
              title: 'Failed to load history',
              message: message,
              onRetry: () => _controller.loadHistory(refresh: true),
            ),
            success: (history) {
              if (history.isEmpty) {
                return EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No results',
                  description: _controller.searchQuery.isNotEmpty 
                      ? 'No rides matched your search query.' 
                      : 'No rides found matching your filters.',
                );
              }

              return RefreshIndicator(
                onRefresh: () => _controller.loadHistory(refresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppConstants.spaceM),
                  itemCount: history.length + (_controller.hasMore && _controller.searchQuery.isEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == history.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppConstants.spaceM),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return RideHistoryCard(ride: history[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

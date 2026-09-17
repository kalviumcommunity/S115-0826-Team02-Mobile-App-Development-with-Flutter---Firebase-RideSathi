import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

import '../../core/state/rider_ride_history_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../models/ride_model.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/ride_history_card.dart';

/// Screen for displaying the authenticated rider's ride history.
class RiderRideHistoryScreen extends StatefulWidget {
  final RiderRideHistoryController? controller;
  
  const RiderRideHistoryScreen({
    super.key,
    this.controller,
  });

  @override
  State<RiderRideHistoryScreen> createState() => _RiderRideHistoryScreenState();
}

class _RiderRideHistoryScreenState extends State<RiderRideHistoryScreen> {
  late final RiderRideHistoryController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RiderRideHistoryController();
    _controller.addListener(_onStateChanged);
    _scrollController.addListener(_onScroll);
    
    // Defer the load slightly so it doesn't block the initial frame/animation
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.removeListener(_onStateChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Widget _buildFilterDropdown() {
    return DropdownButton<RideStatus?>(
      value: _controller.currentStatusFilter,
      icon: const Icon(Icons.filter_list, color: Colors.white),
      dropdownColor: Theme.of(context).colorScheme.surface,
      underline: const SizedBox(),
      onChanged: (RideStatus? newValue) {
        _controller.setFilter(newValue);
      },
      items: [
        const DropdownMenuItem<RideStatus?>(
          value: null,
          child: Text('All Rides', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem<RideStatus?>(
          value: RideStatus.completed,
          child: const Text('Completed', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem<RideStatus?>(
          value: RideStatus.cancelled,
          child: const Text('Cancelled', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem<RideStatus?>(
          value: RideStatus.timedOut,
          child: const Text('Timed Out', style: TextStyle(color: Colors.white)),
        ),
        DropdownMenuItem<RideStatus?>(
          value: RideStatus.rejected,
          child: const Text('Rejected', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spaceM),
            child: _buildFilterDropdown(),
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          initial: () => const SizedBox.shrink(),
          loading: (_) => const Center(child: CircularProgressIndicator()),
          error: (message, code, err) => ErrorView(
            title: 'Failed to load history',
            message: message,
            onRetry: () => _controller.loadHistory(refresh: true),
          ),
          empty: (msg) => EmptyStateView(
            icon: Icons.history_rounded,
            title: 'No rides found',
            description: _controller.currentStatusFilter == null 
              ? 'You haven\'t taken any rides yet.'
              : 'No rides match the selected filter.',
          ),
          success: (history) {

            return RefreshIndicator(
              onRefresh: () => _controller.loadHistory(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppConstants.spaceM),
                itemCount: history.length + (_controller.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == history.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppConstants.spaceM),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final ride = history[index];
                  return RideHistoryCard(
                    ride: ride,
                    onTap: (ride.status == RideStatus.completed && ride.feedback == null)
                        ? () {
                            AppNavigator.pushNamed(
                              context,
                              AppRoutes.riderFeedback,
                              arguments: {'rideId': ride.id},
                            ).then((_) => _controller.loadHistory(refresh: true));
                          }
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

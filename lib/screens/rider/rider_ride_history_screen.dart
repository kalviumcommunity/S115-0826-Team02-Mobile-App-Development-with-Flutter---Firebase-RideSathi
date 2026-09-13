import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/auth_controller.dart';
import '../../core/state/rider_ride_history_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RiderRideHistoryController();
    _controller.addListener(_onStateChanged);
    
    // Defer the load slightly so it doesn't block the initial frame/animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadHistory();
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
      ),
      body: SafeArea(
        child: state.when(
          initial: () => const SizedBox.shrink(),
          loading: (_) => const Center(child: CircularProgressIndicator()),
          error: (message, _) => ErrorView(
            title: 'Failed to load history',
            message: message,
            onRetry: _controller.loadHistory,
          ),
          success: (history) {
            if (history.isEmpty) {
              return const EmptyStateView(
                icon: Icons.history_rounded,
                title: 'No rides yet',
                description: 'You haven\'t taken any rides. Once you complete or cancel a ride, it will appear here.',
              );
            }

            return RefreshIndicator(
              onRefresh: _controller.loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spaceM),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return RideHistoryCard(
                    ride: history[index],
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

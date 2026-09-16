import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/state/ride_feedback_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/star_rating_input.dart';
import '../../widgets/info_banner.dart';

class RideFeedbackScreen extends StatefulWidget {
  final String rideId;
  final RideFeedbackController? controller;

  const RideFeedbackScreen({
    super.key,
    required this.rideId,
    this.controller,
  });

  @override
  State<RideFeedbackScreen> createState() => _RideFeedbackScreenState();
}

class _RideFeedbackScreenState extends State<RideFeedbackScreen> {
  late final RideFeedbackController _controller;
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0; // 0 indicates no rating selected yet

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RideFeedbackController();
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = _controller.state;
    if (state.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating first.')),
      );
      return;
    }
    
    final comment = _commentController.text.trim();
    await _controller.submitFeedback(
      widget.rideId,
      _rating,
      comment.isEmpty ? null : comment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Feedback'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How was your ride?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spaceS),
              Text(
                'Your feedback helps us improve the RideSathi experience.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              Center(
                child: StarRatingInput(
                  rating: _rating,
                  onRatingChanged: state.isLoading
                      ? null
                      : (newRating) {
                          setState(() {
                            _rating = newRating;
                          });
                        },
                ),
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              TextField(
                controller: _commentController,
                enabled: !state.isLoading,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Optional Comment',
                  hintText: 'Share more details about your experience...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceXL),
              if (state.isError) ...[
                InfoBanner(
                  icon: Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  message: state.message ?? 'An error occurred.',
                ),
                const SizedBox(height: AppConstants.spaceM),
              ],
              CustomButton(
                label: 'Submit Feedback',
                isLoading: state.isLoading,
                onPressed: (_rating > 0 && !state.isLoading) ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

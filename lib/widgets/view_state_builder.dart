import 'package:flutter/material.dart';
import '../core/state/view_state.dart';
import 'empty_state_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

/// A generic, stateless widget that maps a [ViewState<T>] to the corresponding
/// standardized UI component:
///
/// - [ViewStatus.initial] → [LoadingView] (or custom initial builder)
/// - [ViewStatus.loading] → [LoadingView]
/// - [ViewStatus.success] → content via [builder]
/// - [ViewStatus.empty] → [EmptyStateView]
/// - [ViewStatus.error] → [ErrorView]
///
/// This eliminates repeated switch/when logic across screens and enforces
/// consistent state presentation conventions established in PR 04 and PR 07.
class ViewStateBuilder<T> extends StatelessWidget {
  /// The current view state to render.
  final ViewState<T> state;

  /// Builder for the success state content.
  final Widget Function(BuildContext context, T data) builder;

  /// Optional retry callback propagated to [ErrorView].
  final VoidCallback? onRetry;

  /// Optional custom builder for the initial state.
  /// Defaults to [LoadingView] if not provided.
  final Widget Function(BuildContext context)? initialBuilder;

  // --- Empty State Customization ---

  /// Title for the empty state. Defaults to 'Nothing Here Yet'.
  final String emptyTitle;

  /// Description for the empty state.
  final String? emptyDescription;

  /// Icon for the empty state.
  final IconData emptyIcon;

  /// Optional action label for the empty state.
  final String? emptyActionLabel;

  /// Optional action callback for the empty state.
  final VoidCallback? onEmptyAction;

  // --- Error State Customization ---

  /// Title for the error state. Defaults to 'Something went wrong'.
  final String errorTitle;

  /// Label for the retry button. Defaults to 'Try Again'.
  final String retryLabel;

  // --- Loading State Customization ---

  /// Optional loading message.
  final String? loadingMessage;

  const ViewStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.initialBuilder,
    this.emptyTitle = 'Nothing Here Yet',
    this.emptyDescription,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorTitle = 'Something went wrong',
    this.retryLabel = 'Try Again',
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      initial: () {
        if (initialBuilder != null) {
          return initialBuilder!(context);
        }
        return LoadingView(message: loadingMessage);
      },
      loading: (message) {
        return LoadingView(message: message ?? loadingMessage);
      },
      success: (data) {
        return builder(context, data);
      },
      empty: (message) {
        return EmptyStateView(
          title: emptyTitle,
          description: message ?? emptyDescription,
          icon: emptyIcon,
          actionLabel: emptyActionLabel,
          onAction: onEmptyAction,
        );
      },
      error: (message, code, error) {
        return ErrorView(
          title: errorTitle,
          message: message,
          retryLabel: retryLabel,
          onRetry: onRetry,
        );
      },
    );
  }
}

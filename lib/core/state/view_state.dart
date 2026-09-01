import 'package:flutter/foundation.dart';

/// Represents the status of an asynchronous operation or UI state.
enum ViewStatus {
  initial,
  loading,
  success,
  empty,
  error,
}

/// Generic immutable state container representing an asynchronous operation
/// or screen view state.
///
/// Designed to interface cleanly with reusable UI components:
/// - [ViewStatus.loading] -> LoadingView
/// - [ViewStatus.error] -> ErrorView
/// - [ViewStatus.empty] -> EmptyStateView
/// - [ViewStatus.success] -> Content
@immutable
class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? message;
  final String? code;
  final Object? error;

  const ViewState._({
    required this.status,
    this.data,
    this.message,
    this.code,
    this.error,
  });

  /// Initial, idle state before any operation begins.
  const ViewState.initial() : this._(status: ViewStatus.initial);

  /// State while an asynchronous operation is in progress.
  const ViewState.loading({String? message, T? previousData})
      : this._(
          status: ViewStatus.loading,
          message: message,
          data: previousData,
        );

  /// State when the operation succeeds with [data].
  const ViewState.success(T data, {String? message})
      : this._(
          status: ViewStatus.success,
          data: data,
          message: message,
        );

  /// State when the operation succeeds but contains empty content.
  const ViewState.empty({String? message})
      : this._(
          status: ViewStatus.empty,
          message: message,
        );

  /// State when an operation fails.
  const ViewState.error(
    String message, {
    String? code,
    Object? error,
    T? previousData,
  }) : this._(
          status: ViewStatus.error,
          message: message,
          code: code,
          error: error,
          data: previousData,
        );

  // Status Convenience Getters
  bool get isInitial => status == ViewStatus.initial;
  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isEmpty => status == ViewStatus.empty;
  bool get isError => status == ViewStatus.error;
  bool get hasData => data != null;

  /// Pattern matching helper for exhaustive UI state handling.
  R when<R>({
    required R Function() initial,
    required R Function(String? message) loading,
    required R Function(T data) success,
    required R Function(String? message) empty,
    required R Function(String message, String? code, Object? error) error,
  }) {
    switch (status) {
      case ViewStatus.initial:
        return initial();
      case ViewStatus.loading:
        return loading(message);
      case ViewStatus.success:
        return success(data as T);
      case ViewStatus.empty:
        return empty(message);
      case ViewStatus.error:
        return error(message ?? 'An unknown error occurred.', code, this.error);
    }
  }

  /// Pattern matching helper with fallback.
  R maybeWhen<R>({
    R Function()? initial,
    R Function(String? message)? loading,
    R Function(T data)? success,
    R Function(String? message)? empty,
    R Function(String message, String? code, Object? error)? error,
    required R Function() orElse,
  }) {
    switch (status) {
      case ViewStatus.initial:
        return initial != null ? initial() : orElse();
      case ViewStatus.loading:
        return loading != null ? loading(message) : orElse();
      case ViewStatus.success:
        return success != null ? success(data as T) : orElse();
      case ViewStatus.empty:
        return empty != null ? empty(message) : orElse();
      case ViewStatus.error:
        return error != null
            ? error(message ?? 'An unknown error occurred.', code, this.error)
            : orElse();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViewState<T> &&
        other.status == status &&
        other.data == data &&
        other.message == message &&
        other.code == code &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(status, data, message, code, error);

  @override
  String toString() =>
      'ViewState<$T>(status: $status, data: $data, message: $message, code: $code)';
}

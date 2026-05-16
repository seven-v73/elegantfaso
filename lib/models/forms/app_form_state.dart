enum AppFormStatus { idle, dirty, saving, success, error, offline }

class AppFormState {
  const AppFormState({
    this.status = AppFormStatus.idle,
    this.message = '',
    this.progress,
  });

  final AppFormStatus status;
  final String message;
  final double? progress;

  bool get isSaving => status == AppFormStatus.saving;
  bool get hasMessage => message.trim().isNotEmpty;

  AppFormState copyWith({
    AppFormStatus? status,
    String? message,
    double? progress,
  }) {
    return AppFormState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

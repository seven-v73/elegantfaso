class FormValidationResult {
  const FormValidationResult._({required this.valid, this.message});

  final bool valid;
  final String? message;

  const FormValidationResult.ok() : this._(valid: true);
  const FormValidationResult.error(String message)
    : this._(valid: false, message: message);
}

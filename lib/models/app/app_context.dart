import '../salon/salon_context.dart';
import 'app_workspace.dart';

class AppContext {
  final AppWorkspace workspace;
  final SalonContext salonContext;
  final String source;
  final DateTime updatedAt;

  const AppContext({
    this.workspace = AppWorkspace.publicSalon,
    this.salonContext = const SalonContext(),
    this.source = '',
    required this.updatedAt,
  });

  factory AppContext.initial() {
    return AppContext(updatedAt: DateTime.now());
  }

  bool get hasSalonContext => !salonContext.isEmpty;

  AppContext copyWith({
    AppWorkspace? workspace,
    SalonContext? salonContext,
    String? source,
    DateTime? updatedAt,
  }) {
    return AppContext(
      workspace: workspace ?? this.workspace,
      salonContext: salonContext ?? this.salonContext,
      source: source ?? this.source,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

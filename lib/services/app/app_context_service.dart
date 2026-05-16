import 'dart:async';

import '../../models/app/app_context.dart';
import '../../models/app/app_workspace.dart';
import '../../models/salon/salon_context.dart';
import '../salon/salon_context_service.dart';

class AppContextService {
  factory AppContextService({SalonContextService? salonContextService}) {
    return _instance;
  }

  AppContextService._internal() : _salonContextService = SalonContextService();

  static final AppContextService _instance = AppContextService._internal();

  final SalonContextService _salonContextService;
  final StreamController<AppContext> _controller =
      StreamController<AppContext>.broadcast();

  AppContext _current = AppContext.initial();

  AppContext get current => _current;
  Stream<AppContext> get stream => _controller.stream;

  void setWorkspace(AppWorkspace workspace) {
    _emit(_current.copyWith(workspace: workspace));
  }

  Future<void> setSalonContext(
    SalonContext context, {
    String source = '',
  }) async {
    _emit(_current.copyWith(salonContext: context, source: source));
    await _salonContextService.remember(context);
  }

  Future<void> setSearchQuery(String query, {String source = 'global'}) {
    return setSalonContext(SalonContext.fromQuery(query, source: source));
  }

  Future<List<SalonContext>> recentSalonContexts() {
    return _salonContextService.loadRecent();
  }

  void clearSalonContext() {
    _emit(_current.copyWith(salonContext: const SalonContext(), source: ''));
  }

  void _emit(AppContext context) {
    _current = context;
    if (!_controller.isClosed) {
      _controller.add(_current);
    }
  }

  void dispose() {
    _controller.close();
  }
}

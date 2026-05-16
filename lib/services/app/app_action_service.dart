import '../../models/app/app_user_capabilities.dart';
import '../salon/salon_action_service.dart';
import 'user_capability_service.dart';

class AppActionResult {
  final bool allowed;
  final String message;

  const AppActionResult.allowed() : allowed = true, message = '';
  const AppActionResult.blocked(this.message) : allowed = false;
}

class AppActionService {
  AppActionService({
    UserCapabilityService? capabilityService,
    SalonActionService? salonActionService,
  }) : _capabilityService = capabilityService ?? UserCapabilityService(),
       salonActions = salonActionService ?? SalonActionService();

  final UserCapabilityService _capabilityService;
  final SalonActionService salonActions;

  Future<AppActionResult> guard(
    AppActionIntent intent, {
    String? ownerId,
  }) async {
    final capabilities = await _capabilityService.current();
    if (capabilities.can(intent, ownerId: ownerId)) {
      return const AppActionResult.allowed();
    }
    return AppActionResult.blocked(
      capabilities.blockedReason(intent, ownerId: ownerId),
    );
  }
}

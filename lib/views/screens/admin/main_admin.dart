import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design/modern_design_system.dart';
import 'core/services/auth_service.dart';
import 'dashboard/admin_dashboard.dart';
import '../auth/role_guard.dart';

void main() => runApp(AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Ajoutez d'autres providers ici
      ],
      child: MaterialApp(
        title: 'ElegantStyle Admin',
        debugShowCheckedModeBanner: false,
        theme: _buildAdminTheme(),
        home: RoleGuard(expectedRole: 'admin', child: AdminDashboard()),
      ),
    );
  }

  ThemeData _buildAdminTheme() {
    return ModernTheme.light.copyWith(
      colorScheme: ModernTheme.light.colorScheme.copyWith(
        primary: ModernColors.primary,
        secondary: ModernColors.admin,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ModernColors.surface,
        indicatorColor: ModernColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? ModernColors.primary : ModernColors.inkSoft,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0,
          );
        }),
      ),
    );
  }
}

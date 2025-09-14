import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_service.dart';
import 'dashboard/admin_dashboard.dart';
import '../auth/role_guard.dart';

void main() => runApp(AdminApp());

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Ajoutez d'autres providers ici
      ],
      child: MaterialApp(
        title: 'ElegantFaso Admin',
        debugShowCheckedModeBanner: false,
        theme: _buildAdminTheme(),
        home: RoleGuard(
          expectedRole: 'admin',
          child: AdminDashboard(),
        ),
      ),
    );
  }

  ThemeData _buildAdminTheme() {
    return ThemeData(
      primarySwatch: Colors.deepPurple,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }
}
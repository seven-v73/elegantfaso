import 'package:flutter/material.dart';

import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/app/app_workspace.dart';
import '../../../services/app/workspace_router_service.dart';

class WorkspaceRouter extends StatelessWidget {
  const WorkspaceRouter({super.key});

  static final WorkspaceRouterService _service = WorkspaceRouterService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppWorkspace>(
      future: _service.resolveCurrentWorkspace(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WorkspaceLoading();
        }

        final workspace = snapshot.data ?? AppWorkspace.client;
        return _service.widgetFor(workspace);
      },
    );
  }
}

class _WorkspaceLoading extends StatelessWidget {
  const _WorkspaceLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: Center(
        child: AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ModernColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Préparation de votre espace',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

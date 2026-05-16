import 'package:flutter/material.dart';

import '../../../design/modern_design_system.dart';
import '../../../models/forms/app_form_state.dart';
import 'app_form_status_banner.dart';
import 'app_sticky_form_bar.dart';

class AppFormScaffold extends StatelessWidget {
  const AppFormScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.secondaryLabel,
    this.onSecondary,
    this.formState = const AppFormState(),
    this.onRetry,
    this.bottomPadding = 100,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AppFormState formState;
  final VoidCallback? onRetry;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isSaving = formState.status == AppFormStatus.saving;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
      ),
      bottomNavigationBar: AppStickyFormBar(
        primaryLabel: primaryLabel,
        onPrimary: onPrimary,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
        isLoading: isSaving,
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                ModernSpacing.lg,
                ModernSpacing.md,
                ModernSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle?.trim().isNotEmpty == true) ...[
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ModernSpacing.lg),
                    ],
                    AppFormStatusBanner(state: formState, onRetry: onRetry),
                    if (formState.hasMessage ||
                        formState.status == AppFormStatus.saving)
                      const SizedBox(height: ModernSpacing.lg),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                ModernSpacing.lg,
                0,
                ModernSpacing.lg,
                bottomPadding,
              ),
              sliver: SliverList.separated(
                itemBuilder: (context, index) => children[index],
                separatorBuilder:
                    (context, index) =>
                        const SizedBox(height: ModernSpacing.lg),
                itemCount: children.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

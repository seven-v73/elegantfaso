import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/gamification/style_progress_model.dart';

class ClientStyleProgressPanel extends StatelessWidget {
  final StyleProgressModel progress;
  final VoidCallback? onOpenDetails;

  const ClientStyleProgressPanel({
    super.key,
    required this.progress,
    this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final tier = progress.visibilityTier;
    final boost = progress.visibilityPercent;
    final topBuckets =
        ([...progress.pointBuckets]
          ..sort((a, b) => b.points.compareTo(a.points))).take(2).toList();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: ModernColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: ModernColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    AppIcons.style,
                    color: ModernColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.dailyTheme,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress.dailyPrompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(AppIcons.award, color: tier.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.levelLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '${progress.lifetimePoints} pts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (boost > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+$boost%',
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.progressToNextLevel,
              minHeight: 8,
              color: tier.color,
              backgroundColor: ModernColors.line,
            ),
          ),
          const SizedBox(height: 10),
          if (progress.pointsToNextLevel > 0)
            Text(
              '${progress.pointsToNextLevel} pts avant le prochain niveau',
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topBuckets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 66,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final bucket = topBuckets[index];
              final colors = [
                ModernColors.primary,
                ModernColors.creator,
                ModernColors.client,
                ModernColors.success,
              ];
              final color = colors[index % colors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bucket.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '${bucket.points} pts',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (onOpenDetails != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenDetails,
              icon: const Icon(Icons.timeline_rounded, size: 18),
              label: const Text('Parcours'),
            ),
          ],
        ],
      ),
    );
  }
}

part of 'admin_dashboard.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Trend trend;
  final String trendValue;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = Trend.neutral,
    this.trendValue = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (trend != Trend.neutral)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          trend == Trend.up
                              ? ModernColors.success.withValues(alpha: 0.1)
                              : ModernColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trend == Trend.up
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color:
                              trend == Trend.up
                                  ? ModernColors.success
                                  : ModernColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trendValue,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color:
                                trend == Trend.up
                                    ? ModernColors.success
                                    : ModernColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ModernColors.ink,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

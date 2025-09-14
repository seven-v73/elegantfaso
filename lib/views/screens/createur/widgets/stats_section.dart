import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../createur_model.dart';

class StatsSection extends StatelessWidget {
  final CreateurModel createur;
  final int clientsCount;
  final int upcomingAppointments;

  const StatsSection({
    super.key,
    required this.createur,
    required this.clientsCount,
    required this.upcomingAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(symbol: 'XOF', decimalDigits: 0);

    final stats = [
      {
        'title': 'Commandes',
        'value': createur.ordersCount.toString(),
        'icon': Icons.shopping_bag,
        'color': const Color(0xFFE76F51),
        'trend': 0.12,
      },
      {
        'title': 'RDV',
        'value': upcomingAppointments.toString(), // Utilise la valeur dynamique
        'icon': Icons.calendar_today,
        'color': const Color(0xFF2A9D8F),
        'trend': 0.05,
      },
      {
        'title': 'Revenus',
        'value': priceFormatter.format(createur.revenue),
        'icon': Icons.attach_money,
        'color': const Color(0xFF4A6FA5),
        'trend': 0.18,
      },
      {
        'title': 'Clients',
        'value': clientsCount.toString(),
        'icon': Icons.people,
        'color': const Color(0xFF6B4E71),
        'trend': 0.08,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 4;
        final spacing = isMobile ? 12.0 : 16.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: isMobile ? 1.2 : 1.5, // Increased aspect ratio
            ),
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _StatCard(
                title: stat['title'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                color: stat['color'] as Color,
                trend: stat['trend'] as double,
              );
            },
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(14), // Slightly reduced padding
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13, // Slightly smaller font
                          color: color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6), // Reduced padding
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18), // Smaller icon
                    ),
                  ],
                ),
                const SizedBox(height: 6), // Reduced spacing
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6), // Reduced spacing
                Row(
                  children: [
                    Icon(
                      trend >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend >= 0 ? Colors.green : Colors.red,
                      size: 18, // Smaller icon
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(trend * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trend >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12, // Smaller font
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
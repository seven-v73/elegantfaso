part of 'admin_dashboard.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Trend trend;
  final String trendValue;

  const StatCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (trend != Trend.neutral)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trend == Trend.up
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          trend == Trend.up ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: trend == Trend.up ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          trendValue,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: trend == Trend.up ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
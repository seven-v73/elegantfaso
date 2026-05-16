import 'shop_activity.dart';
import 'shop_order.dart';
import 'shop_product.dart';

class ShopDashboardSummary {
  const ShopDashboardSummary({
    required this.boutiqueName,
    required this.productsCount,
    required this.publishedCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.hiddenCount,
    required this.missingImageCount,
    required this.pendingOrdersCount,
    required this.paymentProofCount,
    required this.todayAppointmentsCount,
    required this.unreadMessagesCount,
    required this.followersCount,
    required this.productViewsCount,
    required this.profileViewsCount,
    required this.estimatedRevenue,
    this.currency = 'XOF',
    required this.topProducts,
    required this.urgentOrders,
    required this.activities,
  });

  final String boutiqueName;
  final int productsCount;
  final int publishedCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int hiddenCount;
  final int missingImageCount;
  final int pendingOrdersCount;
  final int paymentProofCount;
  final int todayAppointmentsCount;
  final int unreadMessagesCount;
  final int followersCount;
  final int productViewsCount;
  final int profileViewsCount;
  final double estimatedRevenue;
  final String currency;
  final List<ShopProduct> topProducts;
  final List<ShopOrder> urgentOrders;
  final List<ShopActivity> activities;
}

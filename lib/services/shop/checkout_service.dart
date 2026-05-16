import '../../models/global/cart_item.dart';
import '../../models/shop/public_listing.dart';
import '../../models/shop/seller_info.dart';
import 'salon_product_service.dart';

class CheckoutService {
  CheckoutService({SalonProductService? productService})
    : _productService = productService ?? SalonProductService();

  final SalonProductService _productService;

  Future<void> validateCartItems(List<CartItem> items) async {
    for (final item in items) {
      final listing = PublicListing(
        id: item.productId,
        type: item.metadata['type']?.toString() ?? 'product',
        title: item.name,
        imageUrl: item.imageUrl,
        price: item.price,
        sellerId: item.sellerId,
        data: item.metadata,
      );
      final fresh = await _productService.refreshListing(listing);
      if (fresh == null) {
        throw StateError('${item.name} n’est plus disponible.');
      }
      if (!fresh.hasStock) {
        throw StateError('${item.name} est en rupture de stock.');
      }
      if (fresh.stock != null && item.quantity > fresh.stock!) {
        throw StateError(
          'Stock insuffisant pour ${item.name}. Disponible: ${fresh.stock}.',
        );
      }
      if (fresh.price != item.price) {
        throw StateError(
          'Le prix de ${item.name} a changé. Actualisez votre panier.',
        );
      }
    }
  }

  Vendor vendorFromSeller(SellerInfo seller) {
    return Vendor(
      id: seller.id,
      name: seller.name,
      role: seller.role,
      paymentMethods: seller.paymentMethods,
      phone: seller.phone,
      photoUrl: seller.imageUrl,
      speciality: seller.speciality,
      followersCount: seller.followersCount,
    );
  }
}

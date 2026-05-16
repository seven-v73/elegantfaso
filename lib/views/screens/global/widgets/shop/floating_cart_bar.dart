import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/global/cart_item.dart';
import '../../../../../services/global/cart_service.dart';
import '../../../../../services/preferences/currency_service.dart';
import '../../cart_screen.dart';

class FloatingCartBar extends StatelessWidget {
  const FloatingCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!CartService.isSignedIn) return const SizedBox.shrink();

    return StreamBuilder<List<CartItem>>(
      stream: CartService.getCartStream(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CartItem>[];
        final count = CartService.getTotalItemCount(items);
        if (count == 0) return const SizedBox.shrink();
        final total = CartService.calculateSubtotal(items);
        final currency = items.first.currency;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Material(
              color: ModernColors.primary,
              elevation: 14,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(AppIcons.cart, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$count article${count > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyService.format(total, code: currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

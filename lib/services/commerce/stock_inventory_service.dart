import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/commerce/managed_payment.dart';
import '../../models/shop/product_variant.dart';

class StockInventoryService {
  StockInventoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> reserveForPaidOrder(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'Commande introuvable.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);
      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw StateError('Commande introuvable.');
      }
      if (orderData['inventoryDeductedAt'] != null ||
          orderData['inventoryReservedAt'] != null) {
        return;
      }

      final entries = _inventoryEntriesFrom(orderData['items']);
      for (final entry in entries) {
        final itemRef = _firestore.collection(entry.collection).doc(entry.id);
        final itemSnapshot = await transaction.get(itemRef);
        if (!itemSnapshot.exists) continue;

        final itemData = itemSnapshot.data() ?? const <String, dynamic>{};
        final variants = _variantsFrom(itemData);
        final variantIndex = _variantIndexFor(variants, entry);
        final variant =
            variantIndex == null ? null : variants.elementAt(variantIndex);
        final currentVariantStock = variant?.stock;
        final currentDocumentStock = _stockFrom(itemData);
        final availableStock = currentVariantStock ?? currentDocumentStock;
        if (availableStock == null) continue;
        if (availableStock < entry.quantity) {
          throw StateError(
            'Stock insuffisant pour ${entry.label}. Disponible: $availableStock.',
          );
        }

        final nextDocumentStock =
            currentDocumentStock == null
                ? null
                : (currentDocumentStock - entry.quantity)
                    .clamp(0, 999999)
                    .toInt();
        final nextVariantStock =
            currentVariantStock == null
                ? null
                : (currentVariantStock - entry.quantity)
                    .clamp(0, 999999)
                    .toInt();
        final update = <String, dynamic>{
          'reservedStock': FieldValue.increment(entry.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (nextDocumentStock != null) {
          update['stock'] = nextDocumentStock;
          update['quantity'] = nextDocumentStock;
          update['stockStatus'] = _stockStatusFor(nextDocumentStock);
          update['isAvailable'] = nextDocumentStock > 0;
        }
        if (variantIndex != null && variant != null) {
          variants[variantIndex] = variant.copyWith(
            stock: nextVariantStock,
            reservedStock: (variant.reservedStock ?? 0) + entry.quantity,
          );
          update['variants'] = variants.map((item) => item.toMap()).toList();
        }
        transaction.set(itemRef, update, SetOptions(merge: true));
      }

      transaction.set(orderRef, {
        ...InventoryFlowLedger.reserved(
          items: entries.map((entry) => entry.toMap()).toList(),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> releaseReservedOrder(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'Commande introuvable.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);
      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw StateError('Commande introuvable.');
      }
      if (orderData['inventoryDeductedAt'] != null ||
          orderData['inventoryReservedAt'] == null ||
          orderData['inventoryReleasedAt'] != null) {
        return;
      }

      final entries = _inventoryEntriesFrom(
        orderData['inventoryReservedItems'],
      );
      for (final entry in entries) {
        final itemRef = _firestore.collection(entry.collection).doc(entry.id);
        final itemSnapshot = await transaction.get(itemRef);
        if (!itemSnapshot.exists) continue;

        final itemData = itemSnapshot.data() ?? const <String, dynamic>{};
        final variants = _variantsFrom(itemData);
        final variantIndex = _variantIndexFor(variants, entry);
        final variant =
            variantIndex == null ? null : variants.elementAt(variantIndex);
        final currentVariantStock = variant?.stock;
        final currentStock = _stockFrom(itemData);
        final nextStock =
            currentStock == null ? null : currentStock + entry.quantity;
        final update = <String, dynamic>{
          'reservedStock': FieldValue.increment(-entry.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (variantIndex != null && variant != null) {
          final nextVariantStock =
              currentVariantStock == null
                  ? null
                  : currentVariantStock + entry.quantity;
          variants[variantIndex] = variant.copyWith(
            stock: nextVariantStock,
            reservedStock:
                ((variant.reservedStock ?? entry.quantity) - entry.quantity)
                    .clamp(0, 999999)
                    .toInt(),
          );
          update['variants'] = variants.map((item) => item.toMap()).toList();
        }
        if (nextStock != null) {
          update['stock'] = nextStock;
          update['quantity'] = nextStock;
          update['stockStatus'] = _stockStatusFor(nextStock);
          update['isAvailable'] = nextStock > 0;
        }
        transaction.set(itemRef, update, SetOptions(merge: true));
      }

      transaction.set(orderRef, {
        ...InventoryFlowLedger.released(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> deductForDeliveredOrder(String orderId) async {
    if (orderId.trim().isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'Commande introuvable.');
    }

    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnapshot = await transaction.get(orderRef);
      final orderData = orderSnapshot.data();
      if (!orderSnapshot.exists || orderData == null) {
        throw StateError('Commande introuvable.');
      }
      if (orderData['inventoryDeductedAt'] != null) return;

      final wasReserved = orderData['inventoryReservedAt'] != null;
      final entries =
          wasReserved
              ? _inventoryEntriesFrom(orderData['inventoryReservedItems'])
              : _inventoryEntriesFrom(orderData['items']);
      for (final entry in entries) {
        final itemRef = _firestore.collection(entry.collection).doc(entry.id);
        final itemSnapshot = await transaction.get(itemRef);
        if (!itemSnapshot.exists) continue;

        final itemData = itemSnapshot.data() ?? const <String, dynamic>{};
        final variants = _variantsFrom(itemData);
        final variantIndex = _variantIndexFor(variants, entry);
        final variant =
            variantIndex == null ? null : variants.elementAt(variantIndex);
        final currentStock = _stockFrom(itemData);
        final update = <String, dynamic>{
          'salesCount': FieldValue.increment(entry.quantity),
          'soldCount': FieldValue.increment(entry.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (wasReserved) {
          update['reservedStock'] = FieldValue.increment(-entry.quantity);
          if (variantIndex != null && variant != null) {
            variants[variantIndex] = variant.copyWith(
              reservedStock:
                  ((variant.reservedStock ?? entry.quantity) - entry.quantity)
                      .clamp(0, 999999)
                      .toInt(),
            );
            update['variants'] = variants.map((item) => item.toMap()).toList();
          }
        } else if (currentStock != null) {
          final nextStock =
              (currentStock - entry.quantity).clamp(0, 999999).toInt();
          update['stock'] = nextStock;
          update['quantity'] = nextStock;
          update['stockStatus'] = _stockStatusFor(nextStock);
          update['isAvailable'] = nextStock > 0;
          if (variantIndex != null && variant != null) {
            final currentVariantStock = variant.stock;
            if (currentVariantStock != null) {
              variants[variantIndex] = variant.copyWith(
                stock:
                    (currentVariantStock - entry.quantity)
                        .clamp(0, 999999)
                        .toInt(),
              );
              update['variants'] =
                  variants.map((item) => item.toMap()).toList();
            }
          }
        }
        transaction.set(itemRef, update, SetOptions(merge: true));
      }

      transaction.set(orderRef, {
        ...InventoryFlowLedger.deducted(
          items: entries.map((entry) => entry.toMap()).toList(),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static List<InventoryDeductionEntry> previewEntries(Object? rawItems) {
    return _inventoryEntriesFrom(rawItems);
  }

  static List<InventoryDeductionEntry> _inventoryEntriesFrom(Object? rawItems) {
    if (rawItems is! Iterable) return const [];
    final grouped = <String, InventoryDeductionEntry>{};
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final id =
          item['productId']?.toString().trim().isNotEmpty == true
              ? item['productId'].toString().trim()
              : item['id']?.toString().trim() ?? '';
      if (id.isEmpty) continue;
      final metadata =
          item['metadata'] is Map
              ? Map<String, dynamic>.from(item['metadata'] as Map)
              : const <String, dynamic>{};
      final size =
          item['size']?.toString() ?? metadata['size']?.toString() ?? '';
      final color =
          item['color']?.toString() ?? metadata['color']?.toString() ?? '';
      final rawRole =
          item['sellerRole']?.toString() ??
          metadata['role']?.toString() ??
          metadata['type']?.toString() ??
          '';
      final collection =
          item['collection']?.toString().trim().isNotEmpty == true
              ? item['collection'].toString().trim()
              : _collectionFor(rawRole);
      final quantity = ((item['quantity'] as num?)?.toInt() ?? 1).clamp(1, 999);
      final key =
          '$collection/$id/${ProductVariant.keyFor(size: size, color: color)}';
      final existing = grouped[key];
      grouped[key] =
          existing == null
              ? InventoryDeductionEntry(
                collection: collection,
                id: id,
                quantity: quantity,
                size: size,
                color: color,
              )
              : existing.copyWith(quantity: existing.quantity + quantity);
    }
    return grouped.values.toList();
  }

  static String _collectionFor(String rawRole) {
    final value = rawRole.toLowerCase().trim();
    if (value == 'createur' ||
        value == 'créateur' ||
        value == 'creation' ||
        value == 'création') {
      return 'creations';
    }
    return 'products';
  }

  static int? _stockFrom(Map<String, dynamic> data) {
    final raw = data['stock'] ?? data['quantity'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static List<ProductVariant> _variantsFrom(Map<String, dynamic> data) {
    final raw = data['variants'];
    if (raw is! Iterable) return <ProductVariant>[];
    return raw
        .whereType<Map>()
        .map((item) => ProductVariant.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  static int? _variantIndexFor(
    List<ProductVariant> variants,
    InventoryDeductionEntry entry,
  ) {
    if (!entry.hasVariant || variants.isEmpty) return null;
    final index = variants.indexWhere(
      (variant) => variant.matches(size: entry.size, color: entry.color),
    );
    return index < 0 ? null : index;
  }

  static String _stockStatusFor(int stock) {
    if (stock <= 0) return 'out_of_stock';
    if (stock == 1) return 'piece_unique';
    return 'available';
  }
}

class InventoryDeductionEntry {
  const InventoryDeductionEntry({
    required this.collection,
    required this.id,
    required this.quantity,
    this.size = '',
    this.color = '',
  });

  final String collection;
  final String id;
  final int quantity;
  final String size;
  final String color;

  bool get hasVariant => size.trim().isNotEmpty || color.trim().isNotEmpty;
  String get label {
    final variant = [
      if (size.trim().isNotEmpty) size.trim(),
      if (color.trim().isNotEmpty) color.trim(),
    ].join(' / ');
    return variant.isEmpty ? id : '$id ($variant)';
  }

  InventoryDeductionEntry copyWith({int? quantity}) {
    return InventoryDeductionEntry(
      collection: collection,
      id: id,
      quantity: quantity ?? this.quantity,
      size: size,
      color: color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collection': collection,
      'id': id,
      'quantity': quantity,
      if (size.trim().isNotEmpty) 'size': size,
      if (color.trim().isNotEmpty) 'color': color,
      if (hasVariant)
        'variantKey': ProductVariant.keyFor(size: size, color: color),
    };
  }
}

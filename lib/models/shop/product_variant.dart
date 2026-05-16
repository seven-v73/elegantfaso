class ProductVariant {
  const ProductVariant({
    this.size = '',
    this.color = '',
    this.stock,
    this.reservedStock,
  });

  final String size;
  final String color;
  final int? stock;
  final int? reservedStock;

  bool get hasSize => size.trim().isNotEmpty;
  bool get hasColor => color.trim().isNotEmpty;
  bool get hasManagedStock => stock != null;
  bool get isOutOfStock => hasManagedStock && stock! <= 0;
  String get key => keyFor(size: size, color: color);

  Map<String, dynamic> toMap() {
    return {
      if (hasSize) 'size': size,
      if (hasColor) 'color': color,
      if (stock != null) 'stock': stock,
      if (reservedStock != null) 'reservedStock': reservedStock,
    };
  }

  bool matches({required String size, required String color}) {
    final normalizedSize = _normalize(size);
    final normalizedColor = _normalize(color);
    final sizeOk =
        normalizedSize.isEmpty || _normalize(this.size) == normalizedSize;
    final colorOk =
        normalizedColor.isEmpty || _normalize(this.color) == normalizedColor;
    return sizeOk && colorOk;
  }

  ProductVariant copyWith({
    String? size,
    String? color,
    int? stock,
    int? reservedStock,
  }) {
    return ProductVariant(
      size: size ?? this.size,
      color: color ?? this.color,
      stock: stock ?? this.stock,
      reservedStock: reservedStock ?? this.reservedStock,
    );
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      size: map['size']?.toString() ?? '',
      color: map['color']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt(),
      reservedStock: (map['reservedStock'] as num?)?.toInt(),
    );
  }

  static String keyFor({required String size, required String color}) {
    final parts =
        [
          _normalize(size),
          _normalize(color),
        ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'default' : parts.join('|');
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

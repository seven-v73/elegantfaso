import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Vendor {
  final String id;
  final String name;
  final String role;
  final Map<String, String> paymentMethods;
  final String phone;
  final String photoUrl;
  final String speciality;
  final int followersCount;

  Vendor({
    required this.id,
    required this.name,
    required this.role,
    required this.paymentMethods,
    required this.phone,
    required this.photoUrl,
    this.speciality = '',
    this.followersCount = 0,
  });

  factory Vendor.fromCartItem(CartItem item) {
    return Vendor(
      id: item.sellerId,
      name: item.sellerName,
      role: item.metadata['role'] ?? 'boutique',
      paymentMethods: Map<String, String>.from(item.metadata['paymentMethods'] ?? {}),
      phone: item.metadata['phone'] ?? '',
      photoUrl: item.sellerImage,
      speciality: item.metadata['speciality'] ?? '',
      followersCount: item.metadata['followersCount'] ?? 0,
    );
  }
}

class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String sellerId;
  final String sellerName;
  final String sellerImage;
  final Map<String, dynamic> metadata;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.sellerId,
    required this.sellerName,
    required this.sellerImage,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerImage': sellerImage,
      'metadata': metadata,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerImage: map['sellerImage'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? sellerId,
    String? sellerName,
    String? sellerImage,
    Map<String, dynamic>? metadata,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerImage: sellerImage ?? this.sellerImage,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  final List<CartItem> cartItems;
  final double totalPrice;
  final Vendor vendor;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
    required this.vendor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _priceFormatter = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation de commande'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVendorHeader(context),
            const SizedBox(height: 16),
            Expanded(child: _buildProductList(_priceFormatter)),
            _buildPaymentSection(_priceFormatter, context),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorHeader(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(vendor.photoUrl),
              radius: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (vendor.role == 'createur' && vendor.speciality.isNotEmpty)
                    Text(
                      vendor.speciality,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  Row(
                    children: [
                      Icon(
                        vendor.role == 'boutique' ? Icons.store : Icons.person,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.role == 'boutique' ? 'Boutique' : 'Créateur',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${vendor.followersCount} abonnés',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(NumberFormat formatter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              '${item.quantity} x ${formatter.format(item.price)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Text(
              formatter.format(item.price * item.quantity),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentSection(NumberFormat formatter, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                Text(
                  formatter.format(totalPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutFormScreen(
                      cartItems: cartItems,
                      totalPrice: totalPrice,
                      vendor: vendor,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C1810),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                'Payer maintenant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutFormScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalPrice;
  final Vendor vendor;

  const CheckoutFormScreen({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
    required this.vendor,
  }) : super(key: key);

  @override
  _CheckoutFormScreenState createState() => _CheckoutFormScreenState();
}

class _CheckoutFormScreenState extends State<CheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  File? _proofImage;
  String? _selectedPaymentMethod;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.vendor.paymentMethods.keys.first;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _proofImage != null) {
      setState(() => _isSubmitting = true);

      // Envoyer les données au backend
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Commande envoyée! En attente de validation'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez ajouter une preuve de paiement'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalisation Paiement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(widget.vendor.photoUrl),
                        radius: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vendor.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.vendor.role == 'boutique'
                                        ? Colors.blue[50]
                                        : Colors.purple[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.vendor.role == 'boutique' ? 'Boutique' : 'Créateur',
                                    style: TextStyle(
                                      color: widget.vendor.role == 'boutique'
                                          ? Colors.blue[800]
                                          : Colors.purple[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.vendor.role == 'createur' && widget.vendor.speciality.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      widget.vendor.speciality,
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Moyen de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        items: widget.vendor.paymentMethods.keys.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method, style: const TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedPaymentMethod = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 16),
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            const TextSpan(
                              text: 'Numéro à payer: ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: widget.vendor.paymentMethods[_selectedPaymentMethod],
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Votre numéro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Votre numéro Orange Money',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre numéro';
                      }
                      if (value.length < 8) {
                        return 'Numéro invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Preuve de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: _proofImage == null
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Ajouter une capture d\'écran',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cliquez pour sélectionner une image',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_proofImage!, fit: BoxFit.cover, width: double.infinity),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Instructions:',
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Effectuez le paiement au numéro indiqué\n'
                            '2. Prenez une capture d\'écran de la transaction\n'
                            '3. Importez-la dans cette section',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total à payer:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            priceFormatter.format(widget.totalPrice),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C1810),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                            : const Text(
                          'Confirmer la commande',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Après paiement, votre commande sera en attente de validation par le vendeur',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color _primaryColor = const Color(0xFF2C1810);
  final Color _accentColor = const Color(0xFFD4AF37);
  final Color _lightBgColor = const Color(0xFFFBF9F6);
  final Color _surfaceColor = Colors.white;
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _subtleColor = const Color(0xFF8B7355);

  static final _priceFormatter = NumberFormat.currency(
    symbol: 'FCFA',
    decimalDigits: 0,
    locale: 'fr',
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final imageSize = screenWidth * (isCompact ? 0.16 : 0.14);

    return Scaffold(
      backgroundColor: _lightBgColor,
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<List<CartItem>>(
            stream: CartService.getCartItems(),
            builder: (context, snapshot) {
              final hasItems = snapshot.hasData && snapshot.data!.isNotEmpty;
              return hasItems
                  ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearCartDialog(context),
              )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: CartService.getCartItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(screenWidth);
          }

          final cartItems = snapshot.data ?? [];

          if (cartItems.isEmpty) {
            return _buildEmptyCart(screenWidth);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    return _buildCartItemCard(cartItems[index], isCompact, imageSize, screenWidth);
                  },
                ),
              ),
              _buildCartSummary(cartItems, isCompact),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, bool isCompact, double imageSize, double screenWidth) {
    return Card(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 12 : 16)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryCompact = constraints.maxWidth < 350;
              final role = item.metadata['role'] ?? 'boutique';
              final isCreator = role == 'createur';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: isVeryCompact ? imageSize * 0.9 : imageSize,
                      height: isVeryCompact ? imageSize * 0.9 : imageSize,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isVeryCompact ? 13 : (isCompact ? 14 : 16),
                                  color: _textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _priceFormatter.format(item.price),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: isVeryCompact ? 13 : (isCompact ? 14 : 16),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 4 : 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: isCompact ? 4 : 6,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 4 : 6,
                                vertical: isCompact ? 1 : 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCreator
                                    ? Colors.purple.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
                              ),
                              child: Text(
                                isCreator ? 'Créateur' : 'Boutique',
                                style: TextStyle(
                                  color: isCreator ? Colors.purple : Colors.blue,
                                  fontSize: isVeryCompact ? 9 : (isCompact ? 10 : 12),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: screenWidth * 0.3),
                              child: Text(
                                item.sellerName,
                                style: TextStyle(
                                  color: _subtleColor,
                                  fontSize: isVeryCompact ? 11 : (isCompact ? 12 : 14),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 8 : 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuantityControls(item, isCompact, isVeryCompact),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: isVeryCompact ? 18 : (isCompact ? 20 : 24),
                                color: Colors.red[400],
                              ),
                              onPressed: () => _removeItem(item),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                maxWidth: isVeryCompact ? 28 : (isCompact ? 32 : 40),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item, bool isCompact, bool isVeryCompact) {
    return Container(
      decoration: BoxDecoration(
        color: _lightBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _subtleColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: isVeryCompact ? 14 : (isCompact ? 16 : 18)),
            onPressed: item.quantity > 1
                ? () => _updateQuantity(item.productId, item.quantity - 1)
                : null,
            padding: EdgeInsets.all(isVeryCompact ? 3 : (isCompact ? 4 : 6)),
            constraints: BoxConstraints(
              minWidth: isVeryCompact ? 20 : (isCompact ? 24 : 30),
              minHeight: isVeryCompact ? 20 : (isCompact ? 24 : 30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isVeryCompact ? 13 : (isCompact ? 14 : 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: isVeryCompact ? 14 : (isCompact ? 16 : 18)),
            onPressed: () => _updateQuantity(item.productId, item.quantity + 1),
            padding: EdgeInsets.all(isVeryCompact ? 3 : (isCompact ? 4 : 6)),
            constraints: BoxConstraints(
              minWidth: isVeryCompact ? 20 : (isCompact ? 24 : 30),
              minHeight: isVeryCompact ? 20 : (isCompact ? 24 : 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(List<CartItem> items, bool isCompact) {
    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);
    final totalPrice = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($totalItems ${totalItems > 1 ? 'articles' : 'article'})',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              Text(
                _priceFormatter.format(totalPrice),
                style: TextStyle(
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _proceedToCheckout(items, totalPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 8 : 12)),
              ),
              child: Text(
                'Passer la commande',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(double screenWidth) {
    final isCompact = screenWidth < 600;
    final isVeryCompact = screenWidth < 350;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVeryCompact ? 16 : (isCompact ? 20 : 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: isVeryCompact ? 60 : (isCompact ? 80 : 100),
              color: _subtleColor,
            ),
            SizedBox(height: isVeryCompact ? 12 : (isCompact ? 16 : 24)),
            Text(
              'Votre panier est vide',
              style: TextStyle(
                fontSize: isVeryCompact ? 18 : (isCompact ? 20 : 24),
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: isVeryCompact ? 6 : (isCompact ? 8 : 12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 12 : 24),
              child: Text(
                'Ajoutez des produits pour commencer vos achats',
                style: TextStyle(
                  fontSize: isVeryCompact ? 12 : (isCompact ? 14 : 16),
                  color: _subtleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isVeryCompact ? 18 : (isCompact ? 24 : 32)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryCompact ? 20 : (isCompact ? 24 : 32),
                  vertical: isVeryCompact ? 10 : (isCompact ? 12 : 16),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 8 : 12)),
              ),
              child: Text(
                'Continuer mes achats',
                style: TextStyle(
                  fontSize: isVeryCompact ? 12 : (isCompact ? 14 : 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double screenWidth) {
    final isCompact = screenWidth < 600;
    final isVeryCompact = screenWidth < 350;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isVeryCompact ? 16 : (isCompact ? 20 : 32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isVeryCompact ? 50 : (isCompact ? 60 : 80),
              color: Colors.red[400],
            ),
            SizedBox(height: isVeryCompact ? 12 : (isCompact ? 16 : 24)),
            Text(
              'Erreur lors du chargement',
              style: TextStyle(
                fontSize: isVeryCompact ? 16 : (isCompact ? 18 : 20),
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: isVeryCompact ? 6 : (isCompact ? 8 : 12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 12 : 24),
              child: Text(
                'Veuillez réessayer plus tard',
                style: TextStyle(
                  fontSize: isVeryCompact ? 12 : (isCompact ? 14 : 16),
                  color: _subtleColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isVeryCompact ? 18 : (isCompact ? 24 : 32)),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryCompact ? 20 : (isCompact ? 24 : 32),
                  vertical: isVeryCompact ? 10 : (isCompact ? 12 : 16),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCompact ? 8 : 12)),
              ),
              child: Text(
                'Réessayer',
                style: TextStyle(
                  fontSize: isVeryCompact ? 12 : (isCompact ? 14 : 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(String productId, int quantity) async {
    try {
      await CartService.updateQuantity(productId, quantity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeItem(CartItem item) async {
    try {
      await CartService.removeFromCart(item.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} supprimé du panier'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir vider votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await CartService.clearCart();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Panier vidé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(List<CartItem> items, double totalPrice) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier que tous les articles viennent du même vendeur
    final firstSellerId = items.first.sellerId;
    if (items.any((item) => item.sellerId != firstSellerId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commander plusieurs vendeurs simultanément n\'est pas supporté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Créer l'objet Vendor à partir du premier article
    final vendor = Vendor.fromCartItem(items.first);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: items,
          totalPrice: totalPrice,
          vendor: vendor,
        ),
      ),
    );
  }
}

// Service fictif - À remplacer par votre implémentation réelle
class CartService {
  static Stream<List<CartItem>> getCartItems() {
    return Stream.value([]);
  }

  static Future<void> updateQuantity(String productId, int quantity) async {}
  static Future<void> removeFromCart(String productId) async {}
  static Future<void> clearCart() async {}
}
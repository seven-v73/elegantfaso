import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'tabs/accueil_tab.dart';
import 'tabs/boutique_tab.dart';
import 'tabs/createurs_tab.dart';
import 'tabs/inspiration_tab.dart';
import 'tabs/agenda_tab.dart';

// ====================== CART ITEM MODEL ======================
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;
  final String sellerId;
  final String sellerName;
  final String sellerImage;
  final Map<String, dynamic> metadata;
  final Timestamp addedAt;

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
    required this.addedAt,
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
      'addedAt': addedAt,
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
      addedAt: map['addedAt'] ?? Timestamp.now(),
    );
  }
}

// ====================== CART SERVICE ======================
class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static Stream<List<CartItem>> getCartStream() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CartItem.fromMap(doc.id, doc.data()))
        .toList());
  }

  static Future<void> addToCart(CartItem item) async {
    if (_userId == null) return;

    // Check if item already exists in cart
    final existingItem = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .where('productId', isEqualTo: item.productId)
        .where('sellerId', isEqualTo: item.sellerId)
        .limit(1)
        .get();

    if (existingItem.docs.isNotEmpty) {
      // Update quantity if item exists
      final doc = existingItem.docs.first;
      final currentQuantity = doc['quantity'] ?? 1;
      await doc.reference.update({'quantity': currentQuantity + item.quantity});
    } else {
      // Add new item
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .add(item.toMap());
    }
  }

  static Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;

    if (quantity <= 0) {
      await removeFromCart(itemId);
    } else {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': quantity});
    }
  }

  static Future<void> removeFromCart(String itemId) async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(itemId)
        .delete();
  }

  static Future<void> clearCart() async {
    if (_userId == null) return;

    final batch = _firestore.batch();
    final cartRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart');

    final cartItems = await cartRef.get();
    for (final doc in cartItems.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  static double calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (total, item) => total + (item.price * item.quantity));
  }

  static int getTotalItemCount(List<CartItem> items) {
    return items.fold(0, (total, item) => total + item.quantity);
  }
}

// ====================== VENDOR MODEL ======================
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

// ====================== CHECKOUT SCREENS ======================
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

      // Simulate backend processing
      await Future.delayed(const Duration(seconds: 2));

      // Clear cart after successful payment
      await CartService.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Commande envoyée! En attente de validation'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Redirect to home after payment
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

// ====================== MAIN SCREEN ======================
class SalonModeBurkinabeScreen extends StatefulWidget {
  const SalonModeBurkinabeScreen({super.key});

  @override
  State<SalonModeBurkinabeScreen> createState() => _SalonModeBurkinabeScreenState();
}

class _SalonModeBurkinabeScreenState extends State<SalonModeBurkinabeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final Color _primaryColor = const Color(0xFF2C1810);
  final Color _accentColor = const Color(0xFFD4AF37);
  final Color _lightBgColor = const Color(0xFFFBF9F6);
  final Color _surfaceColor = Colors.white;
  final Color _textColor = const Color(0xFF1A1A1A);
  final Color _subtleColor = const Color(0xFF8B7355);

  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _tabAnimationController;
  late AnimationController _cartBadgeAnimationController;

  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _tabSlideAnimation;
  late Animation<double> _cartBadgeScaleAnimation;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cartBadgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _tabSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tabAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cartBadgeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _cartBadgeAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _fabAnimationController.forward().then((_) {
          _fabAnimationController.reverse();
        });
      }
    });

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _tabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _tabAnimationController.dispose();
    _cartBadgeAnimationController.dispose();
    super.dispose();
  }

  void _showCartScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const CartScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBgColor,
      body: SafeArea(
        child: Column(
          children: [
            SlideTransition(
              position: _headerSlideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1000),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.design_services,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: FadeTransition(
                        opacity: _headerAnimationController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MODE BURKINABÈ',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: _primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'L\'élégance africaine authentique',
                              style: TextStyle(
                                fontSize: 12,
                                color: _subtleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    StreamBuilder<List<CartItem>>(
                      stream: CartService.getCartStream(),
                      builder: (context, snapshot) {
                        final cartItems = snapshot.data ?? [];
                        final itemCount = CartService.getTotalItemCount(cartItems);

                        if (snapshot.hasData && itemCount > 0) {
                          _cartBadgeAnimationController.forward().then((_) {
                            _cartBadgeAnimationController.reverse();
                          });
                        }

                        return _buildAnimatedCartButton(
                          itemCount: itemCount,
                          delay: 200,
                          onPressed: _showCartScreen,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SlideTransition(
              position: _tabSlideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: _subtleColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: _primaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: _primaryColor,
                  unselectedLabelColor: _subtleColor,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: [
                    _buildAnimatedTab('Accueil', Icons.home_outlined, 0),
                    _buildAnimatedTab('Boutique', Icons.store_outlined, 1),
                    _buildAnimatedTab('Créateurs', Icons.palette_outlined, 2),
                    _buildAnimatedTab('Inspiration', Icons.lightbulb_outline, 3),
                    _buildAnimatedTab('Agenda', Icons.event_outlined, 4),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AccueilTab(),
                  BoutiqueTab(),
                  CreateursTab(),
                  InspirationTab(),
                  AgendaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCartButton({
    required int itemCount,
    required int delay,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  color: _primaryColor,
                  iconSize: 24,
                  onPressed: onPressed,
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: ScaleTransition(
                    scale: _cartBadgeScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : itemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTab(String text, IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: _currentTabIndex == index ? _primaryColor : _subtleColor,
                  ),
                  const SizedBox(width: 6),
                  Text(text),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ====================== CART SCREEN ======================
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
            stream: CartService.getCartStream(),
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
        stream: CartService.getCartStream(),
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
                    final item = cartItems[index];
                    // Extraction des métadonnées
                    final size = item.metadata['size'] ?? '';
                    final color = item.metadata['color'] ?? '';

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCartItemCard(
                        item,
                        size,
                        color,
                        isCompact,
                        imageSize,
                        screenWidth,
                        key: ValueKey(item.id),
                      ),
                    );
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

  Widget _buildCartItemCard(
      CartItem item,
      String size,
      String color,
      bool isCompact,
      double imageSize,
      double screenWidth, {
        Key? key,
      }) {
    return Card(
      key: key,
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'cart-image-${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: _subtleColor.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: _subtleColor.withOpacity(0.1),
                    child: Icon(
                      Icons.image_not_supported,
                      color: _subtleColor,
                    ),
                  ),
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
                            fontSize: isCompact ? 14 : 16,
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
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 4 : 6),

                  Text(
                    'Par ${item.sellerName}',
                    style: TextStyle(
                      color: _subtleColor,
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (size.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Taille: $size',
                            style: TextStyle(
                              fontSize: 12,
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (color.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            color,
                            style: TextStyle(
                              fontSize: 12,
                              color: _accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 8 : 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuantityControls(item, isCompact),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                          size: isCompact ? 20 : 24,
                          color: Colors.red[400],
                        ),
                        onPressed: () => _removeItem(item),
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

  Widget _buildQuantityControls(CartItem item, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: _lightBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _subtleColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: isCompact ? 16 : 18),
            onPressed: item.quantity > 1
                ? () => _updateQuantity(item.id, item.quantity - 1)
                : null,
            padding: EdgeInsets.all(isCompact ? 4 : 6),
            color: item.quantity > 1 ? _primaryColor : _subtleColor.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 14 : 16,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: isCompact ? 16 : 18),
            onPressed: () => _updateQuantity(item.id, item.quantity + 1),
            padding: EdgeInsets.all(isCompact ? 4 : 6),
            color: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(List<CartItem> items, bool isCompact) {
    final totalItems = CartService.getTotalItemCount(items);
    final totalPrice = CartService.calculateTotal(items);

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                ),
                elevation: 2,
                shadowColor: _primaryColor.withOpacity(0.3),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                ),
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

  void _updateQuantity(String itemId, int quantity) async {
    try {
      await CartService.updateQuantity(itemId, quantity);
      HapticFeedback.lightImpact();
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
      await CartService.removeFromCart(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} supprimé du panier'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      HapticFeedback.mediumImpact();
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
                HapticFeedback.heavyImpact();
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

    final vendor = Vendor.fromCartItem(items.first);

    // Redirection vers l'écran de paiement
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// ====================== MODÈLES ======================
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

// ====================== SERVICES ======================
class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<List<CartItem>> getCartItems() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CartItem.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  static Future<void> updateQuantity(String cartItemId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(cartItemId)
        .update({'quantity': quantity});
  }

  static Future<void> removeFromCart(String cartItemId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(cartItemId)
        .delete();
  }

  static Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final items = await _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .get();

    for (final doc in items.docs) {
      await doc.reference.delete();
    }
  }

  static bool canPurchaseProduct(String sellerId) {
    final user = _auth.currentUser;
    return user != null && user.uid != sellerId;
  }

  static Future<void> addToCart({
    required String productId,
    required String name,
    required String imageUrl,
    required double price,
    required String type,
    required String sellerId,
    required String sellerName,
    required String sellerImage,
    required Map<String, dynamic> metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    if (user.uid == sellerId) throw Exception('Cannot purchase your own item');

    final cartRef = _firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .where('productId', isEqualTo: productId)
        .where('sellerId', isEqualTo: sellerId);

    final query = await cartRef.get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final currentQuantity = doc['quantity'] ?? 1;
      await doc.reference.update({'quantity': currentQuantity + 1});
    } else {
      await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .add({
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': 1,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerImage': sellerImage,
        'metadata': {
          ...metadata,
          'type': type,
          'role': type == 'product' ? 'boutique' : 'createur',
        },
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<bool> validateCartItem(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(itemId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  static Future<void> createOrder({
    required List<CartItem> items,
    required Vendor vendor,
    required String paymentMethod,
    required String proofUrl,
    required String buyerPhone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final orderRef = _firestore.collection('orders').doc();

    final orderData = {
      'id': orderRef.id,
      'buyerId': user.uid,
      'vendorId': vendor.id,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)),
      'paymentMethod': paymentMethod,
      'proofUrl': proofUrl,
      'buyerPhone': buyerPhone,
      'vendorPhone': vendor.phone,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await orderRef.set(orderData);
  }
}

// ====================== ÉCRANS DE COMMANDE ======================
class CheckoutScreen extends StatefulWidget {
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
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isValidating = true;
  bool _validationSuccess = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _validateCartItems();
  }

  Future<void> _validateCartItems() async {
    try {
      for (final item in widget.cartItems) {
        final isValid = await CartService.validateCartItem(item.id);
        if (!isValid) {
          setState(() {
            _isValidating = false;
            _validationSuccess = false;
            _validationError = 'Certains articles ne sont plus disponibles';
          });
          return;
        }
      }
      setState(() {
        _isValidating = false;
        _validationSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationSuccess = false;
        _validationError = 'Erreur de validation: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Validation du panier...'),
            ],
          ),
        ),
      );
    }

    if (!_validationSuccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Problème de validation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                const SizedBox(height: 20),
                Text(
                  _validationError ?? 'Articles non disponibles',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Certains articles de votre panier ne sont plus disponibles. Veuillez vérifier votre panier.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C1810),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Retour au panier'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _CheckoutContent(
      cartItems: widget.cartItems,
      totalPrice: widget.totalPrice,
      vendor: widget.vendor,
    );
  }
}

class _CheckoutContent extends StatelessWidget {
  final List<CartItem> cartItems;
  final double totalPrice;
  final Vendor vendor;

  const _CheckoutContent({
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

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_proofs/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _proofImage != null) {
      setState(() => _isSubmitting = true);

      // Upload proof image
      final proofUrl = await _uploadImage(_proofImage!);
      if (proofUrl == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Échec du téléchargement de la preuve. Veuillez réessayer.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      try {
        // Create order
        await CartService.createOrder(
          items: widget.cartItems,
          vendor: widget.vendor,
          paymentMethod: _selectedPaymentMethod!,
          proofUrl: proofUrl,
          buyerPhone: _phoneController.text,
        );

        // Clear cart items
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          for (final item in widget.cartItems) {
            await FirebaseFirestore.instance
                .collection('carts')
                .doc(user.uid)
                .collection('items')
                .doc(item.id)
                .delete();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Commande envoyée! En attente de validation'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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

// ====================== ÉCRAN DU PANIER ======================
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
                ? () => _updateQuantity(item.id, item.quantity - 1)
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
            onPressed: () => _updateQuantity(item.id, item.quantity + 1),
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

  void _updateQuantity(String cartItemId, int quantity) async {
    try {
      await CartService.updateQuantity(cartItemId, quantity);
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

    // Gestion multi-vendeurs
    final groupedItems = _groupItemsByVendor(items);

    // Vérification cruciale pour éviter "No element"
    if (groupedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun article valide dans le panier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (groupedItems.length == 1) {
      final vendorItems = groupedItems.values.first;

      // Vérification cruciale pour éviter "No element"
      if (vendorItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Aucun article trouvé pour ce vendeur'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final vendor = Vendor.fromCartItem(vendorItems.first);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            cartItems: vendorItems,
            totalPrice: _calculateTotalPrice(vendorItems),
            vendor: vendor,
          ),
        ),
      );
    } else {
      _showVendorSelectionDialog(context, groupedItems);
    }
  }

  Map<String, List<CartItem>> _groupItemsByVendor(List<CartItem> items) {
    final Map<String, List<CartItem>> groupedItems = {};
    for (final item in items) {
      // Ignorer les articles avec sellerId vide
      if (item.sellerId.isNotEmpty) {
        groupedItems.putIfAbsent(item.sellerId, () => []).add(item);
      }
    }
    return groupedItems;
  }

  double _calculateTotalPrice(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _showVendorSelectionDialog(
      BuildContext context, Map<String, List<CartItem>> groupedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionnez un vendeur'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: groupedItems.entries.map((entry) {
              final vendorItems = entry.value;

              // Vérification de sécurité
              if (vendorItems.isEmpty) return const SizedBox.shrink();

              final vendor = Vendor.fromCartItem(vendorItems.first);
              final total = _calculateTotalPrice(vendorItems);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12
                  ),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(vendor.photoUrl),
                  ),
                  title: Text(
                    vendor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${vendorItems.length} article(s) - ${_priceFormatter.format(total)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(
                          cartItems: vendorItems,
                          totalPrice: total,
                          vendor: vendor,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

// ====================== PRODUITS RECOMMANDÉS ======================
class RecommendedProducts extends StatefulWidget {
  const RecommendedProducts({super.key});

  @override
  State<RecommendedProducts> createState() => _RecommendedProductsState();
}

class _RecommendedProductsState extends State<RecommendedProducts>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }

  double _getChildAspectRatio(double width) {
    if (width < 600) return 0.7;
    if (width < 900) return 0.75;
    return 0.8;
  }

  double _getFontSize(double width, double baseSize) {
    if (width < 600) return baseSize * 0.9;
    if (width < 900) return baseSize;
    return baseSize * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(screenWidth),
          SizedBox(height: screenWidth < 600 ? 12 : 16),
          _buildProductGrid(screenWidth),
        ],
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    final isCompact = screenWidth < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recommandés pour vous',
                  style: TextStyle(
                    fontSize: _getFontSize(screenWidth, 20),
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              if (isCompact)
                _buildCartButton(screenWidth)
              else
                Row(
                  children: [
                    _buildCartButton(screenWidth),
                    const SizedBox(width: 8),
                    _buildSeeAllButton(screenWidth),
                  ],
                ),
            ],
          ),
          if (isCompact) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildSeeAllButton(screenWidth),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildCartButton(double screenWidth) {
    return StreamBuilder<List<CartItem>>(
      stream: CartService.getCartItems(),
      builder: (context, snapshot) {
        final itemCount = snapshot.data?.length ?? 0;
        final buttonSize = screenWidth < 600 ? 20.0 : 24.0;

        return Stack(
          children: [
            IconButton(
              iconSize: buttonSize,
              padding: EdgeInsets.all(screenWidth < 600 ? 8 : 12),
              constraints: BoxConstraints(
                minWidth: screenWidth < 600 ? 36 : 48,
                minHeight: screenWidth < 600 ? 36 : 48,
              ),
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: _primaryColor,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              ),
            ),
            if (itemCount > 0)
              Positioned(
                right: screenWidth < 600 ? 2 : 4,
                top: screenWidth < 600 ? 2 : 4,
                child: Container(
                  padding: EdgeInsets.all(screenWidth < 600 ? 1 : 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(
                    minWidth: screenWidth < 600 ? 14 : 16,
                    minHeight: screenWidth < 600 ? 14 : 16,
                  ),
                  child: Text(
                    '$itemCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth < 600 ? 8 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSeeAllButton(double screenWidth) {
    return TextButton(
      onPressed: _navigateToAllProducts,
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        backgroundColor: _primaryColor.withOpacity(0.1),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 10 : 12,
          vertical: screenWidth < 600 ? 4 : 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        'Voir tout',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: _getFontSize(screenWidth, 14),
        ),
      ),
    );
  }

  Widget _buildProductGrid(double screenWidth) {
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final childAspectRatio = _getChildAspectRatio(screenWidth);
    final spacing = screenWidth < 600 ? 8.0 : 12.0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .snapshots(),
      builder: (context, productsSnapshot) {
        if (productsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingGrid(crossAxisCount, childAspectRatio, spacing);
        }

        if (productsSnapshot.hasError) {
          return _buildErrorWidget(screenWidth);
        }

        final products = productsSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('creations')
              .orderBy('createdAt', descending: true)
              .limit(4)
              .snapshots(),
          builder: (context, creationsSnapshot) {
            if (creationsSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid(crossAxisCount, childAspectRatio, spacing);
            }

            if (creationsSnapshot.hasError) {
              return _buildErrorWidget(screenWidth);
            }

            final creations = creationsSnapshot.data?.docs ?? [];
            final allItems = [...products, ...creations]..shuffle();

            if (allItems.isEmpty) {
              return _buildEmptyWidget(screenWidth);
            }

            return SlideTransition(
              position: _slideAnimation,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: allItems.length > 6 ? 6 : allItems.length,
                itemBuilder: (context, index) {
                  final item = allItems[index];
                  final itemData = item.data() as Map<String, dynamic>;

                  return AnimatedBuilder(
                    animation: _fadeController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: _fadeController,
                          curve: Interval(
                            index * 0.1,
                            1.0,
                            curve: Curves.easeInOut,
                          ),
                        )),
                        child: item.reference.path.contains('products')
                            ? _buildProductCard(itemData, item.id, screenWidth)
                            : _buildCreationCard(itemData, item.id, screenWidth),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> productData, String productId, double screenWidth) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('boutiques')
          .doc(productData['boutiqueId'])
          .get(),
      builder: (context, boutiqueSnapshot) {
        String boutiqueName = 'Boutique';
        String boutiqueImage = '';

        if (boutiqueSnapshot.hasData && boutiqueSnapshot.data!.exists) {
          final boutiqueData = boutiqueSnapshot.data!.data() as Map<String, dynamic>?;
          boutiqueName = boutiqueData?['name'] ?? 'Boutique inconnue';
          boutiqueImage = boutiqueData?['imageUrl'] ?? '';
        }

        return _buildItemCard(
          id: productId,
          name: productData['name'] ?? 'Produit sans nom',
          imageUrl: productData['imageUrl'] ?? '',
          price: (productData['price'] ?? 0).toDouble(),
          sellerName: boutiqueName,
          sellerImage: boutiqueImage,
          sellerId: productData['boutiqueId'] ?? '',
          type: 'product',
          badge: 'Boutique',
          badgeColor: Colors.orange,
          metadata: productData,
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _buildCreationCard(Map<String, dynamic> creationData, String creationId, double screenWidth) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(creationData['createurId'])
          .get(),
      builder: (context, userSnapshot) {
        String creatorName = 'Créateur';
        String creatorImage = '';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          creatorName = userData?['displayName'] ??
              userData?['name'] ??
              'Créateur inconnu';
          creatorImage = userData?['photoUrl'] ??
              userData?['photolr1'] ??
              '';
        }

        String imageUrl = '';
        if (creationData['images'] != null && creationData['images'] is List) {
          final images = List<String>.from(creationData['images']);
          if (images.isNotEmpty) {
            imageUrl = images.first;
          }
        }

        return _buildItemCard(
          id: creationId,
          name: creationData['title'] ?? 'Création sans titre',
          imageUrl: imageUrl,
          price: (creationData['price'] ?? 0).toDouble(),
          sellerName: creatorName,
          sellerImage: creatorImage,
          sellerId: creationData['createurId'] ?? '',
          type: 'creation',
          badge: 'Créateur',
          badgeColor: Colors.blue,
          metadata: creationData,
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _buildItemCard({
    required String id,
    required String name,
    required String imageUrl,
    required double price,
    required String sellerName,
    required String sellerImage,
    required String sellerId,
    required String type,
    required String badge,
    required Color badgeColor,
    required Map<String, dynamic> metadata,
    required double screenWidth,
  }) {
    final isCompact = screenWidth < 600;
    final borderRadius = isCompact ? 12.0 : 16.0;
    final badgeSize = isCompact ? 8.0 : 10.0;
    final avatarRadius = isCompact ? 6.0 : 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: isCompact ? 8 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: constraints.maxHeight * 0.6,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: isCompact ? 30 : 40,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: isCompact ? 4 : 8,
                      right: isCompact ? 4 : 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 8,
                          vertical: isCompact ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: badgeSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _getFontSize(screenWidth, 14),
                            color: _textColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: isCompact ? 2 : 4),

                      Row(
                        children: [
                          if (sellerImage.isNotEmpty) ...[
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(sellerImage),
                              radius: avatarRadius,
                            ),
                            SizedBox(width: isCompact ? 4 : 6),
                          ],
                          Expanded(
                            child: Text(
                              sellerName,
                              style: TextStyle(
                                color: _subtleColor,
                                fontSize: _getFontSize(screenWidth, 11),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isCompact ? 2 : 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _priceFormatter.format(price),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: _getFontSize(screenWidth, 13),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: isCompact ? 4 : 8),
                          AddToCartButton(
                            productId: id,
                            name: name,
                            imageUrl: imageUrl,
                            price: price,
                            type: type,
                            sellerId: sellerId,
                            sellerName: sellerName,
                            sellerImage: sellerImage,
                            metadata: metadata,
                            isCompact: isCompact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid(int crossAxisCount, double childAspectRatio, double spacing) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: screenWidth < 600 ? 40 : 48,
            color: Colors.red[400],
          ),
          SizedBox(height: screenWidth < 600 ? 8 : 12),
          Text(
            'Erreur lors du chargement',
            style: TextStyle(
              fontSize: _getFontSize(screenWidth, 16),
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          SizedBox(height: screenWidth < 600 ? 4 : 8),
          Text(
            'Veuillez réessayer plus tard',
            style: TextStyle(
              color: _subtleColor,
              fontSize: _getFontSize(screenWidth, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: screenWidth < 600 ? 40 : 48,
            color: _subtleColor,
          ),
          SizedBox(height: screenWidth < 600 ? 8 : 12),
          Text(
            'Aucun produit disponible',
            style: TextStyle(
              fontSize: _getFontSize(screenWidth, 16),
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          SizedBox(height: screenWidth < 600 ? 4 : 8),
          Text(
            'Revenez plus tard pour découvrir nos nouveautés',
            style: TextStyle(
              color: _subtleColor,
              fontSize: _getFontSize(screenWidth, 14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToAllProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation vers tous les produits'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ====================== BOUTON AJOUTER AU PANIER ======================
class AddToCartButton extends StatefulWidget {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String type;
  final String sellerId;
  final String sellerName;
  final String sellerImage;
  final Map<String, dynamic> metadata;
  final bool isCompact;

  const AddToCartButton({
    Key? key,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.type,
    required this.sellerId,
    required this.sellerName,
    required this.sellerImage,
    required this.metadata,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _isLoading = false;
  bool _canPurchase = true;

  @override
  void initState() {
    super.initState();
    _canPurchase = CartService.canPurchaseProduct(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canPurchase) {
      return Container(
        width: widget.isCompact ? 28 : 32,
        height: widget.isCompact ? 28 : 32,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
        ),
        child: Icon(
          Icons.block,
          color: Colors.white,
          size: widget.isCompact ? 14 : 16,
        ),
      );
    }

    return Container(
      width: widget.isCompact ? 28 : 32,
      height: widget.isCompact ? 28 : 32,
      decoration: BoxDecoration(
        color: _isLoading ? Colors.grey[400] : const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(widget.isCompact ? 6 : 8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: _isLoading ? null : _addToCart,
        icon: _isLoading
            ? SizedBox(
          width: widget.isCompact ? 12 : 14,
          height: widget.isCompact ? 12 : 14,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(
          Icons.add_shopping_cart,
          color: Colors.white,
          size: widget.isCompact ? 14 : 16,
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    setState(() => _isLoading = true);

    try {
      await CartService.addToCart(
        productId: widget.productId,
        name: widget.name,
        imageUrl: widget.imageUrl,
        price: widget.price,
        type: widget.type,
        sellerId: widget.sellerId,
        sellerName: widget.sellerName,
        sellerImage: widget.sellerImage,
        metadata: widget.metadata,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.name} ajouté au panier'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
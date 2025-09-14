import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../messages/chat_screen.dart';
import '../../messages/user_model.dart';

class SharedLooksScreen extends StatefulWidget {
  const SharedLooksScreen({super.key});

  @override
  State<SharedLooksScreen> createState() => _SharedLooksScreenState();
}

class _SharedLooksScreenState extends State<SharedLooksScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  List<DocumentSnapshot> _sharedLooks = [];
  final Map<String, String> _senderNames = {};
  final Map<String, String> _imageUrls = {};
  final Map<String, UserModel> _senderUserModels = {};
  String _debugInfo = '';

  late AnimationController _refreshAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserModel? _currentUserModel;

  // Metadata pour les mesures corporelles
  static const Map<String, Map<String, dynamic>> _measurementMetadata = {
    'tour_poitrine': {'label': 'Tour de poitrine', 'icon': Icons.woman, 'unit': 'cm', 'color': Colors.pink},
    'tour_taille': {'label': 'Tour de taille', 'icon': Icons.straighten, 'unit': 'cm', 'color': Colors.green},
    'tour_hanches': {'label': 'Tour de hanches', 'icon': Icons.people, 'unit': 'cm', 'color': Colors.purple},
    'tour_bras': {'label': 'Tour de bras', 'icon': Icons.accessibility, 'unit': 'cm', 'color': Colors.orange},
    'tour_cuisse': {'label': 'Tour de cuisse', 'icon': Icons.directions_run, 'unit': 'cm', 'color': Colors.indigo},
    'longueur_jambe': {'label': 'Longueur de jambe', 'icon': Icons.airline_seat_legroom_reduced, 'unit': 'cm', 'color': Colors.blue},
    'longueur_bras': {'label': 'Longueur de bras', 'icon': Icons.accessibility_new, 'unit': 'cm', 'color': Colors.teal},
    'pointure': {'label': 'Pointure', 'icon': Icons.shopping_bag, 'unit': '', 'color': Colors.brown},
    'bonnet': {'label': 'Bonnet', 'icon': Icons.woman, 'unit': '', 'color': Colors.red},
    'tour_cou': {'label': 'Tour de cou', 'icon': Icons.person, 'unit': 'cm', 'color': Colors.cyan},
    'largeur_epaules': {'label': 'Largeur épaules', 'icon': Icons.accessibility, 'unit': 'cm', 'color': Colors.deepOrange},
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentUser();
    _loadSharedLooks();
  }

  void _initializeAnimations() {
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _currentUserModel = UserModel.fromDocument(doc);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedLooks() async {
    setState(() => _isLoading = true);
    _refreshAnimationController.reset();
    _refreshAnimationController.forward();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      debugPrint("Chargement des looks pour l'utilisateur: ${user.uid}");
      _debugInfo = "UID utilisateur: ${user.uid}\n";

      final snapshot = await _firestore
          .collection('shared_outfits')
          .where('creatorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'sent')
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint("${snapshot.docs.length} looks trouvés");
      _debugInfo += "${snapshot.docs.length} documents trouvés dans 'shared_outfits'\n";

      if (snapshot.docs.isEmpty) {
        _debugInfo += "Aucun document trouvé avec les critères:\n";
        _debugInfo += "- creatorId: ${user.uid}\n";
        _debugInfo += "- status: sent\n";
      }

      List<Future> loadFutures = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String? ?? '';
        final imagePath = data['imageUrl'] as String? ?? '';
        final creatorId = data['creatorId'] as String? ?? '';

        _debugInfo += "\nDocument ID: ${doc.id}\n";
        _debugInfo += "senderId: $senderId\n";
        _debugInfo += "creatorId: $creatorId\n";
        _debugInfo += "imagePath: $imagePath\n";

        if (imagePath.isNotEmpty) {
          loadFutures.add(_getImageUrl(imagePath).then((url) {
            _imageUrls[doc.id] = url;
            debugPrint("URL image obtenue: $url");
          }).catchError((e) {
            debugPrint("Erreur chargement image: $e");
            _debugInfo += "Erreur chargement image: $e\n";
          }));
        } else {
          _debugInfo += "Chemin d'image vide\n";
        }

        if (senderId.isNotEmpty && !_senderNames.containsKey(senderId)) {
          loadFutures.add(_getSenderName(senderId).then((_) {
            return _loadSenderUserModel(senderId);
          }).catchError((e) {
            debugPrint("Erreur chargement nom: $e");
            _debugInfo += "Erreur chargement nom: $e\n";
          }));
        }
      }

      await Future.wait(loadFutures);

      setState(() {
        _sharedLooks = snapshot.docs;
        _isLoading = false;
      });

      _cardAnimationController.reset();
      _cardAnimationController.forward();

    } catch (e, stackTrace) {
      debugPrint('Erreur chargement looks partagés: $e');
      debugPrint('Stack trace: $stackTrace');
      _debugInfo += "Erreur principale: $e\n$stackTrace";
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erreur de chargement: ${e.toString()}");
    }
  }

  Future<void> _loadSenderUserModel(String senderId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(senderId).get();
      if (userDoc.exists) {
        _senderUserModels[senderId] = UserModel.fromDocument(userDoc);
      }
    } catch (e) {
      debugPrint("Erreur chargement UserModel pour $senderId: $e");
    }
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      final ref = _storage.ref().child(imagePath);
      final url = await ref.getDownloadURL();
      debugPrint("Téléchargement URL réussi: $url");
      return url;
    } catch (e) {
      debugPrint("Erreur récupération URL image: $e");
      return 'https://via.placeholder.com/300x400?text=Image+non+disponible';
    }
  }

  Future<void> _getSenderName(String senderId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(senderId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        String? name;
        if (userData.containsKey('name')) {
          name = userData['name'] as String?;
        } else if (userData.containsKey('displayName')) {
          name = userData['displayName'] as String?;
        } else if (userData.containsKey('username')) {
          name = userData['username'] as String?;
        }

        _senderNames[senderId] = name ?? 'Client';
        debugPrint("Nom trouvé pour $senderId: ${_senderNames[senderId]}");
      } else {
        final clientDoc = await _firestore.collection('clients').doc(senderId).get();
        if (clientDoc.exists) {
          final clientData = clientDoc.data() as Map<String, dynamic>;
          _senderNames[senderId] = clientData['name'] as String? ?? 'Client';
        } else {
          _senderNames[senderId] = 'Client';
        }
        debugPrint("Nom client pour $senderId: ${_senderNames[senderId]}");
      }
    } catch (e) {
      debugPrint("Erreur récupération client $senderId: $e");
      _senderNames[senderId] = 'Client';
    }
  }

  Future<void> _respondToLook(String lookId, bool accepted, double? price) async {
    try {
      await _firestore.collection('shared_outfits').doc(lookId).update({
        'status': accepted ? 'accepted' : 'rejected',
        'responseTimestamp': FieldValue.serverTimestamp(),
        if (accepted && price != null) 'price': price,
      });

      _showSuccessSnackBar(accepted ? "Look accepté avec succès!" : "Look refusé");
      await _loadSharedLooks();
    } catch (e) {
      debugPrint('Erreur réponse look: $e');
      _showErrorSnackBar("Erreur d'envoi de réponse: ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToChat(String senderId) {
    final senderUserModel = _senderUserModels[senderId];
    if (_currentUserModel != null && senderUserModel != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
            utilisateurCourant: _currentUserModel!,
            autreUtilisateur: senderUserModel,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      _showErrorSnackBar("Impossible d'ouvrir le chat pour le moment");
    }
  }

  void _showResponseDialog(DocumentSnapshot look) {
    final data = look.data() as Map<String, dynamic>;
    final senderId = data['senderId'] as String? ?? '';
    final senderName = _senderNames[senderId] ?? 'Client';

    TextEditingController priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.attach_money, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Répondre à $senderName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Proposez un prix pour ce look personnalisé',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Prix proposé (FCFA)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _respondToLook(look.id, false, null);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final price = double.tryParse(priceController.text);
                          Navigator.pop(context);
                          _respondToLook(look.id, true, price);
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementItem({
    required String key,
    required String value,
    required double width,
  }) {
    final meta = _measurementMetadata[key] ?? {
      'label': key.replaceAll('_', ' '),
      'icon': Icons.straighten,
      'unit': '',
      'color': Colors.grey
    };

    final label = meta['label'] as String;
    final icon = meta['icon'] as IconData;
    final unit = meta['unit'] as String;
    final color = meta['color'] as Color;

    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '$value${unit.isNotEmpty ? ' $unit' : ''}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsSection(Map<String, dynamic> measurements) {
    final keys = measurements.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final itemWidth = (screenWidth - 8) / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MESURES CORPORELLES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keys.map((key) {
            final value = measurements[key]?.toString() ?? '';
            return _buildMeasurementItem(
              key: key,
              value: value,
              width: itemWidth,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLookCard(DocumentSnapshot look, int index) {
    final data = look.data() as Map<String, dynamic>;
    final imageUrl = _imageUrls[look.id] ?? 'https://via.placeholder.com/300x400?text=Chargement...';
    final message = data['message'] as String? ?? 'Nouveau look partagé';
    final senderId = data['senderId'] as String? ?? '';
    final senderName = _senderNames[senderId] ?? 'Client';
    final timestamp = data['timestamp'] as Timestamp?;
    final date = timestamp != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(timestamp.toDate())
        : 'Date inconnue';

    final measurements = data['measurements'] as Map<String, dynamic>? ?? {};
    final hasMeasurements = measurements.isNotEmpty;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(bottom: 20, top: index == 0 ? 8 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header avec avatar et infos
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.shade200, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: _senderNames.containsKey(senderId)
                            ? NetworkImage("https://ui-avatars.com/api/?name=${Uri.encodeComponent(senderName)}&background=random&color=fff")
                            : null,
                        child: _senderNames.containsKey(senderId)
                            ? null
                            : Icon(Icons.person, color: Colors.blue.shade700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NOUVEAU',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image avec bordure arrondie
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 240,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade50,
                      height: 240,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chargement...',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade50,
                      height: 240,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Image non disponible',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Message
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

              // Section des mesures corporelles
              if (hasMeasurements)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildMeasurementsSection(measurements),
                ),

              // Boutons d'action avec animations
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _AnimatedActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Discuter',
                        onPressed: () => _navigateToChat(senderId),
                        color: Colors.blue,
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AnimatedActionButton(
                        icon: Icons.close,
                        label: 'Refuser',
                        onPressed: () => _respondToLook(look.id, false, null),
                        color: Colors.red,
                        backgroundColor: Colors.red.shade50,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AnimatedActionButton(
                        icon: Icons.check,
                        label: 'Accepter',
                        onPressed: () => _showResponseDialog(look),
                        color: Colors.green,
                        backgroundColor: Colors.green.shade50,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 60,
                    color: Colors.blue.shade300,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun look partagé',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Les looks que vos clients partagent avec vous apparaîtront ici. Vous pourrez les accepter ou les refuser.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            onPressed: _loadSharedLooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Looks Partagés',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimationController.value * 2.0 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSharedLooks,
                  tooltip: 'Actualiser',
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'debug') {
                _showDebugDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report, size: 20),
                    SizedBox(width: 8),
                    Text('Debug'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des looks...'),
          ],
        ),
      )
          : _sharedLooks.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadSharedLooks,
        color: Colors.blue,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _sharedLooks.length,
          itemBuilder: (context, index) {
            return _buildLookCard(_sharedLooks[index], index);
          },
        ),
      ),
    );
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations de débogage'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(_debugInfo),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _debugInfo));
              Navigator.pop(context);
              _showSuccessSnackBar('Informations copiées');
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color backgroundColor;
  final bool isPrimary;

  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.backgroundColor,
    this.isPrimary = false,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _controller.forward().then((_) {
                  _controller.reverse();
                });
                widget.onPressed();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: widget.isPrimary ? widget.color : widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isPrimary
                      ? null
                      : Border.all(color: widget.color.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.isPrimary ? Colors.white : widget.color,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isPrimary ? Colors.white : widget.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
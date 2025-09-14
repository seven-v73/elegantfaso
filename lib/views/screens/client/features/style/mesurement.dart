import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileMeasurementsPage extends StatefulWidget {
  const ProfileMeasurementsPage({Key? key}) : super(key: key);

  @override
  State<ProfileMeasurementsPage> createState() => _ProfileMeasurementsPageState();
}

class _ProfileMeasurementsPageState extends State<ProfileMeasurementsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _isLoading = false;
  List<UserModel> _creators = [];
  bool _isLoadingCreators = false;
  bool _isSharing = false;
  String _searchQuery = '';

  // Contrôleurs pour les champs de saisie
  final Map<String, TextEditingController> _controllers = {
    'tour_poitrine': TextEditingController(),
    'tour_taille': TextEditingController(),
    'tour_hanches': TextEditingController(),
    'tour_bras': TextEditingController(),
    'tour_cuisse': TextEditingController(),
    'longueur_bras': TextEditingController(),
    'longueur_jambe': TextEditingController(),
    'largeur_epaules': TextEditingController(),
    'tour_cou': TextEditingController(),
    'taille_soutien_gorge': TextEditingController(),
    'bonnet': TextEditingController(),
    'pointure': TextEditingController(),
  };

  // Guides de mesure
  final Map<String, Map<String, String>> _measurementGuides = {
    'tour_poitrine': {
      'title': 'Tour de Poitrine',
      'description': 'Mesurez horizontalement au niveau le plus fort de la poitrine',
      'tip': 'Portez un soutien-gorge bien ajusté et respirez normalement'
    },
    'tour_taille': {
      'title': 'Tour de Taille',
      'description': 'Mesurez à la partie la plus étroite de la taille',
      'tip': 'Placez le mètre ruban juste au-dessus du nombril'
    },
    'tour_hanches': {
      'title': 'Tour de Hanches',
      'description': 'Mesurez à la partie la plus large des hanches',
      'tip': 'Tenez-vous debout, pieds joints, et mesurez horizontalement'
    },
    'tour_bras': {
      'title': 'Tour de Bras',
      'description': 'Mesurez autour de la partie la plus large du bras',
      'tip': 'Bras détendu le long du corps'
    },
    'tour_cuisse': {
      'title': 'Tour de Cuisse',
      'description': 'Mesurez au point le plus large de la cuisse',
      'tip': 'Debout, poids réparti sur les deux jambes'
    },
    'longueur_bras': {
      'title': 'Longueur de Bras',
      'description': 'De l\'épaule jusqu\'au poignet',
      'tip': 'Bras légèrement fléchi, mesurez sur l\'extérieur'
    },
    'longueur_jambe': {
      'title': 'Longueur de Jambe',
      'description': 'De la taille jusqu\'à la cheville',
      'tip': 'Mesurez sur le côté, de la taille au sol'
    },
    'largeur_epaules': {
      'title': 'Largeur d\'Épaules',
      'description': 'D\'une épaule à l\'autre, par le dos',
      'tip': 'Mesurez d\'un bout d\'épaule à l\'autre'
    },
    'tour_cou': {
      'title': 'Tour de Cou',
      'description': 'Autour de la base du cou',
      'tip': 'Laissez un peu d\'espace pour le confort'
    },
    'pointure': {
      'title': 'Pointure',
      'description': 'Taille de chaussure habituelle',
      'tip': 'Indiquez votre pointure européenne'
    }
  };

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadMeasurements() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        final doc = await _firestore
            .collection('measurements')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _controllers.forEach((key, controller) {
            controller.text = data[key]?.toString() ?? '';
          });
        }
      } catch (e) {
        _showSnackBar('Erreur lors du chargement des données: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _loadCreators() async {
    if (!mounted) return;

    setState(() => _isLoadingCreators = true);

    try {
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'createur')
          .orderBy('name'); // Tri par nom

      final QuerySnapshot querySnapshot = await query.get();

      final List<UserModel> creators = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _creators = creators;
          _isLoadingCreators = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCreators = false);
        _showSnackBar('Erreur lors du chargement des créateurs: ${e.toString()}');
      }
    }
  }

  List<UserModel> get _filteredCreators {
    if (_searchQuery.isEmpty) return _creators;
    return _creators.where((creator) {
      return creator.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          creator.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          creator.speciality.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _saveMeasurements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final measurements = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          measurements[key] = controller.text.trim();
        }
      });

      measurements['updated_at'] = FieldValue.serverTimestamp();
      measurements['user_id'] = user.uid;

      await _firestore
          .collection('measurements')
          .doc(user.uid)
          .set(measurements, SetOptions(merge: true));

      setState(() => _isEditing = false);
      _showSnackBar('Mensurations sauvegardées avec succès!');
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareWithCreator(UserModel creator) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSharing = true);

    // Vérifier si l'utilisateur a des mensurations
    bool hasMeasurements = false;
    final measurements = <String, dynamic>{};

    _controllers.forEach((key, controller) {
      if (controller.text.trim().isNotEmpty) {
        measurements[key] = controller.text.trim();
        hasMeasurements = true;
      }
    });

    if (!hasMeasurements) {
      _showSnackBar('Veuillez d\'abord saisir vos mensurations');
      setState(() => _isSharing = false);
      return;
    }

    // Vérifier si un partage avec ce créateur existe déjà
    try {
      final existingShare = await _firestore
          .collection('shared_measurements')
          .where('client_id', isEqualTo: user.uid)
          .where('creator_id', isEqualTo: creator.id)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingShare.docs.isNotEmpty) {
        _showSnackBar('Un partage avec ce créateur est déjà en attente');
        setState(() => _isSharing = false);
        return;
      }

      // Créer l'ID unique pour le partage
      final shareId = _firestore.collection('shared_measurements').doc().id;
      final now = DateTime.now();

      // Préparer les données du partage
      final shareData = {
        'id': shareId,
        'client_id': user.uid,
        'client_name': user.displayName ?? 'Client',
        'client_email': user.email ?? '',
        'creator_id': creator.id,
        'creator_name': creator.name,
        'creator_email': creator.email,
        'measurements': measurements,
        'shared_at': FieldValue.serverTimestamp(),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Sauvegarder le partage
      await _firestore
          .collection('shared_measurements')
          .doc(shareId)
          .set(shareData);

      // Créer une notification pour le créateur
      final notificationData = {
        'recipient_id': creator.id,
        'sender_id': user.uid,
        'sender_name': user.displayName ?? 'Client',
        'sender_email': user.email ?? '',
        'type': 'measurement_shared',
        'title': 'Nouvelles mensurations partagées',
        'message': '${user.displayName ?? 'Un client'} a partagé ses mensurations avec vous',
        'share_id': shareId,
        'read': false,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('notifications')
          .add(notificationData);

      // Délai artificiel pour une meilleure UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Mensurations partagées avec ${creator.name} avec succès!');
      }
    } catch (e) {
      _showSnackBar('Erreur lors du partage: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showShareDialog() {
    // Réinitialiser l'état de recherche
    setState(() {
      _searchQuery = '';
      _isLoadingCreators = true;
    });

    // Charger les créateurs avant d'ouvrir le dialogue
    _loadCreators().then((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Partager avec un créateur'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    const Text('Sélectionnez un créateur avec qui partager vos mensurations:'),
                    const SizedBox(height: 16),

                    // Barre de recherche
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un créateur...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Liste des créateurs
                    Expanded(
                      child: _isLoadingCreators
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredCreators.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search,
                                size: 48,
                                color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun créateur disponible'
                                  : 'Aucun créateur trouvé',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: _filteredCreators.length,
                        itemBuilder: (context, index) {
                          final creator = _filteredCreators[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade100,
                                child: creator.profileImage != null
                                    ? ClipOval(
                                  child: Image.network(
                                    creator.profileImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Text(
                                          creator.name.isNotEmpty
                                              ? creator.name[0].toUpperCase()
                                              : 'C',
                                          style: TextStyle(
                                            color: Colors.purple.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  ),
                                )
                                    : Text(
                                  creator.name.isNotEmpty
                                      ? creator.name[0].toUpperCase()
                                      : 'C',
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                creator.name.isEmpty ? 'Créateur sans nom' : creator.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(creator.email),
                                  if (creator.speciality.isNotEmpty)
                                    Text(
                                      creator.speciality,
                                      style: TextStyle(
                                        color: Colors.blue.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: _isSharing
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              onTap: () => _shareWithCreator(creator),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                if (!_isLoadingCreators && _filteredCreators.isEmpty)
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _isLoadingCreators = true;
                      });
                      _loadCreators();
                    },
                    child: const Text('Recharger'),
                  ),
              ],
            ),
          ),
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMeasurementGuide(String key) {
    final guide = _measurementGuides[key];
    if (guide == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guide['title']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guide['description']!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guide['tip']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementField({
    required String label,
    required String key,
    String unit = 'cm',
    TextInputType inputType = TextInputType.number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showMeasurementGuide(key),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controllers[key],
          keyboardType: inputType,
          enabled: _isEditing,
          decoration: InputDecoration(
            hintText: 'Entrez $label',
            suffixText: unit.isNotEmpty ? unit : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mes Mesures'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
          if (_isEditing) ...[
            IconButton(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.close),
            ),
            IconButton(
              onPressed: _isLoading ? null : _saveMeasurements,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête du profil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.purple.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Utilisateur',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'email@example.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Client',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showShareDialog(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Partager avec un créateur'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section des mensurations
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.straighten, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      const Text(
                        'Mes Mensurations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Mensurations principales
                  _buildSectionHeader('Mensurations Principales', Colors.blue),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Tour de Poitrine',
                          key: 'tour_poitrine',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Tour de Taille',
                          key: 'tour_taille',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMeasurementField(
                    label: 'Tour de Hanches',
                    key: 'tour_hanches',
                  ),

                  const SizedBox(height: 32),

                  // Mensurations détaillées
                  _buildSectionHeader('Mensurations Détaillées', Colors.green),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Tour de Bras',
                          key: 'tour_bras',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Tour de Cuisse',
                          key: 'tour_cuisse',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Longueur de Bras',
                          key: 'longueur_bras',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Longueur de Jambe',
                          key: 'longueur_jambe',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Largeur d\'Épaules',
                          key: 'largeur_epaules',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Tour de Cou',
                          key: 'tour_cou',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Tailles spécifiques
                  _buildSectionHeader('Tailles Spécifiques', Colors.purple),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Taille Soutien-Gorge',
                          key: 'taille_soutien_gorge',
                          unit: '',
                          inputType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMeasurementField(
                          label: 'Bonnet',
                          key: 'bonnet',
                          unit: '',
                          inputType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMeasurementField(
                    label: 'Pointure',
                    key: 'pointure',
                    unit: '',
                  ),

                  const SizedBox(height: 24),

                  // Guide d'aide
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Conseils pour prendre vos mesures',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Utilisez un mètre ruban souple\n'
                              '• Portez des sous-vêtements bien ajustés\n'
                              '• Tenez-vous debout, détendu(e)\n'
                              '• Demandez de l\'aide si nécessaire\n'
                              '• Cliquez sur ℹ️ pour plus de détails',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: !_isEditing
      //     ? FloatingActionButton.extended(
      //   onPressed: () => _showShareDialog(),
      //   backgroundColor: Colors.purple.shade600,
      //   icon: const Icon(Icons.share),
      //   label: const Text('Partager'),
      // )
      //     : null,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String speciality;
  final String? profileImage;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.speciality = '',
    this.profileImage,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'client',
      speciality: data['speciality'] ?? data['specialty'] ?? '',
      profileImage: data['photoUrl'] ?? data['photoURL'],
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'speciality': speciality,
      'profileImage': profileImage,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VirtualTryOnService {
  static const String replicateApiKey = 'r8_dPwOz2x9wBRywNu2g6peetNkg3b3jLG3k0O3l';
  static const String segmindApiKey = 'SG_a507239134ece12a';

  static const List<Map<String, dynamic>> availableServices = [
    {
      'type': 'replicate',
      'name': 'Replicate IDM-VTON',
      'priority': 1,
      'model': 'yisol/idm-vton:c871bb9b046607b680449ecbae55fd8c6d945e0a1948644bf2361b3d021d3ff4',
    },
    {
      'type': 'segmind',
      'name': 'Segmind Virtual Try-On',
      'priority': 2,
      'endpoint': 'https://api.segmind.com/v1/idm-vton',
    },
  ];

  static Uint8List _cleanImageBytes(Uint8List bytes) {
    try {
      // Convertir en base64 puis revenir en bytes pour forcer un encodage propre
      final base64Str = base64Encode(bytes);
      return base64Decode(base64Str);
    } catch (e) {
      // Si l'encodage échoue, utiliser une méthode de nettoyage alternative
      return Uint8List.fromList(bytes.where((b) => b < 128).toList());
    }
  }

  static Future<Map<String, dynamic>> performVirtualTryOn({
    required File personImage,
    required File garmentImage,
    Function(String)? onStatusUpdate,
  }) async {
    if (!await personImage.exists() || !await garmentImage.exists()) {
      return {
        'success': false,
        'data': null,
        'message': 'Les fichiers images n\'existent pas'
      };
    }

    List<Map<String, dynamic>> sortedServices = List.from(availableServices);
    sortedServices.sort((a, b) => a['priority'].compareTo(b['priority']));

    onStatusUpdate?.call('🔄 Démarrage de l\'essayage virtuel...');

    for (int i = 0; i < sortedServices.length; i++) {
      Map<String, dynamic> service = sortedServices[i];
      onStatusUpdate?.call('🔄 Essai du service ${i + 1}/${sortedServices.length}: ${service['name']}');

      try {
        var result = await _tryService(service, personImage, garmentImage, onStatusUpdate);

        if (result['success']) {
          onStatusUpdate?.call('✅ Succès avec le service: ${service['name']}');
          return result;
        } else if (result['tryNext'] == true) {
          onStatusUpdate?.call('⏭️ Service ${service['name']} non disponible, passage au suivant...');
          continue;
        } else {
          onStatusUpdate?.call('❌ Erreur définitive avec ${service['name']}');
          return result;
        }
      } catch (e) {
        onStatusUpdate?.call('❌ Erreur avec le service ${service['name']}: $e');
        print('Erreur service ${service['name']}: $e');

        if (i == sortedServices.length - 1) {
          return {
            'success': false,
            'data': null,
            'message': 'Tous les services ont échoué. Dernière erreur: $e'
          };
        }
        continue;
      }
    }

    return {
      'success': false,
      'data': null,
      'message': 'Tous les services sont temporairement indisponibles. Veuillez réessayer plus tard.'
    };
  }

  static Future<Map<String, dynamic>> _tryService(
      Map<String, dynamic> service,
      File personImage,
      File garmentImage,
      Function(String)? onStatusUpdate
      ) async {

    switch (service['type']) {
      case 'replicate':
        return await _tryReplicate(service, personImage, garmentImage, onStatusUpdate);
      case 'segmind':
        return await _trySegmind(service, personImage, garmentImage, onStatusUpdate);
      default:
        return {
          'success': false,
          'data': null,
          'message': 'Service ${service['type']} non supporté',
          'tryNext': true
        };
    }
  }

  static Future<Map<String, dynamic>> _tryReplicate(
      Map<String, dynamic> service,
      File personImage,
      File garmentImage,
      Function(String)? onStatusUpdate
      ) async {
    try {
      onStatusUpdate?.call('🔄 Conversion des images en base64...');

      var personBytes = _cleanImageBytes(await personImage.readAsBytes());
      var garmentBytes = _cleanImageBytes(await garmentImage.readAsBytes());

      if (personBytes.length > 10 * 1024 * 1024 || garmentBytes.length > 10 * 1024 * 1024) {
        return {
          'success': false,
          'data': null,
          'message': 'Les images sont trop volumineuses (max 10MB)',
          'tryNext': true
        };
      }

      String personBase64 = base64Encode(personBytes);
      String garmentBase64 = base64Encode(garmentBytes);

      onStatusUpdate?.call('🚀 Analyse de la requête...');

      var response = await http.post(
        Uri.parse('https://api.replicate.com/v1/predictions'),
        headers: {
          'Authorization': 'Token $replicateApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version': service['model'].split(':')[1],
          'input': {
            'human_img': 'data:image/jpeg;base64,$personBase64',
            'garm_img': 'data:image/jpeg;base64,$garmentBase64',
            'garment_des': 'A garment',
            'is_checked': true,
            'is_checked_crop': false,
            'denoise_steps': 20,
            'seed': 42
          }
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 201) {
        var predictionData = jsonDecode(response.body);
        String predictionId = predictionData['id'];

        onStatusUpdate?.call('⏳ Traitement en cours...');
        return await _waitForReplicateResult(predictionId, onStatusUpdate);
      }

      return _handleApiError('Replicate', response);

    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Erreur Replicate: $e',
        'tryNext': true
      };
    }
  }

  static Future<Map<String, dynamic>> _waitForReplicateResult(
      String predictionId,
      Function(String)? onStatusUpdate
      ) async {
    int maxAttempts = 30;
    int attempts = 0;

    while (attempts < maxAttempts) {
      await Future.delayed(Duration(seconds: 3));
      onStatusUpdate?.call('⏳ Vérification du statut... (${attempts + 1}/$maxAttempts)');

      try {
        var response = await http.get(
          Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
          headers: {
            'Authorization': 'Token $replicateApiKey',
          },
        ).timeout(Duration(seconds: 15));

        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          String status = data['status'];

          if (status == 'succeeded') {
            onStatusUpdate?.call('📥 Téléchargement du résultat...');
            var output = data['output'];
            String imageUrl = output is List ? output[0] : output;

            var imageResponse = await http.get(Uri.parse(imageUrl));
            if (imageResponse.statusCode == 200) {
              return {
                'success': true,
                'data': imageResponse.bodyBytes,
                'message': 'Essayage virtuel réussi!'
              };
            }
          } else if (status == 'failed') {
            return {
              'success': false,
              'data': null,
              'message': 'Échec du traitement: ${data['error'] ?? 'Erreur inconnue'}',
              'tryNext': true
            };
          }
        }
      } catch (e) {
        print('Erreur lors de la vérification: $e');
      }

      attempts++;
    }

    return {
      'success': false,
      'data': null,
      'message': 'Timeout - traitement trop long',
      'tryNext': true
    };
  }

  static Future<Map<String, dynamic>> _trySegmind(
      Map<String, dynamic> service,
      File personImage,
      File garmentImage,
      Function(String)? onStatusUpdate
      ) async {
    try {
      onStatusUpdate?.call('🔄 Traitement avec Segmind...');

      var personBytes = _cleanImageBytes(await personImage.readAsBytes());
      var garmentBytes = _cleanImageBytes(await garmentImage.readAsBytes());

      String personBase64 = base64Encode(personBytes);
      String garmentBase64 = base64Encode(garmentBytes);

      var response = await http.post(
        Uri.parse(service['endpoint']),
        headers: {
          'x-api-key': segmindApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'human_img': 'data:image/jpeg;base64,$personBase64',
          'garm_img': 'data:image/jpeg;base64,$garmentBase64',
          'garment_des': 'A garment to try on',
          'is_checked': true,
          'is_checked_crop': false,
          'denoise_steps': 20,
          'seed': 42
        }),
      ).timeout(Duration(seconds: 60));

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String imageUrl = jsonResponse['image'];

        onStatusUpdate?.call('📥 Téléchargement du résultat...');
        var imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          return {
            'success': true,
            'data': imageResponse.bodyBytes,
            'message': 'Essayage virtuel réussi avec Segmind!'
          };
        }
      }

      return _handleApiError('Segmind', response);

    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Erreur Segmind: $e',
        'tryNext': true
      };
    }
  }

  static Map<String, dynamic> _handleApiError(String serviceName, http.Response response) {
    if (response.statusCode == 401) {
      return {
        'success': false,
        'data': null,
        'message': 'Clé API invalide pour $serviceName',
        'tryNext': false
      };
    } else if (response.statusCode == 402) {
      return {
        'success': false,
        'data': null,
        'message': 'Crédit insuffisant pour $serviceName',
        'tryNext': true
      };
    } else if (response.statusCode == 429) {
      return {
        'success': false,
        'data': null,
        'message': 'Limite de requêtes dépassée pour $serviceName',
        'tryNext': true
      };
    } else if (response.statusCode >= 500) {
      return {
        'success': false,
        'data': null,
        'message': 'Erreur serveur $serviceName',
        'tryNext': true
      };
    } else {
      return {
        'success': false,
        'data': null,
        'message': 'Erreur $serviceName: ${response.statusCode}',
        'tryNext': true
      };
    }
  }
}

class VirtualTryOnScreen extends StatefulWidget {
  final String? initialImagePath;

  const VirtualTryOnScreen({Key? key, this.initialImagePath}) : super(key: key);

  @override
  _VirtualTryOnScreenState createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  File? personImage;
  String? garmentImageUrl;
  Uint8List? resultImage;
  bool isProcessing = false;
  String statusMessage = '';
  final ImagePicker _picker = ImagePicker();
  bool isCancelled = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> creations = [];
  bool isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadProducts();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _loadProducts() async {
    try {
      // Charger les produits
      final productsSnapshot = await _firestore.collection('products').get();
      products = productsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'imageUrl': data['imageUrl'],
          'name': data['name'] ?? 'Produit sans nom',
          'category': data['category'] ?? '',
        };
      }).toList();

      // Charger les créations
      final creationsSnapshot = await _firestore.collection('creations').get();
      creations = creationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'imageUrl': (data['images'] is List && (data['images'] as List).isNotEmpty)
              ? (data['images'] as List)[0]
              : '',
          'name': data['description'] ?? 'Création sans nom',
        };
      }).toList();

      setState(() {
        isLoadingProducts = false;
      });
    } catch (e) {
      print('Erreur chargement produits: $e');
      setState(() {
        isLoadingProducts = false;
      });
      _showSnackBar('Erreur de chargement des produits', Colors.red);
    }
  }

  Future<void> _pickPersonImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        personImage = File(image.path);
      });
    }
  }

  Future<void> _performTryOn() async {
    if (personImage == null || garmentImageUrl == null) {
      _showSnackBar('Veuillez sélectionner les deux images', Colors.orange);
      return;
    }

    setState(() {
      isProcessing = true;
      isCancelled = false;
      statusMessage = 'Préparation...';
      resultImage = null;
    });

    try {
      // Télécharger l'image du vêtement depuis l'URL
      final response = await http.get(Uri.parse(garmentImageUrl!));
      if (response.statusCode != 200) {
        throw Exception('Échec du téléchargement du vêtement');
      }

      // Nettoyer les bytes de l'image
      final garmentBytes = VirtualTryOnService._cleanImageBytes(response.bodyBytes);

      final tempDir = await Directory.systemTemp.createTemp();
      final garmentFile = File('${tempDir.path}/garment.jpg');
      await garmentFile.writeAsBytes(garmentBytes);

      var result = await VirtualTryOnService.performVirtualTryOn(
        personImage: personImage!,
        garmentImage: garmentFile,
        onStatusUpdate: (status) {
          if (mounted && !isCancelled) {
            setState(() {
              statusMessage = status;
            });
          }
        },
      );

      if (mounted) {
        if (isCancelled) {
          setState(() {
            isProcessing = false;
            statusMessage = 'Traitement annulé';
          });
          return;
        }

        setState(() {
          isProcessing = false;
          if (result['success']) {
            resultImage = result['data'];
            statusMessage = result['message'];
          } else {
            statusMessage = result['message'];
          }
        });

        if (!result['success']) {
          _showSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          statusMessage = 'Erreur: ${e.toString().split('\n').first}';
        });
        _showSnackBar('Erreur lors du traitement: ${e.toString().split('\n').first}', Colors.red);
      }
    }
  }

  void _cancelProcessing() {
    setState(() {
      isCancelled = true;
      isProcessing = false;
      statusMessage = 'Annulation en cours...';
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required File? image,
    String? imageUrl,
    required VoidCallback onTap,
    required IconData icon,
    required Color buttonColor,
    required IconData placeholderIcon,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: image != null
                      ? Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    cacheWidth: 800,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(),
                  )
                      : (imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => _buildImageErrorWidget(),
                  )
                      : Container(
                    color: Colors.grey[50],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placeholderIcon,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Touchez pour sélectionner',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(
                image != null || imageUrl != null ? 'Changer' : 'Sélectionner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red),
            SizedBox(height: 8),
            Text('Erreur d\'image', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildTryOnButton() {
    if (isProcessing) {
      return Container(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _cancelProcessing,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isProcessing ? 0 : 8,
            shadowColor: Colors.red.withOpacity(0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, size: 24),
              SizedBox(width: 12),
              Text(
                'Annuler le traitement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _performTryOn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6B46C1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Color(0xFF6B46C1).withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_fix_high, size: 24),
            SizedBox(width: 12),
            Text(
              'Essayer le vêtement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (statusMessage.isEmpty) return SizedBox.shrink();

    IconData statusIcon = Icons.info;
    Color iconColor = Colors.blue;

    if (statusMessage.contains('❌')) {
      statusIcon = Icons.error;
      iconColor = Colors.red;
    } else if (statusMessage.contains('✅')) {
      statusIcon = Icons.check_circle;
      iconColor = Colors.green;
    } else if (statusMessage.contains('⏳')) {
      statusIcon = Icons.timer;
    } else if (statusMessage.contains('🔄')) {
      statusIcon = Icons.autorenew;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
        ),
        child: Row(
          children: [
            Icon(statusIcon, size: 24, color: iconColor),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                statusMessage.replaceAll(RegExp(r'[🔄❌✅⏭️📥⏳]'), ''),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (resultImage == null) return SizedBox.shrink();

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Essayage réussi!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 2/3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  resultImage!,
                  fit: BoxFit.cover,
                  cacheWidth: 800,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(),
                ),
              ),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _performTryOn,
                  icon: Icon(Icons.refresh),
                  label: Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSnackBar('Image sauvegardée!', Colors.green),
                  icon: Icon(Icons.download),
                  label: Text('Télécharger'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSnackBar('Partage activé!', Colors.blue),
                  icon: Icon(Icons.share),
                  label: Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sélectionnez un vêtement'),
          bottom: TabBar(
            labelColor: Color(0xFF6B46C1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF6B46C1),
            tabs: [
              Tab(text: 'Produits'),
              Tab(text: 'Créations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductGrid(products),
            _buildProductGrid(creations),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> items) {
    if (isLoadingProducts) {
      return Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          'Aucun élément disponible',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty) {
              Navigator.pop(context, item['imageUrl']);
            } else {
              _showSnackBar('Image non disponible', Colors.orange);
            }
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: item['imageUrl'],
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => _buildImageErrorWidget(),
                    )
                        : _buildImageErrorWidget(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    item['name'] ?? 'Sans nom',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item['category'] != null)
                  Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Text(
                      item['category'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Essayage Virtuel',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo de la personne
            _buildImageCard(
              title: 'Photo de la personne',
              image: personImage,
              imageUrl: null,
              onTap: _pickPersonImage,
              icon: Icons.photo_library,
              buttonColor: Colors.blue[600]!,
              placeholderIcon: Icons.person_add,
            ),

            SizedBox(height: 20),

            // Vêtement à essayer
            _buildImageCard(
              title: 'Vêtement à essayer',
              image: null,
              imageUrl: garmentImageUrl,
              onTap: () async {
                final selectedImageUrl = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _buildProductSelection(),
                  ),
                );

                if (selectedImageUrl != null) {
                  setState(() {
                    garmentImageUrl = selectedImageUrl;
                  });
                }
              },
              icon: Icons.checkroom,
              buttonColor: Colors.green[600]!,
              placeholderIcon: Icons.shopping_bag,
            ),

            SizedBox(height: 30),

            // Bouton d'essayage
            _buildTryOnButton(),

            SizedBox(height: 24),

            // Statut du traitement
            _buildStatusCard(),

            SizedBox(height: 24),

            // Résultat
            _buildResultCard(),
          ],
        ),
      ),
    );
  }
}
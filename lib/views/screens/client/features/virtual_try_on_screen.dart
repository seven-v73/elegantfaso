import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import 'package:elegantfaso/design/ecommerce_widgets.dart';
import 'package:elegantfaso/models/try_on/try_on_compatibility.dart';
import 'package:elegantfaso/models/try_on/try_on_source.dart';
import 'package:elegantfaso/services/try_on/try_on_result_service.dart';
import 'package:elegantfaso/services/try_on/try_on_source_service.dart';
import 'package:elegantfaso/services/try_on/virtual_try_on_service.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final String? initialImagePath;
  final TryOnSource? initialSource;

  const VirtualTryOnScreen({
    super.key,
    this.initialImagePath,
    this.initialSource,
  });

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _TryOnGarmentSource {
  final String? imageUrl;
  final File? file;
  final String id;
  final TryOnSourceType type;
  final String title;
  final String subtitle;
  final String ownerId;
  final Map<String, dynamic> raw;

  const _TryOnGarmentSource._({
    this.imageUrl,
    this.file,
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.ownerId = '',
    this.raw = const {},
  });

  const _TryOnGarmentSource.empty()
    : imageUrl = null,
      file = null,
      id = '',
      type = TryOnSourceType.gallery,
      title = 'Sans image',
      subtitle = '',
      ownerId = '',
      raw = const {};

  factory _TryOnGarmentSource.network(
    String imageUrl, {
    String id = '',
    TryOnSourceType type = TryOnSourceType.gallery,
    required String title,
    String subtitle = '',
    String ownerId = '',
    Map<String, dynamic> raw = const {},
  }) {
    return _TryOnGarmentSource._(
      imageUrl: imageUrl,
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      ownerId: ownerId,
      raw: raw,
    );
  }

  factory _TryOnGarmentSource.file(
    File file, {
    String id = '',
    TryOnSourceType type = TryOnSourceType.gallery,
    required String title,
    String subtitle = '',
    String ownerId = '',
    Map<String, dynamic> raw = const {},
  }) {
    return _TryOnGarmentSource._(
      file: file,
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      ownerId: ownerId,
      raw: raw,
    );
  }

  factory _TryOnGarmentSource.fromSource(TryOnSource source) {
    if (source.file != null) {
      return _TryOnGarmentSource.file(
        source.file!,
        id: source.id,
        type: source.type,
        title: source.title,
        subtitle: source.subtitle,
        ownerId: source.ownerId,
        raw: source.raw,
      );
    }
    return _TryOnGarmentSource.network(
      source.imageUrl,
      id: source.id,
      type: source.type,
      title: source.title,
      subtitle: source.subtitle,
      ownerId: source.ownerId,
      raw: source.raw,
    );
  }

  bool get hasImage => file != null || (imageUrl?.trim().isNotEmpty ?? false);

  bool get isNetworkImage {
    final value = imageUrl?.trim().toLowerCase() ?? '';
    return value.startsWith('http://') || value.startsWith('https://');
  }

  File? get effectiveFile {
    if (file != null) return file;
    final value = imageUrl?.trim() ?? '';
    if (value.isEmpty || isNetworkImage) return null;
    return File(value);
  }

  TryOnSource toSource() {
    return TryOnSource(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl ?? '',
      file: file,
      ownerId: ownerId,
      raw: raw,
    );
  }
}

enum _TryOnMode { freePreview, faceAccessory, ai }

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen>
    with TickerProviderStateMixin {
  File? personImage;
  File? garmentImageFile;
  String? garmentImageUrl;
  String? garmentSourceLabel;
  _TryOnGarmentSource? selectedGarmentSource;
  Uint8List? resultImage;
  String? savedResultUrl;
  bool isSavingResult = false;
  bool isProcessing = false;
  _TryOnMode tryOnMode = _TryOnMode.freePreview;
  String statusMessage = '';
  final ImagePicker _picker = ImagePicker();
  bool isCancelled = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TryOnSourceService _sourceService = TryOnSourceService();
  final TryOnResultService _resultService = TryOnResultService();
  final VirtualTryOnService _tryOnService = VirtualTryOnService();
  List<TryOnSource> products = [];
  List<TryOnSource> creations = [];
  List<TryOnSource> wardrobeItems = [];
  List<TryOnSource> savedItems = [];
  bool isLoadingProducts = true;
  bool isLoadingClientSources = true;

  // ElegantFaso palette
  static const Color _primaryColor = Color(0xFF0F766E); // Teal élégant
  static const Color _amberAccent = Color(0xFFF59E0B);
  static const Color _blueInfo = Color(0xFF2563EB);
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _errorRed = Color(0xFFDC2626);
  static const Color _bgColor = Color(0xFFF3F5F7);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2933);
  static const Color _textSecondary = Color(0xFF7B8492);
  static const Color _borderColor = Color(0xFFE4E8EE);

  @override
  void initState() {
    super.initState();
    _hydrateInitialSource();
    _initializeFirebase();
    _loadProducts();
    _loadClientSources();
  }

  void _hydrateInitialSource() {
    final initialSource = widget.initialSource;
    if (initialSource != null && initialSource.hasImage) {
      final source = _TryOnGarmentSource.fromSource(initialSource);
      _setInitialGarment(source);
      return;
    }

    final imagePath = widget.initialImagePath?.trim() ?? '';
    if (imagePath.isEmpty) return;
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final source =
        isNetwork
            ? _TryOnGarmentSource.network(
              imagePath,
              title: 'Pièce sélectionnée',
              subtitle: 'Depuis le Salon',
            )
            : _TryOnGarmentSource.file(
              File(imagePath),
              title: 'Pièce sélectionnée',
              subtitle: 'Image locale',
            );
    _setInitialGarment(source);
  }

  void _setInitialGarment(_TryOnGarmentSource source) {
    garmentImageFile = source.effectiveFile;
    garmentImageUrl = source.isNetworkImage ? source.imageUrl : null;
    garmentSourceLabel = source.title;
    selectedGarmentSource = source;
    tryOnMode = _preferredModeFor(source);
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _loadProducts() async {
    final userId = await _resolveUserId() ?? '';
    try {
      final loadedProducts = await _sourceService.loadSalonProducts(userId);
      final loadedCreations = await _sourceService.loadSalonCreations(userId);

      if (mounted) {
        setState(() {
          products = loadedProducts;
          creations = loadedCreations;
          isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProducts = false;
        });
        _showSnackBar('Erreur de chargement des produits', _errorRed);
      }
    }
  }

  Future<void> _loadClientSources() async {
    final userId = await _resolveUserId();
    if (userId == null) {
      if (mounted) setState(() => isLoadingClientSources = false);
      return;
    }

    var wardrobe = <TryOnSource>[];
    var saved = <TryOnSource>[];

    try {
      wardrobe = await _sourceService.loadWardrobe(userId);
    } catch (e) {
      debugPrint('Erreur chargement garde-robe essayage: $e');
    }

    try {
      saved = await _sourceService.loadWishlist(userId);
    } catch (e) {
      debugPrint('Erreur chargement souhaits essayage: $e');
    }

    if (!mounted) return;
    setState(() {
      wardrobeItems = wardrobe;
      savedItems = saved;
      isLoadingClientSources = false;
    });
  }

  Future<String?> _resolveUserId() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;

    try {
      final user = await _auth
          .authStateChanges()
          .where((user) => user != null)
          .first
          .timeout(const Duration(seconds: 3));
      return user?.uid;
    } on TimeoutException {
      return _auth.currentUser?.uid;
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

  Future<_TryOnGarmentSource?> _pickGarmentFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;
    return _TryOnGarmentSource.file(
      File(image.path),
      title: 'Image de la galerie',
      subtitle: 'Fichier local',
    );
  }

  void _applyGarmentSelection(_TryOnGarmentSource source) {
    setState(() {
      garmentImageFile = source.effectiveFile;
      garmentImageUrl = source.isNetworkImage ? source.imageUrl : null;
      garmentSourceLabel = source.title;
      selectedGarmentSource = source;
      resultImage = null;
      savedResultUrl = null;
      statusMessage = '';
    });
  }

  Future<void> _performTryOn() async {
    if (personImage == null ||
        (garmentImageUrl == null && garmentImageFile == null)) {
      _showSnackBar('Veuillez sélectionner les deux images', _amberAccent);
      return;
    }

    final selectedSource = selectedGarmentSource;
    if (tryOnMode == _TryOnMode.faceAccessory &&
        selectedSource != null &&
        !_supportsFaceAccessory(selectedSource)) {
      _showSnackBar(
        'Ce mode est pensé pour lunettes, chapeaux, foulards ou bijoux près du visage.',
        _amberAccent,
      );
      return;
    }

    if (tryOnMode == _TryOnMode.ai &&
        selectedSource != null &&
        !_supportsAiTryOn(selectedSource)) {
      _showSnackBar(
        'Cette pièce sera plus naturelle en aperçu libre. Le rendu assisté est surtout pensé pour les vêtements.',
        _amberAccent,
      );
      return;
    }

    setState(() {
      isProcessing = true;
      isCancelled = false;
      statusMessage = 'Préparation…';
      resultImage = null;
    });

    try {
      final garmentFile = await _resolveGarmentFile();

      if (tryOnMode == _TryOnMode.faceAccessory) {
        setState(() => statusMessage = 'Détection du visage…');
        final preview = await _generateFaceAccessoryPreview(
          person: personImage!,
          accessory: garmentFile,
        );
        if (!mounted || isCancelled) return;
        setState(() {
          isProcessing = false;
          resultImage = preview;
          statusMessage =
              'Accessoire ajusté. Utilisez une image PNG transparente pour un rendu plus naturel.';
        });
        return;
      }

      if (tryOnMode == _TryOnMode.freePreview ||
          !_tryOnService.hasConfiguredProvider) {
        setState(() => statusMessage = 'Préparation de votre aperçu…');
        final preview = await _generateFreePreview(
          person: personImage!,
          garment: garmentFile,
        );
        if (!mounted || isCancelled) return;
        setState(() {
          isProcessing = false;
          resultImage = preview;
          statusMessage =
              'Votre aperçu est prêt. Une photo bien droite donnera un rendu encore plus naturel.';
        });
        return;
      }

      final result = await _tryOnService.performVirtualTryOn(
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
            statusMessage = 'Aperçu annulé';
          });
          return;
        }

        setState(() {
          isProcessing = false;
          if (result.success) {
            resultImage = result.data;
            statusMessage = result.message;
          } else {
            statusMessage = result.message;
          }
        });

        if (!result.success) {
          _showSnackBar(result.message, _errorRed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          statusMessage =
              'Nous n’avons pas pu préparer l’aperçu. Essayez une autre photo.';
        });
        _showSnackBar(
          'Nous n’avons pas pu préparer l’aperçu. Essayez une autre photo.',
          _errorRed,
        );
      }
    }
  }

  Future<File> _resolveGarmentFile() async {
    if (garmentImageFile != null) return garmentImageFile!;
    final url = garmentImageUrl;
    if (url == null || url.trim().isEmpty) {
      throw Exception('Image vêtement manquante');
    }
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Échec du téléchargement du vêtement');
    }

    final tempDir = await Directory.systemTemp.createTemp();
    final garmentFile = File('${tempDir.path}/garment.jpg');
    await garmentFile.writeAsBytes(response.bodyBytes, flush: true);
    return garmentFile;
  }

  Future<Uint8List> _generateFreePreview({
    required File person,
    required File garment,
  }) async {
    final personImage = await _decodeImage(await person.readAsBytes());
    final garmentImage = await _decodeImage(await garment.readAsBytes());

    const outputWidth = 900.0;
    const outputHeight = 1200.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, outputWidth, outputHeight),
    );

    final outputRect = const Rect.fromLTWH(0, 0, outputWidth, outputHeight);
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(outputRect, bgPaint);
    canvas.drawImageRect(
      personImage,
      _coverSourceRect(personImage, outputRect),
      outputRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    canvas.drawRect(
      outputRect,
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );

    final garmentRect = _garmentPlacement(
      garmentImage.width / garmentImage.height,
    );
    final haloRect = garmentRect.inflate(14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(haloRect, const Radius.circular(28)),
      Paint()..color = Colors.white.withValues(alpha: 0.20),
    );
    canvas.drawImageRect(
      garmentImage,
      Rect.fromLTWH(
        0,
        0,
        garmentImage.width.toDouble(),
        garmentImage.height.toDouble(),
      ),
      garmentRect,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Colors.white.withValues(alpha: 0.88),
    );

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: 'Aperçu libre',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelRect = Rect.fromLTWH(28, 28, labelPainter.width + 28, 46);
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(999)),
      Paint()..color = _primaryColor.withValues(alpha: 0.88),
    );
    labelPainter.paint(canvas, const Offset(42, 37));

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      outputWidth.toInt(),
      outputHeight.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _generateFaceAccessoryPreview({
    required File person,
    required File accessory,
  }) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.12,
      ),
    );

    try {
      final personBytes = await person.readAsBytes();
      final personImage = await _decodeImage(personBytes, targetWidth: null);
      final accessoryImage = await _decodeImage(await accessory.readAsBytes());
      final faces = await detector.processImage(InputImage.fromFile(person));

      if (faces.isEmpty) {
        if (mounted) {
          setState(() {
            statusMessage =
                'Visage non détecté. Aperçu libre utilisé pour garder le parcours fluide.';
          });
        }
        return _generateFreePreview(person: person, garment: accessory);
      }

      final face = faces.reduce((a, b) {
        final aArea = a.boundingBox.width * a.boundingBox.height;
        final bArea = b.boundingBox.width * b.boundingBox.height;
        return aArea >= bArea ? a : b;
      });

      const outputWidth = 900.0;
      const outputHeight = 1200.0;
      final outputRect = const Rect.fromLTWH(0, 0, outputWidth, outputHeight);
      final sourceRect = _coverSourceRect(personImage, outputRect);
      final faceRect = _mapImageRectToCanvas(
        face.boundingBox,
        sourceRect,
        outputRect.size,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, outputRect);
      canvas.drawRect(outputRect, Paint()..color = Colors.white);
      canvas.drawImageRect(
        personImage,
        sourceRect,
        outputRect,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.drawRect(
        outputRect,
        Paint()..color = Colors.black.withValues(alpha: 0.025),
      );

      final accessoryRect = _faceAccessoryPlacement(
        face,
        faceRect,
        sourceRect,
        outputRect.size,
        accessoryImage.width / accessoryImage.height,
      );
      final angle =
          ((face.headEulerAngleZ ?? 0) * math.pi / 180)
              .clamp(-0.25, 0.25)
              .toDouble();

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          accessoryRect.inflate(10),
          const Radius.circular(999),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      _drawImageRectRotated(
        canvas,
        accessoryImage,
        Rect.fromLTWH(
          0,
          0,
          accessoryImage.width.toDouble(),
          accessoryImage.height.toDouble(),
        ),
        accessoryRect,
        angle,
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = Colors.white.withValues(alpha: 0.94),
      );

      final labelPainter = TextPainter(
        text: const TextSpan(
          text: 'Accessoire visage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 760);
      final labelRect = Rect.fromLTWH(28, 28, labelPainter.width + 28, 46);
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(999)),
        Paint()..color = _primaryColor.withValues(alpha: 0.88),
      );
      labelPainter.paint(canvas, const Offset(42, 37));

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        outputWidth.toInt(),
        outputHeight.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      await detector.close();
    }
  }

  Future<ui.Image> _decodeImage(
    Uint8List bytes, {
    int? targetWidth = 900,
  }) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Rect _coverSourceRect(ui.Image image, Rect outputRect) {
    final inputRatio = image.width / image.height;
    final outputRatio = outputRect.width / outputRect.height;
    if (inputRatio > outputRatio) {
      final width = image.height * outputRatio;
      final left = (image.width - width) / 2;
      return Rect.fromLTWH(left, 0, width, image.height.toDouble());
    }
    final height = image.width / outputRatio;
    final top = (image.height - height) / 2;
    return Rect.fromLTWH(0, top, image.width.toDouble(), height);
  }

  Rect _garmentPlacement(double aspectRatio) {
    final source = selectedGarmentSource;
    final text = _sourceSearchText(source);
    double widthFactor = 0.58;
    double centerX = 0.50;
    double top = 0.25;

    if (text.contains('sac') || text.contains('bag')) {
      widthFactor = 0.36;
      centerX = 0.68;
      top = 0.48;
    } else if (text.contains('chauss') ||
        text.contains('shoe') ||
        text.contains('sandale')) {
      widthFactor = 0.50;
      centerX = 0.50;
      top = 0.74;
    } else if (text.contains('bijou') ||
        text.contains('lunette') ||
        text.contains('foulard')) {
      widthFactor = 0.34;
      centerX = 0.50;
      top = 0.18;
    }

    final width = 900.0 * widthFactor;
    final height = (width / aspectRatio).clamp(160.0, 620.0);
    final left = (900.0 * centerX) - (width / 2);
    return Rect.fromLTWH(left, 1200.0 * top, width, height);
  }

  Rect _faceAccessoryPlacement(
    Face face,
    Rect faceRect,
    Rect sourceRect,
    Size outputSize,
    double aspectRatio,
  ) {
    final source = selectedGarmentSource;
    final text = _sourceSearchText(source);
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;
    final eyeCenter =
        leftEye != null && rightEye != null
            ? (_mapPointToCanvas(leftEye.x, leftEye.y, sourceRect, outputSize) +
                    _mapPointToCanvas(
                      rightEye.x,
                      rightEye.y,
                      sourceRect,
                      outputSize,
                    )) /
                2
            : Offset(faceRect.center.dx, faceRect.top + faceRect.height * 0.36);
    final nosePoint =
        nose == null
            ? Offset(faceRect.center.dx, faceRect.top + faceRect.height * 0.54)
            : _mapPointToCanvas(nose.x, nose.y, sourceRect, outputSize);

    double width = faceRect.width * 0.78;
    double top = eyeCenter.dy - width / aspectRatio * 0.46;
    double centerX = eyeCenter.dx;

    if (text.contains('chapeau') ||
        text.contains('hat') ||
        text.contains('casquette')) {
      width = faceRect.width * 1.18;
      top = faceRect.top - (width / aspectRatio) * 0.58;
      centerX = faceRect.center.dx;
    } else if (text.contains('foulard') ||
        text.contains('turban') ||
        text.contains('scarf')) {
      width = faceRect.width * 1.10;
      top = faceRect.top - (width / aspectRatio) * 0.18;
      centerX = faceRect.center.dx;
    } else if (text.contains('boucle') ||
        text.contains('oreille') ||
        text.contains('earring')) {
      final mappedLeftEar =
          leftEar == null
              ? Offset(faceRect.left + faceRect.width * 0.05, nosePoint.dy)
              : _mapPointToCanvas(leftEar.x, leftEar.y, sourceRect, outputSize);
      final mappedRightEar =
          rightEar == null
              ? Offset(faceRect.right - faceRect.width * 0.05, nosePoint.dy)
              : _mapPointToCanvas(
                rightEar.x,
                rightEar.y,
                sourceRect,
                outputSize,
              );
      width = (mappedRightEar.dx - mappedLeftEar.dx).abs().clamp(
        faceRect.width * 0.62,
        faceRect.width * 1.12,
      );
      top = nosePoint.dy - (width / aspectRatio) * 0.22;
      centerX = faceRect.center.dx;
    } else if (text.contains('collier') ||
        text.contains('necklace') ||
        text.contains('bijou')) {
      width = faceRect.width * 0.90;
      top = faceRect.bottom - (width / aspectRatio) * 0.08;
      centerX = faceRect.center.dx;
    }

    final height = (width / aspectRatio).clamp(56.0, 360.0);
    final left = (centerX - width / 2).clamp(10.0, 890.0 - width).toDouble();
    final safeTop = top.clamp(10.0, 1190.0 - height).toDouble();
    return Rect.fromLTWH(left, safeTop, width, height);
  }

  Rect _mapImageRectToCanvas(Rect rect, Rect sourceRect, Size outputSize) {
    final topLeft = _mapPointToCanvas(
      rect.left,
      rect.top,
      sourceRect,
      outputSize,
    );
    final bottomRight = _mapPointToCanvas(
      rect.right,
      rect.bottom,
      sourceRect,
      outputSize,
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Offset _mapPointToCanvas(num x, num y, Rect sourceRect, Size outputSize) {
    final mappedX =
        ((x - sourceRect.left) / sourceRect.width) * outputSize.width;
    final mappedY =
        ((y - sourceRect.top) / sourceRect.height) * outputSize.height;
    return Offset(mappedX, mappedY);
  }

  void _drawImageRectRotated(
    Canvas canvas,
    ui.Image image,
    Rect source,
    Rect destination,
    double radians,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(destination.center.dx, destination.center.dy);
    canvas.rotate(radians);
    final centered = Rect.fromCenter(
      center: Offset.zero,
      width: destination.width,
      height: destination.height,
    );
    canvas.drawImageRect(image, source, centered, paint);
    canvas.restore();
  }

  String _sourceSearchText(_TryOnGarmentSource? source) {
    if (source == null) return '';
    return '${source.title} ${source.subtitle} ${source.type.name}'
        .toLowerCase();
  }

  TryOnCompatibility _compatibilityFor(_TryOnGarmentSource source) {
    return TryOnCompatibility.fromSource(
      title: source.title,
      subtitle: source.subtitle,
      sourceType: source.type.name,
      raw: source.raw,
    );
  }

  TryOnExperience _currentExperience() {
    return switch (tryOnMode) {
      _TryOnMode.freePreview => TryOnExperience.freePreview,
      _TryOnMode.faceAccessory => TryOnExperience.faceAccessory,
      _TryOnMode.ai => TryOnExperience.aiGarment,
    };
  }

  _TryOnMode _preferredModeFor(_TryOnGarmentSource source) {
    final compatibility = _compatibilityFor(source);
    if (compatibility.supports(TryOnExperience.faceAccessory) &&
        compatibility.kind == TryOnPieceKind.faceAccessory) {
      return _TryOnMode.faceAccessory;
    }
    if (compatibility.supports(TryOnExperience.aiGarment) &&
        _tryOnService.hasConfiguredProvider) {
      return _TryOnMode.ai;
    }
    return _TryOnMode.freePreview;
  }

  bool _supportsFaceAccessory(_TryOnGarmentSource source) {
    return _compatibilityFor(source).supports(TryOnExperience.faceAccessory);
  }

  bool _supportsAiTryOn(_TryOnGarmentSource source) {
    return _compatibilityFor(source).supports(TryOnExperience.aiGarment);
  }

  bool _isRecommendedForCurrentMode(_TryOnGarmentSource source) {
    return _compatibilityFor(source).supports(_currentExperience());
  }

  String _pieceKindLabel(_TryOnGarmentSource source) {
    if (source.type == TryOnSourceType.gallery) return 'Libre';
    return _compatibilityFor(source).label;
  }

  String _experienceLabel() {
    return switch (tryOnMode) {
      _TryOnMode.freePreview => 'Aperçu libre',
      _TryOnMode.faceAccessory => 'Accessoire visage',
      _TryOnMode.ai => 'Rendu assisté',
    };
  }

  void _cancelProcessing() {
    setState(() {
      isCancelled = true;
      isProcessing = false;
      statusMessage = 'Annulation en cours…';
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveResultToWardrobe() async {
    final userId = await _resolveUserId();
    final bytes = resultImage;
    final source = selectedGarmentSource;
    if (userId == null || bytes == null || source == null) {
      _showSnackBar(
        'Essayage incomplet. Relancez avec un vêtement.',
        _amberAccent,
      );
      return;
    }

    setState(() {
      isSavingResult = true;
      statusMessage = 'Sauvegarde dans vos essayages...';
    });

    try {
      final url = await _resultService.saveResult(
        userId: userId,
        bytes: bytes,
        source: source.toSource(),
        personImagePath: personImage?.path ?? '',
        garmentImageUrl: garmentImageUrl ?? source.imageUrl ?? '',
        experience: _currentExperience(),
        pieceKind: _compatibilityFor(source).kind,
        experienceLabel: _experienceLabel(),
      );
      if (!mounted) return;
      setState(() {
        savedResultUrl = url;
        isSavingResult = false;
        statusMessage = 'Essayage sauvegardé dans votre garde-robe.';
      });
      _showSnackBar('Essayage sauvegardé dans Looks essayés.', _successGreen);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSavingResult = false;
        statusMessage = 'Sauvegarde impossible pour le moment.';
      });
      _showSnackBar('Impossible de sauvegarder cet essayage.', _errorRed);
    }
  }

  Future<void> _shareResult() async {
    final bytes = resultImage;
    if (bytes == null) return;
    final tempDir = await Directory.systemTemp.createTemp();
    final file = File('${tempDir.path}/elegantstyle_try_on.jpg');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Mon essayage virtuel ElegantStyle',
      ),
    );
  }

  // --- Widgets stylisés ElegantFaso ---

  Widget _buildImageCard({
    required String title,
    required File? image,
    String? imageUrl,
    required VoidCallback onTap,
    required IconData icon,
    required Color buttonColor,
    required IconData placeholderIcon,
  }) {
    final bool hasImage =
        image != null || (imageUrl != null && imageUrl.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(6, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-3, -3),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Color(0x1A0F172A),
                    offset: Offset(3, 4),
                    blurRadius: 9,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child:
                    hasImage
                        ? image != null
                            ? Image.file(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              cacheWidth: 800,
                              gaplessPlayback: true,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildImageErrorWidget(),
                            )
                            : CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 800,
                              placeholder:
                                  (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryColor,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      _buildImageErrorWidget(),
                            )
                        : Container(
                          color: _bgColor,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                placeholderIcon,
                                size: 56,
                                color: _textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Touchez pour sélectionner',
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(
              hasImage ? 'Changer' : 'Sélectionner',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: const BorderSide(color: _primaryColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: const Color(0xFFFEF2F2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: _errorRed),
            const SizedBox(height: 8),
            const Text(
              'Erreur d\'image',
              style: TextStyle(color: _errorRed, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard() {
    final hasAiProvider = _tryOnService.hasConfiguredProvider;
    final modeCopy = switch (tryOnMode) {
      _TryOnMode.freePreview =>
        'Aperçu libre : rapide, léger, utile pour se projeter avec vêtements, sacs et chaussures.',
      _TryOnMode.faceAccessory =>
        'Accessoire visage : ajuste lunettes, chapeaux, foulards ou bijoux à partir de votre photo.',
      _TryOnMode.ai =>
        hasAiProvider
            ? 'Rendu assisté : plus adapté aux vêtements, avec un résultat qui dépend de la photo et de la connexion.'
            : 'Rendu assisté indisponible pour le moment. Vous pouvez garder l’aperçu libre, il reste rapide et fluide.',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 8),
          BoxShadow(
            color: Color(0x1A0F172A),
            offset: Offset(3, 4),
            blurRadius: 9,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.offline_bolt_rounded,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Studio d’essayage',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildModeChip(
                mode: _TryOnMode.freePreview,
                icon: Icons.auto_fix_high_rounded,
                label: 'Aperçu libre',
              ),
              _buildModeChip(
                mode: _TryOnMode.faceAccessory,
                icon: Icons.face_retouching_natural_rounded,
                label: 'Accessoire visage',
              ),
              _buildModeChip(
                mode: _TryOnMode.ai,
                icon: Icons.auto_awesome_rounded,
                label: 'Assisté',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            modeCopy,
            style: const TextStyle(
              color: _textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!hasAiProvider && tryOnMode == _TryOnMode.ai) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed:
                  () => setState(() => tryOnMode = _TryOnMode.freePreview),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Utiliser l’aperçu libre'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTryOnGuidanceCard() {
    final selectedSource = selectedGarmentSource;
    final hasSelection = selectedSource != null;
    final recommended =
        !hasSelection || _isRecommendedForCurrentMode(selectedSource);
    final title = switch (tryOnMode) {
      _TryOnMode.faceAccessory => 'Pour un accessoire visage réussi',
      _TryOnMode.ai => 'Pour un rendu naturel',
      _TryOnMode.freePreview => 'Pour un aperçu libre fluide',
    };
    final text = switch (tryOnMode) {
      _TryOnMode.faceAccessory =>
        'Choisissez une photo nette du visage, puis une lunette, un chapeau, un foulard ou un bijou. Les PNG transparents donnent le meilleur rendu.',
      _TryOnMode.ai =>
        'Gardez ce mode pour robes, hauts, vestes ou ensembles. Une photo debout, bien éclairée, améliore beaucoup le résultat.',
      _TryOnMode.freePreview =>
        'Idéal pour visualiser vite une idée, même sans connexion forte. Fonctionne avec vêtements, sacs, chaussures et images de galerie.',
    };
    final warning =
        hasSelection && !recommended
            ? 'La pièce choisie semble mieux adaptée à un autre mode.'
            : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            warning == null
                ? _primaryColor.withValues(alpha: 0.08)
                : _amberAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              warning == null
                  ? _primaryColor.withValues(alpha: 0.18)
                  : _amberAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning == null
                ? Icons.tips_and_updates_rounded
                : Icons.info_rounded,
            color: warning == null ? _primaryColor : _amberAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning ?? title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warning == null ? text : '$warning $text',
                  style: const TextStyle(
                    color: _textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required _TryOnMode mode,
    required IconData icon,
    required String label,
  }) {
    final selected = tryOnMode == mode;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : _primaryColor,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 12.5,
      ),
      selectedColor: _primaryColor,
      backgroundColor: _bgColor,
      side: BorderSide(color: selected ? _primaryColor : _borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) {
        setState(() {
          tryOnMode = mode;
          resultImage = null;
          savedResultUrl = null;
          statusMessage = '';
        });
      },
    );
  }

  Widget _buildTryOnButton() {
    if (isProcessing) {
      return AppButton(
        label: 'Annuler',
        onPressed: _cancelProcessing,
        icon: Icons.cancel_rounded,
        variant: AppButtonVariant.danger,
        expand: true,
      );
    }

    return AppButton(
      label:
          tryOnMode == _TryOnMode.faceAccessory
              ? 'Essayer l’accessoire'
              : 'Voir le rendu',
      onPressed: _performTryOn,
      icon:
          tryOnMode == _TryOnMode.faceAccessory
              ? Icons.face_retouching_natural_rounded
              : Icons.checkroom_rounded,
      expand: true,
    );
  }

  Widget _buildStatusCard() {
    if (statusMessage.isEmpty) return const SizedBox.shrink();

    Color statusColor;
    IconData statusIcon;

    if (statusMessage.contains('✅')) {
      statusColor = _successGreen;
      statusIcon = Icons.check_circle_rounded;
    } else if (statusMessage.contains('❌')) {
      statusColor = _errorRed;
      statusIcon = Icons.error_rounded;
    } else if (statusMessage.contains('⏳') ||
        statusMessage.contains('🔄') ||
        statusMessage.contains('⏭️')) {
      statusColor = _primaryColor;
      statusIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusColor = _blueInfo;
      statusIcon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 8),
          BoxShadow(
            color: Color(0x1A0F172A),
            offset: Offset(3, 4),
            blurRadius: 9,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              statusMessage.replaceAll(RegExp(r'[🔄❌✅⏭️📥⏳]'), '').trim(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (resultImage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(6, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _successGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Votre aperçu est prêt',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Image.memory(
                resultImage!,
                fit: BoxFit.cover,
                cacheWidth: 800,
                gaplessPlayback: true,
                errorBuilder:
                    (context, error, stackTrace) => _buildImageErrorWidget(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.refresh_rounded,
                label: 'Réessayer',
                isPrimary: true,
                onPressed: _performTryOn,
              ),
              _buildActionButton(
                icon:
                    savedResultUrl == null
                        ? Icons.bookmark_add_rounded
                        : Icons.check_circle_rounded,
                label:
                    isSavingResult
                        ? 'Sauvegarde...'
                        : savedResultUrl == null
                        ? 'Sauvegarder'
                        : 'Sauvegardé',
                isPrimary: false,
                onPressed:
                    isSavingResult || savedResultUrl != null
                        ? () {}
                        : _saveResultToWardrobe,
              ),
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Partager',
                isPrimary: false,
                onPressed: _shareResult,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    if (isPrimary) {
      return AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        compact: true,
      );
    } else {
      return AppButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        variant: AppButtonVariant.secondary,
        compact: true,
      );
    }
  }

  Widget _buildProductSelection() {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: _cardColor,
          foregroundColor: _textPrimary,
          elevation: 0,
          title: const Text(
            'Sélectionnez une pièce',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Recharger',
              onPressed: () {
                setState(() => isLoadingClientSources = true);
                _loadClientSources();
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _primaryColor,
            unselectedLabelColor: _textSecondary,
            indicatorColor: _primaryColor,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Garde-robe'),
              Tab(text: 'Souhaits'),
              Tab(text: 'Galerie'),
              Tab(text: 'Produits'),
              Tab(text: 'Créations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildWardrobeGrid(),
            _buildSavedGrid(),
            _buildGalleryPickerPanel(),
            _buildSourceGrid(products, isLoading: isLoadingProducts),
            _buildSourceGrid(creations, isLoading: isLoadingProducts),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeGrid() {
    return _buildSourceGrid(wardrobeItems, isLoading: isLoadingClientSources);
  }

  Widget _buildSavedGrid() {
    return _buildSourceGrid(savedItems, isLoading: isLoadingClientSources);
  }

  Widget _buildGalleryPickerPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                offset: Offset(0, 12),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: _primaryColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Importer depuis votre galerie',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choisissez une photo de vêtement enregistrée sur votre téléphone. Idéal pour visualiser une pièce vue ailleurs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final source = await _pickGarmentFromGallery();
                    if (source == null) return;
                    navigator.pop(source);
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Choisir une image'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceGrid(List<dynamic> items, {required bool isLoading}) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          'Aucun élément disponible',
          style: const TextStyle(fontSize: 16, color: _textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = _sourceFrom(items[index]);
        final hasImage = item.hasImage;
        final recommended = _isRecommendedForCurrentMode(item);

        return GestureDetector(
          onTap: () {
            if (hasImage) {
              Navigator.pop(context, item);
            } else {
              _showSnackBar('Image non disponible', _amberAccent);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Color(0x1A0F172A),
                  offset: Offset(3, 4),
                  blurRadius: 9,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hasImage
                            ? _buildSourceImage(item)
                            : _buildImageErrorWidget(),
                        if (!recommended)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _buildSourceBadge(item, recommended),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceBadge(_TryOnGarmentSource item, bool recommended) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            recommended
                ? _primaryColor.withValues(alpha: 0.92)
                : _amberAccent.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        recommended ? _pieceKindLabel(item) : 'Autre mode',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSourceImage(_TryOnGarmentSource item) {
    final localFile = item.effectiveFile;
    if (localFile != null) {
      return Image.file(
        localFile,
        fit: BoxFit.cover,
        width: double.infinity,
        cacheWidth: 400,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.imageUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      placeholder:
          (context, url) =>
              Center(child: CircularProgressIndicator(color: _primaryColor)),
      errorWidget: (context, url, error) => _buildImageErrorWidget(),
    );
  }

  _TryOnGarmentSource _sourceFrom(dynamic item) {
    if (item is _TryOnGarmentSource) return item;
    if (item is TryOnSource) return _TryOnGarmentSource.fromSource(item);
    if (item is Map<String, dynamic>) {
      return _TryOnGarmentSource.network(
        item['imageUrl']?.toString() ?? '',
        id: item['id']?.toString() ?? '',
        type: TryOnSourceType.gallery,
        title: item['name']?.toString() ?? 'Sans nom',
        subtitle: item['category']?.toString() ?? '',
        ownerId: item['ownerId']?.toString() ?? '',
        raw: item,
      );
    }
    return const _TryOnGarmentSource.empty();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Studio d’essayage',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo de la personne
            _buildImageCard(
              title: 'Photo de la personne',
              image: personImage,
              imageUrl: null,
              onTap: _pickPersonImage,
              icon: Icons.photo_library_rounded,
              buttonColor: Colors.blue,
              placeholderIcon: Icons.person_rounded,
            ),

            const SizedBox(height: 20),

            // Pièce à essayer
            _buildImageCard(
              title:
                  tryOnMode == _TryOnMode.faceAccessory
                      ? 'Accessoire à essayer'
                      : 'Pièce à essayer',
              image: garmentImageFile,
              imageUrl: garmentImageUrl,
              onTap: () async {
                final selectedSource =
                    await Navigator.push<_TryOnGarmentSource>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildProductSelection(),
                      ),
                    );

                if (selectedSource != null) {
                  _applyGarmentSelection(selectedSource);
                }
              },
              icon: Icons.checkroom_rounded,
              buttonColor: Colors.green,
              placeholderIcon: Icons.shopping_bag_rounded,
            ),

            const SizedBox(height: 24),

            // Choix du rendu
            _buildModeCard(),

            const SizedBox(height: 16),

            _buildTryOnGuidanceCard(),

            const SizedBox(height: 16),

            _buildTryOnButton(),

            const SizedBox(height: 20),

            // Statut de l’aperçu
            _buildStatusCard(),

            const SizedBox(height: 20),

            // Résultat
            _buildResultCard(),
          ],
        ),
      ),
    );
  }
}

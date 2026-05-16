import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/account_roles.dart';
import '../media/media_asset_service.dart';
import '../media/media_upload_service.dart';
import '../preferences/currency_service.dart';

class CatalogueExpressDraft {
  const CatalogueExpressDraft({
    required this.file,
    required this.title,
    required this.category,
    required this.price,
    required this.quantity,
    required this.mode,
    required this.status,
    required this.description,
  });

  final XFile file;
  final String title;
  final String category;
  final double price;
  final int quantity;
  final String mode;
  final String status;
  final String description;
}

class CatalogueExpressResult {
  const CatalogueExpressResult({
    required this.created,
    required this.collection,
  });

  final int created;
  final String collection;
}

class CatalogueExpressService {
  CatalogueExpressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MediaUploadService? mediaUploadService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _mediaUploadService = mediaUploadService ?? MediaUploadService(),
       _mediaAssetService = MediaAssetService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MediaUploadService _mediaUploadService;
  final MediaAssetService _mediaAssetService;

  Future<CatalogueExpressResult> publishDrafts({
    required String role,
    required List<CatalogueExpressDraft> drafts,
    required void Function(String stage, double progress) onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Connectez-vous pour publier.');
    if (drafts.isEmpty) throw StateError('Ajoutez au moins une photo.');

    final isCreator = role == AccountRoles.createur;
    final collection = isCreator ? 'creations' : 'products';
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final currency = CurrencyService.currencyFromUserData(
      userDoc.data() ?? const {},
    );

    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      final file = File(draft.file.path);
      final docRef = _firestore.collection(collection).doc();
      final index = i + 1;
      onProgress('Upload photo $index/${drafts.length}', i / drafts.length);
      final upload = await _mediaUploadService.uploadImage(
        file: file,
        folder: isCreator ? 'creations/${user.uid}' : 'products/${user.uid}',
        publicId: 'express_${DateTime.now().millisecondsSinceEpoch}_$i',
      );
      final mediaId = await _mediaAssetService.recordUpload(
        upload: upload,
        ownerId: user.uid,
        ownerRole: role,
        usage: isCreator ? 'creation_express' : 'product_express',
        status: draft.status == 'published' ? 'public' : 'draft',
        linkedCollection: collection,
        linkedDocumentId: docRef.id,
      );

      onProgress(
        'Création du brouillon $index/${drafts.length}',
        (i + 0.5) / drafts.length,
      );
      final common = {
        'ownerId': user.uid,
        'sellerId': user.uid,
        'sellerRole': role,
        'title': draft.title,
        'name': draft.title,
        'description': draft.description,
        'category': draft.category,
        'price': draft.price,
        'currency': currency,
        'status': draft.status,
        'visibility': draft.status == 'published' ? 'salon' : 'private',
        'isPublished': draft.status == 'published',
        'visibleInSalon': draft.status == 'published',
        'imageUrl': upload.optimizedUrl,
        'coverImage': upload.optimizedUrl,
        'thumbnailUrl': upload.thumbnailUrl,
        'mediaIds': [mediaId],
        'media': [upload.copyWithAssetId(mediaId).toMap()],
        'source': 'catalogue_express',
        'expressMode': draft.mode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isCreator) {
        await docRef.set({
          ...common,
          'creatorId': user.uid,
          'createurId': user.uid,
          'priceEstimate': draft.price,
          'availability': draft.mode,
          'images': [upload.optimizedUrl],
          'tags': _tagsFor(draft),
        });
      } else {
        await docRef.set({
          ...common,
          'boutiqueId': user.uid,
          'shopId': user.uid,
          'stock': draft.quantity,
          'quantity': draft.quantity,
          'deliveryMode': draft.mode,
          'stockStatus': draft.quantity <= 1 ? 'piece_unique' : 'available',
        });
      }

      await _mediaAssetService.linkAsset(
        mediaId: mediaId,
        linkedCollection: collection,
        linkedDocumentId: docRef.id,
      );
    }

    onProgress('Catalogue prêt', 1);
    return CatalogueExpressResult(
      created: drafts.length,
      collection: collection,
    );
  }

  List<String> _tagsFor(CatalogueExpressDraft draft) {
    return {
      draft.category,
      draft.mode,
      if (draft.price <= 0) 'prix sur devis',
      'catalogue express',
    }.where((tag) => tag.trim().isNotEmpty).toList();
  }
}

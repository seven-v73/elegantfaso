import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/account_roles.dart';
import '../../models/salon/pro_story.dart';
import '../media/media_asset_service.dart';
import '../media/media_upload_service.dart';
import '../profile/public_profile_service.dart';

class ProStoryService {
  ProStoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    MediaUploadService? mediaUploadService,
    AccountRoleService? accountRoleService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _mediaUploadService = mediaUploadService ?? MediaUploadService(),
       _mediaAssetService = MediaAssetService(firestore: firestore),
       _publicProfileService = PublicProfileService(
         firestore: firestore,
         auth: auth,
       ),
       _accountRoleService =
           accountRoleService ??
           AccountRoleService(firestore: firestore, auth: auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final MediaUploadService _mediaUploadService;
  final MediaAssetService _mediaAssetService;
  final PublicProfileService _publicProfileService;
  final AccountRoleService _accountRoleService;

  CollectionReference<Map<String, dynamic>> get _stories =>
      _firestore.collection('stories');

  Stream<List<ProStory>> watchActiveStories({int limit = 40}) {
    return _stories
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final stories =
              snapshot.docs.map(ProStory.fromDoc).where((story) {
                return !story.isExpired && story.mediaUrl.isNotEmpty;
              }).toList();
          stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return stories;
        });
  }

  Future<String> publishImageStory({
    required String role,
    required File image,
    required String caption,
    String ctaLabel = '',
    String ctaRoute = '',
  }) async {
    if (!AccountRoles.businessRoles.contains(role)) {
      throw StateError('Les stories sont réservées aux comptes pros.');
    }
    final user = _auth.currentUser;
    if (user == null) throw StateError('Connectez-vous pour publier.');
    final roleState = await _accountRoleService.getCurrentState();
    if (roleState == null || !roleState.hasRole(role)) {
      throw StateError('Ce compte n’a pas accès aux stories pro.');
    }

    final profile = await _publicProfileService.load(user.uid);
    final doc = _stories.doc();
    final upload = await _mediaUploadService.uploadImage(
      file: image,
      folder: 'stories/${user.uid}',
      publicId: 'story_${DateTime.now().millisecondsSinceEpoch}',
    );
    final mediaId = await _mediaAssetService.recordUpload(
      upload: upload,
      ownerId: user.uid,
      ownerRole: role,
      usage: 'story',
      status: 'public',
      linkedCollection: 'stories',
      linkedDocumentId: doc.id,
    );

    final now = DateTime.now();
    await doc.set({
      'authorId': user.uid,
      'authorRole': role,
      'authorName':
          profile?.displayName ??
          user.displayName ??
          (role == AccountRoles.boutique ? 'Boutique certifiée' : 'Créateur'),
      'authorPhotoUrl': profile?.photoUrl ?? user.photoURL ?? '',
      'mediaUrl': upload.optimizedUrl,
      'thumbnailUrl': upload.thumbnailUrl,
      'mediaType': 'image',
      'cloudinaryPublicId': upload.publicId,
      'mediaId': mediaId,
      'caption': caption.trim(),
      'ctaLabel': ctaLabel.trim(),
      'ctaRoute': ctaRoute.trim(),
      'visibility': 'salon',
      'status': 'active',
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'stats': {'views': 0, 'taps': 0},
    });
    return doc.id;
  }

  Future<void> markViewed(ProStory story) {
    final userId = _auth.currentUser?.uid;
    return _stories.doc(story.id).set({
      'stats.views': FieldValue.increment(1),
      if (userId != null) 'viewedBy': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

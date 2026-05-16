import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../../design/app_icons.dart';
import 'user_model.dart';
import 'chat_service.dart';
import 'message_model.dart';
import 'product_model.dart';
import '../../../services/media/media_asset_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../../services/salon/salon_analytics_service.dart';
import '../../../models/messages/conversation_context.dart';
import '../base/client_profile_screen.dart';
import '../base/createur_profile_screen.dart';
part 'chat_video_player_screen.dart';
part 'chat_product_detail_screen.dart';

// Écran principal de chat
class ChatScreen extends StatefulWidget {
  final UserModel utilisateurCourant;
  final UserModel autreUtilisateur;
  final Color primaryColor;
  final Color secondaryColor;
  final String? currentRole;
  final String? otherRole;
  final ConversationContext conversationContext;
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.utilisateurCourant,
    required this.autreUtilisateur,
    this.primaryColor = const Color(0xFF6C56F9),
    this.secondaryColor = Colors.white,
    this.currentRole,
    this.otherRole,
    this.conversationContext = const ConversationContext(),
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  static const _messagesPageSize = 50;
  final TextEditingController _messageController = TextEditingController();
  final AutoScrollController _scrollController = AutoScrollController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  final MediaUploadService _mediaUploadService = MediaUploadService();

  late String _idConversation;
  bool _envoiEnCours = false;
  bool _montrerBoutonDefilementBas = false;
  bool _lectureAudioEnCours = false;
  int? _indexAudioEnLecture;
  Position? _positionActuelle;
  bool _enregistrementAudioEnCours = false;
  FlutterSoundRecorder? _enregistreurAudio;
  bool _enregistreurAudioPret = false;
  String? _cheminFichierAudio;
  Timer? _typingTimer;
  double _recordingAmplitude = 0.0;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;
  bool _autreUtilisateurEnLigne = false;
  DateTime? _derniereConnexion;
  StreamSubscription<DocumentSnapshot>? _presenceSubscription;

  String get _currentRole =>
      widget.currentRole ?? widget.utilisateurCourant.role;
  String get _otherRole => widget.otherRole ?? widget.autreUtilisateur.role;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiserChat();
    _initialiserPresence();
    _scrollController.addListener(_ecouteurDefilement);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatService.mettreAJourPresence(widget.utilisateurCourant.id, true);
    } else if (state == AppLifecycleState.paused) {
      _chatService.mettreAJourPresence(widget.utilisateurCourant.id, false);
    }
  }

  Future<bool> _initialiserEnregistreurAudio() async {
    if (_enregistreurAudioPret) return true;
    try {
      final recorder =
          _enregistreurAudio ??= FlutterSoundRecorder(logLevel: Level.off);
      await recorder.openRecorder();
      if (await Permission.microphone.isGranted) {
        await recorder.setSubscriptionDuration(
          const Duration(milliseconds: 50),
        );
      }
      _enregistreurAudioPret = true;
      return true;
    } catch (_) {
      _enregistreurAudioPret = false;
      return false;
    }
  }

  void _initialiserPresence() {
    _presenceSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.autreUtilisateur.id)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>;
              final isOnline = data['isOnline'] ?? false;
              final lastSeen =
                  data['lastSeen'] != null
                      ? (data['lastSeen'] as Timestamp).toDate()
                      : DateTime.now();

              if (mounted) {
                setState(() {
                  _autreUtilisateurEnLigne = isOnline;
                  _derniereConnexion = lastSeen;
                });
              }
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _autreUtilisateurEnLigne = widget.autreUtilisateur.isOnline;
                _derniereConnexion = widget.autreUtilisateur.lastSeen;
              });
            }
          },
        );
  }

  void _initialiserChat() {
    _idConversation =
        widget.conversationId ??
        _chatService.genererIdConversation(
          widget.utilisateurCourant.id,
          widget.autreUtilisateur.id,
          role1: _currentRole,
          role2: _otherRole,
          context: widget.conversationContext,
        );

    _chatService.verifierOuCreerConversation(
      _idConversation,
      [widget.utilisateurCourant.id, widget.autreUtilisateur.id],
      participantRoles: {
        widget.utilisateurCourant.id: _currentRole,
        widget.autreUtilisateur.id: _otherRole,
      },
      participantNames: {
        widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
        widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
      },
      participantPhotos: {
        widget.utilisateurCourant.id: widget.utilisateurCourant.safePhotoUrl,
        widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
      },
      context: widget.conversationContext,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _defilerVersBas(anime: false);
      _chatService.marquerMessagesLus(
        _idConversation,
        widget.utilisateurCourant.id,
      );
    });
  }

  void _ecouteurDefilement() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 100) {
      if (!_montrerBoutonDefilementBas) {
        setState(() => _montrerBoutonDefilementBas = true);
      }
    } else {
      if (_montrerBoutonDefilementBas) {
        setState(() => _montrerBoutonDefilementBas = false);
      }
    }
  }

  Future<void> _defilerVersBas({bool anime = true}) async {
    if (!_scrollController.hasClients) return;

    await _scrollController.scrollToIndex(
      0,
      duration: anime ? const Duration(milliseconds: 300) : Duration.zero,
      preferPosition: AutoScrollPosition.end,
    );
  }

  Future<void> _envoyerMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _envoiEnCours = true);
    try {
      await _chatService.envoyerMessage(
        idConversation: _idConversation,
        idDestinataire: widget.autreUtilisateur.id,
        contenu: message,
        type: TypeMessage.texte,
        nomExpediteur: widget.utilisateurCourant.displayName,
        imageExpediteur: widget.utilisateurCourant.photoUrl,
        senderRole: _currentRole,
        receiverRole: _otherRole,
        context: widget.conversationContext,
        participantNames: {
          widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
          widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
        },
        participantPhotos: {
          widget.utilisateurCourant.id: widget.utilisateurCourant.safePhotoUrl,
          widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
        },
      );
      _messageController.clear();
      _defilerVersBas();
      _resetTypingIndicator();
    } catch (e) {
      _montrerErreurSnackbar('Échec de l\'envoi: $e');
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  void _resetTypingIndicator() {
    _typingTimer?.cancel();
    _chatService.mettreAJourStatutSaisie(
      _idConversation,
      widget.utilisateurCourant.id,
      false,
    );
  }

  Future<void> _envoyerImage() async {
    setState(() => _envoiEnCours = true);
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _chatService.envoyerImage(
          idConversation: _idConversation,
          idDestinataire: widget.autreUtilisateur.id,
          image: File(image.path),
          nomExpediteur: widget.utilisateurCourant.displayName,
          imageExpediteur: widget.utilisateurCourant.photoUrl,
          senderRole: _currentRole,
          receiverRole: _otherRole,
          context: widget.conversationContext,
          participantNames: {
            widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
            widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
          },
          participantPhotos: {
            widget.utilisateurCourant.id:
                widget.utilisateurCourant.safePhotoUrl,
            widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
          },
        );
        _defilerVersBas();
      }
    } catch (e) {
      _montrerErreurSnackbar('Échec d\'envoi de l\'image: $e');
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _envoyerVideo() async {
    setState(() => _envoiEnCours = true);
    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        final file = File(video.path);
        final videoUrl = await _uploaderFichier(file, 'videos');
        await _chatService.envoyerMessage(
          idConversation: _idConversation,
          idDestinataire: widget.autreUtilisateur.id,
          contenu: videoUrl,
          type: TypeMessage.video,
          nomExpediteur: widget.utilisateurCourant.displayName,
          imageExpediteur: widget.utilisateurCourant.photoUrl,
          senderRole: _currentRole,
          receiverRole: _otherRole,
          context: widget.conversationContext,
          participantNames: {
            widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
            widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
          },
          participantPhotos: {
            widget.utilisateurCourant.id:
                widget.utilisateurCourant.safePhotoUrl,
            widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
          },
          metadonnees: {
            'nomFichier': video.name,
            'taille': await file.length(),
          },
        );
        _defilerVersBas();
      }
    } catch (e) {
      _montrerErreurSnackbar('Échec d\'envoi de la vidéo: $e');
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  void _jouerAudio(String url, int index) async {
    if (_lectureAudioEnCours && _indexAudioEnLecture == index) {
      await _audioPlayer.stop();
      setState(() {
        _lectureAudioEnCours = false;
        _indexAudioEnLecture = null;
      });
      return;
    }

    if (_lectureAudioEnCours) await _audioPlayer.stop();

    setState(() {
      _lectureAudioEnCours = true;
      _indexAudioEnLecture = index;
    });

    await _audioPlayer.play(UrlSource(url));
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          _lectureAudioEnCours = false;
          _indexAudioEnLecture = null;
        });
      }
    });
  }

  void _montrerImagePleinEcran(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
    );
  }

  void _ouvrirLecteurVideo(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  Future<void> _ouvrirDocument(String fileUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = fileUrl.split('/').last;
      final file = File('${tempDir.path}/$fileName');

      if (!await file.exists()) {
        await Future.delayed(const Duration(seconds: 1));
        await file.writeAsString('Contenu du document');
      }
      await OpenFile.open(file.path);
    } catch (e) {
      _montrerErreurSnackbar('Échec d\'ouverture: $e');
    }
  }

  String _formaterTailleFichier(int bytes) {
    if (bytes <= 0) return "0 o";
    const suffixes = ["o", "Ko", "Mo", "Go"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _montrerErreurSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _construireBulleMessage(DocumentSnapshot doc, int index) {
    final message = Message.fromMap(doc.data() as Map<String, dynamic>);
    final estMoi = message.idExpediteur == widget.utilisateurCourant.id;
    final estDernier = index == 0;

    return AutoScrollTag(
      key: ValueKey(doc.id),
      controller: _scrollController,
      index: index,
      child: Padding(
        padding: EdgeInsets.only(top: 8, bottom: estDernier ? 16 : 8),
        child: GestureDetector(
          onLongPress: () => _ouvrirActionsMessage(message),
          child: Align(
            alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!estMoi && estDernier)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: CachedNetworkImageProvider(
                        widget.autreUtilisateur.safePhotoUrl,
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estMoi ? widget.primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            estMoi
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                        bottomRight:
                            estMoi
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!estMoi && !estDernier)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.nomExpediteur ?? 'Inconnu',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color:
                                    estMoi ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ),
                        _construireContenuMessage(message, estMoi, index),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat.Hm().format(
                                message.horodatage.toDate(),
                              ),
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    estMoi ? Colors.white70 : Colors.grey[500],
                              ),
                            ),
                            if (estMoi) ...[
                              const SizedBox(width: 6),
                              Icon(
                                message.statut == MessageStatut.lu
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 12,
                                color:
                                    message.statut == MessageStatut.lu
                                        ? Colors.blue[100]
                                        : Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construireContenuMessage(Message message, bool estMoi, int index) {
    if (message.isDeleted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 16,
            color: estMoi ? Colors.white70 : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            'Message supprimé',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: estMoi ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      );
    }
    switch (message.type) {
      case TypeMessage.image:
        return GestureDetector(
          onTap: () => _montrerImagePleinEcran(message.contenu),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.contenu,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder:
                  (_, _) => Container(
                    color: Colors.grey[300],
                    width: 200,
                    height: 200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (_, _, _) => Container(
                    color: Colors.grey[300],
                    width: 200,
                    height: 200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
            ),
          ),
        );

      case TypeMessage.video:
        final miniatureVideo = _obtenirMiniatureVideo(message.contenu);
        return GestureDetector(
          onTap: () => _ouvrirLecteurVideo(message.contenu),
          child: Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      miniatureVideo == null
                          ? const _VideoThumbnailFallback()
                          : CachedNetworkImage(
                            imageUrl: miniatureVideo,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, _) => const _VideoThumbnailFallback(),
                            errorWidget:
                                (_, _, _) => const _VideoThumbnailFallback(),
                          ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VIDÉO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case TypeMessage.audio:
        final duration =
            message.metadonnees?['duree'] != null
                ? Duration(seconds: message.metadonnees!['duree'])
                : const Duration(seconds: 0);

        return GestureDetector(
          onTap: () => _jouerAudio(message.contenu, index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: estMoi ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _lectureAudioEnCours && _indexAudioEnLecture == index
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 24,
                  color: estMoi ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Text(
                  '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: estMoi ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_lectureAudioEnCours && _indexAudioEnLecture == index)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          estMoi ? Colors.white : widget.primaryColor,
                        ),
                        backgroundColor: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

      case TypeMessage.document:
        return GestureDetector(
          onTap: () => _ouvrirDocument(message.contenu),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: estMoi ? Colors.white24 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 40,
                  color: estMoi ? Colors.white : widget.primaryColor,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.metadonnees?['nomFichier'] ?? 'Document',
                      style: TextStyle(
                        color: estMoi ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formaterTailleFichier(
                        message.metadonnees?['taille'] ?? 0,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: estMoi ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case TypeMessage.produit:
        return _construireApercuProduit(message.metadonnees ?? {}, estMoi);

      case TypeMessage.localisation:
        final lat = message.metadonnees?['latitude'] ?? 0.0;
        final lng = message.metadonnees?['longitude'] ?? 0.0;
        return _construireApercuLocalisation(lat, lng, estMoi);

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.contenu,
              style: TextStyle(
                fontSize: 16,
                color: estMoi ? Colors.white : Colors.black,
              ),
            ),
            if (message.isEdited)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'modifié',
                  style: TextStyle(
                    fontSize: 10,
                    color: estMoi ? Colors.white70 : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
    }
  }

  Widget _construireApercuProduit(
    Map<String, dynamic> metadonnees,
    bool estMoi,
  ) {
    return GestureDetector(
      onTap: () => _montrerDetailsProduit(metadonnees),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: estMoi ? Colors.white24 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: metadonnees['imageUrl'] ?? '',
                height: 150,
                fit: BoxFit.cover,
                placeholder:
                    (_, _) => Container(
                      color: Colors.grey[300],
                      height: 150,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadonnees['nom'] ?? 'Produit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: estMoi ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${metadonnees['prix']?.toStringAsFixed(2) ?? '0.00'} €',
                    style: TextStyle(
                      color: estMoi ? Colors.amber : widget.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _montrerDetailsProduit(metadonnees),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          estMoi ? Colors.white : widget.primaryColor,
                      side: BorderSide(
                        color: estMoi ? Colors.white : widget.primaryColor,
                      ),
                    ),
                    child: const Text('Voir le produit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireApercuLocalisation(double lat, double lng, bool estMoi) {
    const apiKey = 'VOTRE_CLE_API_GOOGLE_MAPS';
    final staticMapUrl =
        "https://maps.googleapis.com/maps/api/staticmap?"
        "center=$lat,$lng"
        "&zoom=15"
        "&size=300x150"
        "&markers=color:red%7C$lat,$lng"
        "&key=$apiKey";

    return GestureDetector(
      onTap: () => _ouvrirMaps(lat, lng),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Localisation partagée',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: estMoi ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: staticMapUrl,
              width: 250,
              height: 150,
              fit: BoxFit.cover,
              placeholder:
                  (_, _) => Container(
                    color: Colors.grey[300],
                    width: 250,
                    height: 150,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez pour ouvrir dans Maps',
            style: TextStyle(
              fontSize: 12,
              color: estMoi ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String? _obtenirMiniatureVideo(String videoUrl) {
    if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
      final videoId = _extraireIdYouTube(videoUrl);
      if (videoId == null || videoId.isEmpty) return null;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
    return null;
  }

  String? _extraireIdYouTube(String url) {
    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=)([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match != null && match.groupCount >= 2 ? match.group(2) : null;
  }

  void _montrerDetailsProduit(Map<String, dynamic> donneesProduit) {
    final produit = Produit.fromMap(donneesProduit);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductDetailScreen(
              produit: produit,
              onOrder: () => _preparerCommandeDepuisProduit(produit),
            ),
      ),
    );
  }

  void _preparerCommandeDepuisProduit(Produit produit) {
    Navigator.pop(context);
    _messageController.text =
        'Bonjour, je suis intéressé(e) par "${produit.nom}". Est-ce toujours disponible ?';
    _focusNode.requestFocus();
  }

  void _ouvrirProfilInterlocuteur() {
    final user = widget.autreUtilisateur;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                user.isCreator
                    ? CreateurProfileScreen(userId: user.id)
                    : ClientProfileScreen(userId: user.id),
      ),
    );
  }

  Future<void> _ouvrirMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _montrerErreurSnackbar('Impossible d\'ouvrir Maps');
    }
  }

  Widget _construireZoneSaisie() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _construireBoutonPlus(),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Écrivez un message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (text) {
                          _typingTimer?.cancel();
                          _chatService.mettreAJourStatutSaisie(
                            _idConversation,
                            widget.utilisateurCourant.id,
                            text.isNotEmpty,
                          );

                          _typingTimer = Timer(const Duration(seconds: 3), () {
                            _chatService.mettreAJourStatutSaisie(
                              _idConversation,
                              widget.utilisateurCourant.id,
                              false,
                            );
                          });
                        },
                      ),
                    ),
                    if (_enregistrementAudioEnCours)
                      _construireIndicateurEnregistrement(),
                    if (!_enregistrementAudioEnCours)
                      IconButton(
                        icon: Icon(Icons.mic, color: widget.primaryColor),
                        onPressed: _basculerEnregistrementAudio,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _construireBoutonEnvoi(),
          ],
        ),
      ),
    );
  }

  Widget _construireCarteContexte() {
    final contextData = widget.conversationContext;
    if (!contextData.hasContent) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                contextData.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: contextData.imageUrl,
                      fit: BoxFit.cover,
                    )
                    : Icon(
                      _contextIcon(contextData.type),
                      color: widget.primaryColor,
                    ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _contextLabel(contextData.type),
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                Text(
                  contextData.title.isEmpty
                      ? 'Conversation ${_contextLabel(contextData.type).toLowerCase()}'
                      : contextData.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (contextData.subtitle.isNotEmpty)
                  Text(
                    contextData.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireReponsesRapides() {
    final replies = _quickRepliesForRole(
      _currentRole,
      widget.conversationContext.type,
    );
    if (replies.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = replies[index];
          return ActionChip(
            avatar: Icon(
              Icons.reply_rounded,
              size: 16,
              color: widget.primaryColor,
            ),
            label: Text(reply),
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade200),
            onPressed:
                () => setState(() {
                  _messageController.text = reply;
                  _messageController.selection = TextSelection.collapsed(
                    offset: reply.length,
                  );
                }),
          );
        },
      ),
    );
  }

  List<String> _quickRepliesForRole(String role, String contextType) {
    if (contextType == ConversationContextTypes.secondhand) {
      return const [
        'La pièce est-elle disponible ?',
        'Je peux la réserver ?',
        'Où peut-on se retrouver ?',
      ];
    }
    if (role == 'boutique') {
      return const [
        'Produit disponible',
        'Envoyez la preuve de paiement',
        'Commande confirmée',
      ];
    }
    if (role == 'createur') {
      return const [
        'Je peux le réaliser',
        'Envoyez vos mensurations',
        'Proposons un RDV',
      ];
    }
    return const [
      'Je suis intéressé',
      'Quel est le délai ?',
      'Puis-je personnaliser ?',
    ];
  }

  IconData _contextIcon(String type) {
    return switch (type) {
      ConversationContextTypes.product => AppIcons.shop,
      ConversationContextTypes.creation => AppIcons.creations,
      ConversationContextTypes.secondhand => Icons.recycling_rounded,
      ConversationContextTypes.order => Icons.receipt_long_rounded,
      ConversationContextTypes.appointment => Icons.event_rounded,
      ConversationContextTypes.measurement => Icons.straighten_rounded,
      ConversationContextTypes.support => Icons.support_agent_rounded,
      _ => Icons.chat_bubble_rounded,
    };
  }

  String _contextLabel(String type) {
    return switch (type) {
      ConversationContextTypes.product => 'Produit',
      ConversationContextTypes.creation => 'Création',
      ConversationContextTypes.secondhand => 'Vide-dressing',
      ConversationContextTypes.order => 'Commande',
      ConversationContextTypes.appointment => 'Rendez-vous',
      ConversationContextTypes.measurement => 'Mensurations',
      ConversationContextTypes.support => 'Support',
      _ => 'Discussion',
    };
  }

  Widget _construireBoutonPlus() {
    return GestureDetector(
      onTap: _montrerMenuFichiers,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: widget.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _construireBoutonEnvoi() {
    if (_envoiEnCours) {
      return Container(
        margin: const EdgeInsets.all(4),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: _envoyerMessage,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: widget.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _construireIndicateurEnregistrement() {
    return Expanded(
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.mic, color: Colors.red[400]),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: _recordingAmplitude,
                min: 0,
                max: 1,
                activeColor: Colors.red[400],
                inactiveColor: Colors.grey[300],
                onChanged: null,
              ),
            ),
          ),
          Text(
            '${_calculateRecordingDuration().inSeconds}s',
            style: TextStyle(color: Colors.grey[600]),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: _annulerEnregistrementAudio,
          ),
        ],
      ),
    );
  }

  Duration _calculateRecordingDuration() {
    return DateTime.now().difference(_recordingStartTime ?? DateTime.now());
  }

  Future<void> _basculerEnregistrementAudio() async {
    if (_enregistrementAudioEnCours) {
      setState(() {
        _enregistrementAudioEnCours = false;
        _recordingTimer?.cancel();
      });
      await _enregistreurAudio?.stopRecorder();
      if (_cheminFichierAudio != null) {
        await _envoyerFichierAudio(_cheminFichierAudio!);
      }
      return;
    }

    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
      return;
    }

    final ready = await _initialiserEnregistreurAudio();
    if (!ready) {
      _montrerErreurSnackbar('Micro indisponible pour le moment');
      return;
    }

    setState(() {
      _enregistrementAudioEnCours = true;
      _recordingStartTime = DateTime.now();
      _recordingAmplitude = 0.0;
    });

    _demarrerTimerEnregistrement();

    final tempDir = await getTemporaryDirectory();
    _cheminFichierAudio =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

    await _enregistreurAudio?.startRecorder(
      toFile: _cheminFichierAudio,
      codec: Codec.aacADTS,
    );
  }

  Future<void> _annulerEnregistrementAudio() async {
    _recordingTimer?.cancel();
    if (mounted) {
      setState(() => _enregistrementAudioEnCours = false);
    } else {
      _enregistrementAudioEnCours = false;
    }
    await _enregistreurAudio?.stopRecorder();
  }

  void _demarrerTimerEnregistrement() {
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      setState(() {
        _recordingAmplitude = 0.1 + Random().nextDouble() * 0.8;
      });
    });
  }

  Future<void> _envoyerFichierAudio(String cheminFichier) async {
    setState(() => _envoiEnCours = true);
    try {
      final fichierAudio = File(cheminFichier);
      final audioUrl = await _uploaderFichier(fichierAudio, 'audios');

      await _chatService.envoyerMessage(
        idConversation: _idConversation,
        idDestinataire: widget.autreUtilisateur.id,
        contenu: audioUrl,
        type: TypeMessage.audio,
        nomExpediteur: widget.utilisateurCourant.displayName,
        imageExpediteur: widget.utilisateurCourant.photoUrl,
        metadonnees: {'duree': _calculateRecordingDuration().inSeconds},
        senderRole: _currentRole,
        receiverRole: _otherRole,
        context: widget.conversationContext,
      );
      _defilerVersBas();
    } catch (e) {
      _montrerErreurSnackbar('Échec d\'envoi audio: $e');
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  Future<String> _uploaderFichier(File file, String dossier) async {
    try {
      final upload = await _mediaUploadService.uploadFile(
        file: file,
        folder: 'messages/${widget.utilisateurCourant.id}/$dossier',
        publicId: '${DateTime.now().millisecondsSinceEpoch}',
      );
      await MediaAssetService().recordUpload(
        upload: upload,
        ownerId: widget.utilisateurCourant.id,
        ownerRole: 'client',
        usage: 'message_$dossier',
        status: 'private',
        linkedCollection: 'conversations',
      );
      return upload.resourceType == 'image' ? upload.optimizedUrl : upload.url;
    } catch (e) {
      throw Exception('Échec de l\'upload: $e');
    }
  }

  Future<void> _envoyerDocument() async {
    setState(() => _envoiEnCours = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'xlsx', 'pptx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final selectedFile = result.files.single;
        final filePath = selectedFile.path;

        if (filePath == null) {
          _montrerErreurSnackbar('Fichier invalide ou introuvable.');
          return;
        }

        final file = File(filePath);
        final fileSize = selectedFile.size;

        final fileUrl = await _uploaderFichier(file, 'documents');

        await _chatService.envoyerMessage(
          idConversation: _idConversation,
          idDestinataire: widget.autreUtilisateur.id,
          contenu: fileUrl,
          type: TypeMessage.document,
          nomExpediteur: widget.utilisateurCourant.displayName,
          imageExpediteur: widget.utilisateurCourant.photoUrl,
          metadonnees: {'nomFichier': selectedFile.name, 'taille': fileSize},
          senderRole: _currentRole,
          receiverRole: _otherRole,
          context: widget.conversationContext,
          participantNames: {
            widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
            widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
          },
          participantPhotos: {
            widget.utilisateurCourant.id:
                widget.utilisateurCourant.safePhotoUrl,
            widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
          },
        );

        _defilerVersBas();
      }
    } catch (e) {
      _montrerErreurSnackbar("Échec de l'envoi du document : $e");
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _envoyerProduit() async {
    final produit = Produit(
      id: 'prod123',
      nom: 'Smartphone Premium',
      prix: 799.99,
      imageUrl: 'https://example.com/smartphone.jpg',
      description: 'Dernier modèle avec écran 120Hz et triple caméra',
      quantiteDisponible: 10,
      dateCreation: DateTime.now(),
    );

    setState(() => _envoiEnCours = true);
    try {
      await _chatService.envoyerProduit(
        idConversation: _idConversation,
        idDestinataire: widget.autreUtilisateur.id,
        produit: produit,
        nomExpediteur: widget.utilisateurCourant.displayName,
        imageExpediteur: widget.utilisateurCourant.photoUrl,
        senderRole: _currentRole,
        receiverRole: _otherRole,
        context: widget.conversationContext,
        participantNames: {
          widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
          widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
        },
        participantPhotos: {
          widget.utilisateurCourant.id: widget.utilisateurCourant.safePhotoUrl,
          widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
        },
      );
      _defilerVersBas();
    } catch (e) {
      _montrerErreurSnackbar('Échec d\'envoi produit: $e');
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _envoyerLocalisation() async {
    setState(() => _envoiEnCours = true);
    try {
      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }

      if (await Permission.location.isGranted) {
        _positionActuelle = await Geolocator.getCurrentPosition();

        await _chatService.envoyerLocalisation(
          idConversation: _idConversation,
          idDestinataire: widget.autreUtilisateur.id,
          latitude: _positionActuelle!.latitude,
          longitude: _positionActuelle!.longitude,
          nomExpediteur: widget.utilisateurCourant.displayName,
          imageExpediteur: widget.utilisateurCourant.photoUrl,
          senderRole: _currentRole,
          receiverRole: _otherRole,
          context: widget.conversationContext,
          participantNames: {
            widget.utilisateurCourant.id: widget.utilisateurCourant.mainName,
            widget.autreUtilisateur.id: widget.autreUtilisateur.mainName,
          },
          participantPhotos: {
            widget.utilisateurCourant.id:
                widget.utilisateurCourant.safePhotoUrl,
            widget.autreUtilisateur.id: widget.autreUtilisateur.safePhotoUrl,
          },
        );
        _defilerVersBas();
      }
    } catch (e) {
      _montrerErreurSnackbar('Échec d\'envoi localisation: $e');
    } finally {
      setState(() => _envoiEnCours = false);
    }
  }

  void _montrerMenuFichiers() {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Wrap(
                    children: [
                      _construireOptionFichier(
                        icone: Icons.photo,
                        libelle: 'Galerie',
                        couleur: Colors.blue,
                        onTap: _envoyerImage,
                      ),
                      _construireOptionFichier(
                        icone: Icons.videocam,
                        libelle: 'Vidéo',
                        couleur: Colors.purple,
                        onTap: _envoyerVideo,
                      ),
                      _construireOptionFichier(
                        icone: Icons.insert_drive_file,
                        libelle: 'Document',
                        couleur: Colors.orange,
                        onTap: _envoyerDocument,
                      ),
                      _construireOptionFichier(
                        icone: AppIcons.shop,
                        libelle: 'Produit',
                        couleur: Colors.teal,
                        onTap: _envoyerProduit,
                      ),
                      _construireOptionFichier(
                        icone: Icons.location_on,
                        libelle: 'Localisation',
                        couleur: Colors.red,
                        onTap: _envoyerLocalisation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  Widget _construireOptionFichier({
    required IconData icone,
    required Color couleur,
    required String libelle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 4,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: couleur, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                libelle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construireIndicateurSaisie() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('conversations')
              .doc(_idConversation)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final typingMap = data['saisieEnCours'] as Map<String, dynamic>? ?? {};
        final saisieEnCours = typingMap[widget.autreUtilisateur.id] ?? false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: saisieEnCours ? 30 : 0,
          child:
              saisieEnCours
                  ? Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: CachedNetworkImageProvider(
                                  widget.autreUtilisateur.safePhotoUrl,
                                ),
                              ),
                              const Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 6,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.autreUtilisateur.displayName} écrit...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _construireMessagesChargement() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final estMoi = index % 3 == 0;
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  estMoi
                      ? widget.primaryColor.withValues(alpha: 0.2)
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!estMoi)
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(width: 80, height: 10, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  void _montrerDialogueViderHistorique() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Vider l\'historique'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer tous les messages de cette conversation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  _chatService.effacerHistoriqueChat(_idConversation);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _archiverConversation() async {
    await _chatService.archiverConversation(
      _idConversation,
      widget.utilisateurCourant.id,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _bloquerConversation() async {
    await _chatService.bloquerConversation(
      _idConversation,
      widget.utilisateurCourant.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Conversation bloquée')));
    Navigator.pop(context);
  }

  Future<void> _modifierMessage(Message message) async {
    final controller = TextEditingController(text: message.contenu);
    final updated = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier le message'),
            content: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Message',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (updated == null || updated.isEmpty || updated == message.contenu) {
      return;
    }
    await _chatService.modifierMessage(messageId: message.id, contenu: updated);
  }

  Future<void> _supprimerMessage(Message message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le message ?'),
            content: const Text(
              'Le message sera retiré de la conversation, avec une trace de suppression.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _chatService.supprimerMessage(message.id);
    }
  }

  void _ouvrirActionsMessage(Message message) {
    final estMoi = message.idExpediteur == widget.utilisateurCourant.id;
    if (!estMoi || message.isDeleted || message.type != TypeMessage.texte) {
      return;
    }
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Modifier'),
                  onTap: () {
                    Navigator.pop(context);
                    _modifierMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Supprimer',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _supprimerMessage(message);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back, color: Colors.black),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(
                  widget.autreUtilisateur.safePhotoUrl,
                ),
              ),
            ],
          ),
        ),
        title: InkWell(
          onTap: _ouvrirProfilInterlocuteur,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.autreUtilisateur.mainName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _autreUtilisateurEnLigne ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _autreUtilisateurEnLigne
                        ? 'En ligne maintenant'
                        : _derniereConnexion != null
                        ? 'Vu à ${DateFormat.Hm().format(_derniereConnexion!)}'
                        : 'Hors ligne',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(Icons.archive_outlined),
                      title: Text('Archiver'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text(
                        'Vider l’historique',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      leading: Icon(Icons.block, color: Colors.red),
                      title: Text(
                        'Bloquer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
            onSelected: (value) {
              if (value == 'archive') _archiverConversation();
              if (value == 'clear') _montrerDialogueViderHistorique();
              if (value == 'block') _bloquerConversation();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          image: const DecorationImage(
            image: NetworkImage(
              'https://www.transparenttextures.com/patterns/light-wool.png',
            ),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: Column(
          children: [
            _construireCarteContexte(),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _chatService.streamMessages(
                        _idConversation,
                        limit: _messagesPageSize,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint(
                            'Erreur chargement messages: ${snapshot.error}',
                          );
                          return const Center(
                            child: Text('Messages indisponibles.'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _construireMessagesChargement();
                        }

                        final messages = snapshot.data?.docs ?? [];

                        if (messages.isEmpty) {
                          return const Center(
                            child: Text('Envoyez votre premier message'),
                          );
                        }

                        return Column(
                          children: [
                            if (messages.length >= _messagesPageSize)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  4,
                                ),
                                child: Text(
                                  'Les $_messagesPageSize derniers messages sont affichés pour garder la discussion fluide.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                reverse: true,
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  return _construireBulleMessage(
                                    messages[index],
                                    messages.length - 1 - index,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    if (_montrerBoutonDefilementBas)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton(
                          heroTag: null,
                          backgroundColor: Colors.white,
                          mini: true,
                          onPressed: _defilerVersBas,
                          child: Icon(
                            Icons.arrow_downward,
                            color: widget.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            _construireIndicateurSaisie(),

            _construireReponsesRapides(),

            _construireZoneSaisie(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatService.mettreAJourPresence(widget.utilisateurCourant.id, false);
    _audioPlayer.dispose();
    _enregistreurAudio?.closeRecorder();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }
}

class _VideoThumbnailFallback extends StatelessWidget {
  const _VideoThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      color: Colors.black26,
      child: const Center(
        child: Icon(Icons.videocam_rounded, color: Colors.white70, size: 34),
      ),
    );
  }
}

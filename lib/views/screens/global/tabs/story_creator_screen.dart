import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

class StoryCreatorScreen extends StatefulWidget {
  @override
  _StoryCreatorScreenState createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends State<StoryCreatorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseStoryService _storyService = FirebaseStoryService();

  File? _selectedMedia;
  bool _isLoading = false;
  bool _isTextOnly = false;
  bool _isEditing = false;
  bool _showStyleOptions = false;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  // Style du texte
  Color _textColor = Colors.white;
  Color _backgroundColor = Color(0xFFE53E3E);
  double _fontSize = 28.0;
  FontWeight _fontWeight = FontWeight.bold;
  TextAlign _textAlign = TextAlign.center;
  String _fontFamily = 'Roboto';
  Offset _textPosition = Offset(0, 0);
  double _textScale = 1.0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Color> _backgroundGradients = [
    Color(0xFFE53E3E), // Rouge
    Color(0xFF3182CE), // Bleu
    Color(0xFF38A169), // Vert
    Color(0xFFD69E2E), // Orange
    Color(0xFF805AD5), // Violet
    Color(0xFFE91E63), // Rose
    Color(0xFF00BCD4), // Cyan
    Color(0xFF4CAF50), // Vert clair
  ];

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Colors.yellow,
    Color(0xFF00FF00),
    Color(0xFFFF00FF),
  ];

  final List<String> _fontFamilies = [
    'Roboto',
    'OpenSans',
    'Lato',
    'Montserrat',
    'Pacifico',
    'DancingScript',
    'Oswald',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Démarrer le timer de nettoyage
    _storyService.startCleanupTimer();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _animationController.dispose();
    _fadeController.dispose();
    _videoController?.dispose();
    _storyService.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool isVideo) async {
    final media = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (media != null) {
      setState(() {
        _selectedMedia = File(media.path);
        _isTextOnly = false;
        _isEditing = false;
        _isVideo = isVideo;

        if (isVideo) {
          _videoController = VideoPlayerController.file(_selectedMedia!)
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
            });
        }
      });
    }
  }

  Future<void> _takeMedia(bool isVideo) async {
    final media = isVideo
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (media != null) {
      setState(() {
        _selectedMedia = File(media.path);
        _isTextOnly = false;
        _isEditing = false;
        _isVideo = isVideo;

        if (isVideo) {
          _videoController = VideoPlayerController.file(_selectedMedia!)
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
            });
        }
      });
    }
  }

  void _toggleTextOnly() {
    setState(() {
      _isTextOnly = !_isTextOnly;
      _isEditing = _isTextOnly;
      if (_isTextOnly) {
        _selectedMedia = null;
        _videoController?.dispose();
        _videoController = null;
        _showStyleOptions = true;
        _fadeController.forward();
      }
    });
  }

  void _toggleStyleOptions() {
    setState(() {
      _showStyleOptions = !_showStyleOptions;
      if (_showStyleOptions) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    });
  }

  void _resetTextPosition() {
    setState(() {
      _textPosition = Offset(0, 0);
      _textScale = 1.0;
    });
  }

  Future<void> _publishStory() async {
    if (_captionController.text.trim().isEmpty && _selectedMedia == null) {
      _showSnackBar('Veuillez ajouter du contenu à votre story', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _animationController.forward();

    Map<String, dynamic>? textStyle;
    if (_isTextOnly) {
      textStyle = {
        'textColor': _textColor.value,
        'backgroundColor': _backgroundColor.value,
        'fontSize': _fontSize,
        'fontWeight': _fontWeight.index,
        'textAlign': _textAlign.index,
        'fontFamily': _fontFamily,
        'positionX': _textPosition.dx,
        'positionY': _textPosition.dy,
        'scale': _textScale,
      };
    }

    final success = await _storyService.createStory(
      mediaFile: _selectedMedia,
      isVideo: _isVideo,
      caption: _captionController.text.trim(),
      textStyle: textStyle,
    );

    _animationController.reverse();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showSnackBar('Story publiée avec succès!', Colors.green);
      Navigator.pop(context, true);
    } else {
      _showSnackBar('Erreur lors de la publication', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu principal
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isEditing = false;
                      _showStyleOptions = false;
                      if (_showStyleOptions) _fadeController.reverse();
                    }),
                    child: _buildContent(),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),

            // Options de style
            if (_showStyleOptions) _buildFloatingStyleOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),

          Text(
            'Nouvelle Story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTap: _publishStory,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE53E3E), Color(0xFFECC94B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE53E3E).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'Publier',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _isTextOnly ? _backgroundColor : Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond ou média
            if (_selectedMedia != null && !_isVideo) ...[
              Image.file(
                _selectedMedia!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ]
            else if (_selectedMedia != null && _isVideo) ...[
              if (_videoController != null && _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else
                Center(child: CircularProgressIndicator()),
            ]
            else if (_isTextOnly) ...[
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _backgroundColor,
                        _backgroundColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 80,
                          color: Colors.white.withOpacity(0.5)),
                      SizedBox(height: 16),
                      Text(
                        'Ajoutez un média ou créez une story texte',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

            // Zone de texte
            if (_isEditing)
              _buildTextEditor()
            else if (_captionController.text.isNotEmpty || _isTextOnly)
              _buildTextPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return Positioned(
      left: _textPosition.dx,
      top: _textPosition.dy,
      child: GestureDetector(
        // SUPPRIMER onPanUpdate
        onScaleUpdate: (details) {
          setState(() {
            // Gestion combinée du déplacement et zoom
            _textPosition += details.focalPointDelta;
            _textScale = (_textScale * details.scale).clamp(0.5, 3.0);
          });
        },
        child: Transform.scale(
          scale: _textScale,
          child: Container(
            padding: EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: TextField(
                controller: _captionController,
                autofocus: true,
                maxLines: null,
                maxLength: 200,
                style: TextStyle(
                  color: _textColor,
                  fontSize: _fontSize,
                  fontWeight: _fontWeight,
                  fontFamily: _fontFamily,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black.withOpacity(0.9),
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
                textAlign: _textAlign,
                decoration: InputDecoration(
                  hintText: _isTextOnly ? 'Votre message...' : 'Ajoutez une légende...',
                  hintStyle: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    return Positioned(
      left: _textPosition.dx,
      top: _textPosition.dy,
      child: GestureDetector(
        onTap: () => setState(() {
          _isEditing = true;
          _showStyleOptions = true;
          _fadeController.forward();
        }),
        // SUPPRIMER onPanUpdate
        onScaleUpdate: (details) {
          setState(() {
            // Gestion combinée du déplacement et zoom
            _textPosition += details.focalPointDelta;
            _textScale = (_textScale * details.scale).clamp(0.5, 3.0);
          });
        },
        child: Transform.scale(
          scale: _textScale,
          child: Container(
            padding: EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 300),
                style: TextStyle(
                  color: _textColor,
                  fontSize: _fontSize,
                  fontWeight: _fontWeight,
                  fontFamily: _fontFamily,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black.withOpacity(0.9),
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
                textAlign: _textAlign,
                child: Text(
                  _captionController.text.isNotEmpty
                      ? _captionController.text
                      : (_isTextOnly
                      ? 'Appuyez pour écrire...'
                      : 'Appuyez pour ajouter du texte...'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Boutons principaux
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () => _pickMedia(false),
                ),
                _buildControlButton(
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  onTap: () => _takeMedia(false),
                ),
                _buildControlButton(
                  icon: Icons.videocam,
                  label: 'Vidéo',
                  onTap: () => _pickMedia(true),
                ),
                _buildControlButton(
                  icon: Icons.text_fields,
                  label: 'Texte',
                  isActive: _isTextOnly,
                  onTap: _toggleTextOnly,
                ),
                _buildControlButton(
                  icon: Icons.style,
                  label: 'Style',
                  isActive: _showStyleOptions,
                  onTap: _toggleStyleOptions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStyleOptions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Options de style',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.restart_alt, color: Colors.white),
                      onPressed: _resetTextPosition,
                      tooltip: 'Réinitialiser position',
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showStyleOptions = false;
                          _fadeController.reverse();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Onglets
            DefaultTabController(
              length: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    indicatorColor: Color(0xFFE53E3E),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Fond'),
                      Tab(text: 'Texte'),
                      Tab(text: 'Police'),
                      Tab(text: 'Alignement'),
                    ],
                  ),

                  SizedBox(height: 16),

                  Container(
                    height: 180,
                    child: TabBarView(
                      children: [
                        // Onglet Fond
                        _buildBackgroundOptions(),

                        // Onglet Texte
                        _buildTextOptions(),

                        // Onglet Police
                        _buildFontOptions(),

                        // Onglet Alignement
                        _buildAlignmentOptions(),
                      ],
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

  Widget _buildBackgroundOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur de fond',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _backgroundGradients.length,
            itemBuilder: (context, index) {
              final color = _backgroundGradients[index];
              return GestureDetector(
                onTap: () => setState(() => _backgroundColor = color),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _backgroundColor == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: _backgroundColor == color
                        ? [
                      BoxShadow(
                        color: color.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur du texte',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _textColors.length,
            itemBuilder: (context, index) {
              final color = _textColors[index];
              return GestureDetector(
                onTap: () => setState(() => _textColor = color),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _textColor == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTextOptionButton(
              icon: Icons.format_size,
              label: 'Grande',
              isActive: _fontSize == 32,
              onTap: () => setState(() => _fontSize = 32),
            ),
            _buildTextOptionButton(
              icon: Icons.format_size,
              label: 'Normale',
              isActive: _fontSize == 24,
              onTap: () => setState(() => _fontSize = 24),
            ),
            _buildTextOptionButton(
              icon: Icons.format_bold,
              label: 'Gras',
              isActive: _fontWeight == FontWeight.bold,
              onTap: () => setState(() => _fontWeight = _fontWeight == FontWeight.bold
                  ? FontWeight.normal
                  : FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontOptions() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: _fontFamilies.length,
      itemBuilder: (context, index) {
        final font = _fontFamilies[index];
        return GestureDetector(
          onTap: () => setState(() => _fontFamily = font),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _fontFamily == font
                  ? Color(0xFFE53E3E).withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _fontFamily == font
                    ? Color(0xFFE53E3E)
                    : Colors.white24,
              ),
            ),
            child: Center(
              child: Text(
                'Aa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: font,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlignmentOptions() {
    return Column(
      children: [
        Text(
          'Alignement du texte',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        SizedBox(height: 16),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            children: [
              _buildAlignmentOption(
                icon: Icons.format_align_left,
                label: 'Gauche',
                alignment: TextAlign.left,
              ),
              _buildAlignmentOption(
                icon: Icons.format_align_center,
                label: 'Centré',
                alignment: TextAlign.center,
              ),
              _buildAlignmentOption(
                icon: Icons.format_align_right,
                label: 'Droite',
                alignment: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlignmentOption({
    required IconData icon,
    required String label,
    required TextAlign alignment,
  }) {
    final isActive = _textAlign == alignment;
    return GestureDetector(
      onTap: () => setState(() => _textAlign = alignment),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFE53E3E).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Color(0xFFE53E3E) : Colors.white24,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white70),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Color(0xFFE53E3E).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Color(0xFFE53E3E) : Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Color(0xFFE53E3E) : Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFFE53E3E).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Color(0xFFE53E3E) : Colors.white24,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FirebaseStoryService {
  static final FirebaseStoryService _instance = FirebaseStoryService._internal();
  factory FirebaseStoryService() => _instance;
  FirebaseStoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Timer pour nettoyer les stories expirées
  Timer? _cleanupTimer;

  void startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(Duration(hours: 1), (timer) {
      _cleanupExpiredStories();
    });
  }

  Future<void> _cleanupExpiredStories() async {
    final now = DateTime.now();
    final expiredStories = await _firestore
        .collection('stories')
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();

    for (final doc in expiredStories.docs) {
      await deleteStory(doc.id);
    }
  }

  Stream<List<Story>> getStoriesStream() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Story.fromFirestore(doc))
        .where((story) => !story.isExpired)
        .toList());
  }

  Future<String?> uploadFile(File file, bool isVideo) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final extension = isVideo ? 'mp4' : 'jpg';
      final ref = _storage
          .ref()
          .child('stories')
          .child(user.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.$extension');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Erreur upload file: $e');
      return null;
    }
  }

  Future<bool> createStory({
    File? mediaFile,
    bool isVideo = false,
    required String caption,
    Map<String, dynamic>? textStyle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      String? mediaUrl;
      if (mediaFile != null) {
        mediaUrl = await uploadFile(mediaFile, isVideo);
      }

      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: 24));

      final story = Story(
        id: '',
        userId: user.uid,
        author: user.displayName ?? 'Utilisateur',
        userPhotoUrl: user.photoURL ?? '',
        mediaUrl: mediaUrl,
        isVideo: isVideo,
        caption: caption,
        likes: [],
        comments: [],
        createdAt: now,
        expiresAt: expiresAt,
        textStyle: textStyle,
      );

      await _firestore.collection('stories').add(story.toFirestore());
      return true;
    } catch (e) {
      print('Erreur création story: $e');
      return false;
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final storyDoc = await _firestore.collection('stories').doc(storyId).get();
      if (!storyDoc.exists) return false;

      final story = Story.fromFirestore(storyDoc);
      if (story.userId != user.uid) return false; // Only owner can delete

      // Delete media from storage if exists
      if (story.mediaUrl != null) {
        try {
          await _storage.refFromURL(story.mediaUrl!).delete();
        } catch (e) {
          print('Erreur suppression media: $e');
        }
      }

      await _firestore.collection('stories').doc(storyId).delete();
      return true;
    } catch (e) {
      print('Erreur suppression story: $e');
      return false;
    }
  }

  Future<bool> toggleLike(String storyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final storyRef = _firestore.collection('stories').doc(storyId);

      return await _firestore.runTransaction((transaction) async {
        final storyDoc = await transaction.get(storyRef);
        if (!storyDoc.exists) return false;

        final story = Story.fromFirestore(storyDoc);
        final likes = List<String>.from(story.likes);

        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
        } else {
          likes.add(user.uid);
        }

        transaction.update(storyRef, {'likes': likes});
        return true;
      });
    } catch (e) {
      print('Erreur toggle like: $e');
      return false;
    }
  }

  Future<bool> addComment(String storyId, String commentText) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        userName: user.displayName ?? 'Utilisateur',
        userPhotoUrl: user.photoURL ?? '',
        text: commentText,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('stories').doc(storyId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()])
      });

      return true;
    } catch (e) {
      print('Erreur ajout commentaire: $e');
      return false;
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }
}

class Story {
  final String id;
  final String userId;
  final String author;
  final String userPhotoUrl;
  final String? mediaUrl;
  final bool isVideo;
  final String caption;
  final List<String> likes;
  final List<Comment> comments;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, dynamic>? textStyle;

  Story({
    required this.id,
    required this.userId,
    required this.author,
    required this.userPhotoUrl,
    this.mediaUrl,
    this.isVideo = false,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.expiresAt,
    this.textStyle,
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      author: data['author'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      mediaUrl: data['mediaUrl'],
      isVideo: data['isVideo'] ?? false,
      caption: data['caption'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>?)
          ?.map((c) => Comment.fromMap(c))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      textStyle: data['textStyle'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'author': author,
      'userPhotoUrl': userPhotoUrl,
      'mediaUrl': mediaUrl,
      'isVideo': isVideo,
      'caption': caption,
      'likes': likes,
      'comments': comments.map((c) => c.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'textStyle': textStyle,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}j';
    }
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
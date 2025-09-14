import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'response_quiz.dart';

class StyleQuizScreen extends StatefulWidget {
  const StyleQuizScreen({super.key});

  @override
  State<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends State<StyleQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _selectedOption = -1;
  Map<String, int> _userProfile = {
    'traditional': 0,
    'modern': 0,
    'casual': 0,
    'formal': 0,
    'colorful': 0,
    'neutral': 0,
  };

  // AJOUT : Variable pour stocker les réponses de l'utilisateur
  List<Map<String, dynamic>> _userAnswers = [];

  late AnimationController _progressController;
  late AnimationController _cardController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;

  bool _isAnswering = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _cardAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _cardController.forward();
    _updateProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _questions = [
    {
      'question': "Dans quelle situation portez-vous généralement vos plus beaux habits ?",
      'subtitle': "Choisissez ce qui vous correspond le mieux",
      'options': [
        {
          'text': "Mariages et cérémonies traditionnelles",
          'profile': {'traditional': 3, 'formal': 2},
          'emoji': '💒',
        },
        {
          'text': "Réunions professionnelles et officielles",
          'profile': {'formal': 3, 'modern': 2},
          'emoji': '💼',
        },
        {
          'text': "Sorties décontractées entre amis",
          'profile': {'casual': 3, 'modern': 1},
          'emoji': '🎉',
        },
        {
          'text': "Événements religieux et spirituels",
          'profile': {'traditional': 2, 'formal': 2},
          'emoji': '🕌',
        }
      ],
    },
    {
      'question': "Quelles couleurs vous attirent le plus ?",
      'subtitle': "Pensez aux couleurs qui vous mettent en valeur",
      'options': [
        {
          'text': "Couleurs vives et éclatantes (rouge, orange, jaune)",
          'profile': {'colorful': 3, 'traditional': 1},
          'emoji': '🌈',
        },
        {
          'text': "Tons terreux et naturels (ocre, brun, beige)",
          'profile': {'traditional': 3, 'neutral': 1},
          'emoji': '🌍',
        },
        {
          'text': "Couleurs douces et pastels",
          'profile': {'neutral': 2, 'modern': 2},
          'emoji': '🌸',
        },
        {
          'text': "Noir, blanc et tons monochromes",
          'profile': {'modern': 3, 'formal': 2},
          'emoji': '⚫',
        }
      ],
    },
    {
      'question': "Comment décririez-vous votre style personnel ?",
      'subtitle': "Soyez authentique dans votre choix",
      'options': [
        {
          'text': "J'aime mélanger traditionnel et moderne",
          'profile': {'traditional': 2, 'modern': 2},
          'emoji': '🎭',
        },
        {
          'text': "Je préfère rester fidèle aux traditions",
          'profile': {'traditional': 3, 'formal': 1},
          'emoji': '👑',
        },
        {
          'text': "J'adore les tendances contemporaines",
          'profile': {'modern': 3, 'colorful': 1},
          'emoji': '✨',
        },
        {
          'text': "Simple et élégant avant tout",
          'profile': {'neutral': 3, 'formal': 1},
          'emoji': '💎',
        }
      ],
    },
    {
      'question': "Quel tissu vous fait vous sentir le mieux ?",
      'subtitle': "Choisissez selon votre confort et vos préférences",
      'options': [
        {
          'text': "Bogolan et tissus traditionnels tissés à la main",
          'profile': {'traditional': 3, 'colorful': 1},
          'emoji': '🧵',
        },
        {
          'text': "Coton léger et respirant",
          'profile': {'casual': 2, 'neutral': 2},
          'emoji': '🌿',
        },
        {
          'text': "Soie et tissus nobles",
          'profile': {'formal': 3, 'modern': 1},
          'emoji': '🎀',
        },
        {
          'text': "Tissus modernes et innovants",
          'profile': {'modern': 3, 'casual': 1},
          'emoji': '🔬',
        }
      ],
    },
    {
      'question': "Quelle importance accordez-vous aux accessoires ?",
      'subtitle': "Dernière question pour affiner votre profil",
      'options': [
        {
          'text': "Bijoux traditionnels en or et perles",
          'profile': {'traditional': 3, 'formal': 1},
          'emoji': '📿',
        },
        {
          'text': "Accessoires modernes et tendance",
          'profile': {'modern': 3, 'colorful': 1},
          'emoji': '👜',
        },
        {
          'text': "Quelques pièces simples et élégantes",
          'profile': {'neutral': 2, 'formal': 1},
          'emoji': '💍',
        },
        {
          'text': "Peu d'accessoires, j'aime la simplicité",
          'profile': {'casual': 2, 'neutral': 1},
          'emoji': '🌟',
        }
      ],
    },
  ];

  void _updateProgress() {
    double targetProgress = (_currentQuestionIndex + 1) / _questions.length;
    _progressController.animateTo(targetProgress);
  }

  void _selectOption(int index) {
    if (_isAnswering) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedOption = index;
    });
  }

  void _nextQuestion() async {
    if (_selectedOption == -1 || _isAnswering) return;

    setState(() {
      _isAnswering = true;
    });

    // MODIFICATION : Sauvegarder la réponse de l'utilisateur
    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedOption = currentQuestion['options'][_selectedOption];

    _userAnswers.add({
      'questionIndex': _currentQuestionIndex,
      'question': currentQuestion['question'],
      'selectedOption': _selectedOption,
      'selectedText': selectedOption['text'],
      'selectedEmoji': selectedOption['emoji'],
    });

    // Mettre à jour le profil utilisateur
    Map<String, int> selectedProfile = selectedOption['profile'];

    selectedProfile.forEach((key, value) {
      _userProfile[key] = (_userProfile[key] ?? 0) + value;
    });

    HapticFeedback.mediumImpact();

    // Animation de sortie
    await _cardController.reverse();

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = -1;
        _isAnswering = false;
      });
      _updateProgress();
      _cardController.forward();
    } else {
      // Naviguer vers les résultats avec le profil utilisateur et les réponses
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              QuizResultsScreen(
                userProfile: _userProfile,
                userAnswers: _userAnswers,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  String _getProgressText() {
    return "${_currentQuestionIndex + 1} sur ${_questions.length}";
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Quiz Style Burkinabé",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A4C93), Color(0xFF8B5A83)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _getProgressText(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression animée
          Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A4C93), Color(0xFF8B5A83)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: AnimatedBuilder(
              animation: _cardAnimation,
              builder: (context, child) {
                double clampedValue = _cardController.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: clampedValue,
                  child: Opacity(
                    opacity: clampedValue,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Color(0xFFFAFAFA)],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question principale
                                Text(
                                  currentQuestion['question'],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentQuestion['subtitle'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Options
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: currentQuestion['options'].length,
                                    itemBuilder: (context, index) {
                                      final option = currentQuestion['options'][index];
                                      return AnimatedContainer(
                                        duration: Duration(
                                          milliseconds: 200 + (index * 100),
                                        ),
                                        curve: Curves.easeOutBack,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        child: OptionCard(
                                          emoji: option['emoji'],
                                          text: option['text'],
                                          isSelected: _selectedOption == index,
                                          onTap: () => _selectOption(index),
                                          animationDelay: index * 100,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bouton suivant
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedOption == -1 || _isAnswering ? null : _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A4C93),
                  foregroundColor: Colors.white,
                  elevation: _selectedOption == -1 ? 0 : 6,
                  shadowColor: const Color(0xFF6A4C93).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isAnswering
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  _currentQuestionIndex == _questions.length - 1
                      ? "DÉCOUVRIR MON STYLE 🎨"
                      : "QUESTION SUIVANTE ➡️",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptionCard extends StatefulWidget {
  final String emoji;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final int animationDelay;

  const OptionCard({
    super.key,
    required this.emoji,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFF6A4C93).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF6A4C93)
                      : Colors.grey.withOpacity(0.3),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF6A4C93).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? const Color(0xFF6A4C93).withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: widget.isSelected
                            ? const Color(0xFF6A4C93)
                            : const Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6A4C93),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
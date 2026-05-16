import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';

class StyleQuizScreen extends StatefulWidget {
  const StyleQuizScreen({super.key});

  @override
  State<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends State<StyleQuizScreen> {
  int _currentIndex = 0;
  int? _selectedIndex;
  final Map<String, int> _scores = {
    'heritage': 0,
    'modern': 0,
    'minimal': 0,
    'expressive': 0,
    'practical': 0,
    'occasion': 0,
    'budget': 0,
    'beauty': 0,
    'bold': 0,
  };
  final List<Map<String, dynamic>> _answers = [];

  static const List<_DiagnosticQuestion> _questions = [
    _DiagnosticQuestion(
      title: 'Ton moment prioritaire ?',
      subtitle: 'Occasion',
      options: [
        _DiagnosticOption(
          label: 'Cérémonie',
          icon: AppIcons.appointments,
          scores: {'heritage': 3, 'occasion': 3, 'expressive': 1},
        ),
        _DiagnosticOption(
          label: 'Bureau',
          icon: Icons.work_rounded,
          scores: {'modern': 2, 'minimal': 2, 'occasion': 2},
        ),
        _DiagnosticOption(
          label: 'Quotidien',
          icon: Icons.weekend_rounded,
          scores: {'practical': 3, 'minimal': 1, 'modern': 1},
        ),
        _DiagnosticOption(
          label: 'Sortie',
          icon: AppIcons.style,
          scores: {'expressive': 3, 'modern': 2, 'bold': 1},
        ),
      ],
    ),
    _DiagnosticQuestion(
      title: 'Ton lien avec les textiles culturels ?',
      subtitle: 'Identité',
      options: [
        _DiagnosticOption(
          label: 'Pièce centrale',
          icon: AppIcons.award,
          scores: {'heritage': 4, 'expressive': 1},
        ),
        _DiagnosticOption(
          label: 'Mix moderne',
          icon: Icons.merge_type_rounded,
          scores: {'heritage': 2, 'modern': 3},
        ),
        _DiagnosticOption(
          label: 'Détail discret',
          icon: Icons.texture_rounded,
          scores: {'heritage': 1, 'minimal': 3},
        ),
        _DiagnosticOption(
          label: 'Confort d’abord',
          icon: Icons.spa_rounded,
          scores: {'practical': 3, 'minimal': 1},
        ),
      ],
    ),
    _DiagnosticQuestion(
      title: 'Ta palette naturelle ?',
      subtitle: 'Couleurs',
      options: [
        _DiagnosticOption(
          label: 'Couleurs fortes',
          icon: AppIcons.style,
          scores: {'expressive': 4, 'heritage': 1, 'bold': 1},
        ),
        _DiagnosticOption(
          label: 'Neutres',
          icon: Icons.contrast_rounded,
          scores: {'minimal': 4, 'modern': 1},
        ),
        _DiagnosticOption(
          label: 'Tons terre',
          icon: Icons.terrain_rounded,
          scores: {'heritage': 2, 'practical': 2},
        ),
        _DiagnosticOption(
          label: 'Doux',
          icon: Icons.water_drop_rounded,
          scores: {'minimal': 2, 'modern': 2},
        ),
      ],
    ),
    _DiagnosticQuestion(
      title: 'Ce qui compte le plus ?',
      subtitle: 'Priorité',
      options: [
        _DiagnosticOption(
          label: 'Coupe',
          icon: Icons.straighten_rounded,
          scores: {'modern': 2, 'minimal': 2, 'occasion': 1},
        ),
        _DiagnosticOption(
          label: 'Histoire',
          icon: Icons.history_edu_rounded,
          scores: {'heritage': 4},
        ),
        _DiagnosticOption(
          label: 'Facile à porter',
          icon: Icons.repeat_rounded,
          scores: {'practical': 4},
        ),
        _DiagnosticOption(
          label: 'Impact',
          icon: AppIcons.style,
          scores: {'expressive': 4, 'bold': 2},
        ),
      ],
    ),
    _DiagnosticQuestion(
      title: 'Ton budget, le plus souvent ?',
      subtitle: 'Achat',
      options: [
        _DiagnosticOption(
          label: 'Petit prix',
          icon: Icons.savings_rounded,
          scores: {'budget': 3, 'practical': 2},
        ),
        _DiagnosticOption(
          label: 'Bon rapport qualité',
          icon: Icons.balance_rounded,
          scores: {'budget': 2, 'modern': 2},
        ),
        _DiagnosticOption(
          label: 'Pièce forte',
          icon: Icons.diamond_rounded,
          scores: {'expressive': 2, 'occasion': 2},
        ),
        _DiagnosticOption(
          label: 'Sur mesure',
          icon: Icons.design_services_rounded,
          scores: {'heritage': 2, 'modern': 2, 'occasion': 2},
        ),
      ],
    ),
    _DiagnosticQuestion(
      title: 'Beauté et accessoires ?',
      subtitle: 'Finition',
      options: [
        _DiagnosticOption(
          label: 'Très simple',
          icon: Icons.face_retouching_natural_rounded,
          scores: {'minimal': 2, 'beauty': 1},
        ),
        _DiagnosticOption(
          label: 'Bijou signature',
          icon: Icons.diamond_outlined,
          scores: {'heritage': 1, 'beauty': 2},
        ),
        _DiagnosticOption(
          label: 'Coiffure forte',
          icon: Icons.content_cut_rounded,
          scores: {'expressive': 2, 'beauty': 3, 'bold': 1},
        ),
        _DiagnosticOption(
          label: 'Selon l’occasion',
          icon: Icons.event_available_rounded,
          scores: {'occasion': 2, 'beauty': 1},
        ),
      ],
    ),
    _DiagnosticQuestion(
      title: 'Après le résultat ?',
      subtitle: 'Action',
      options: [
        _DiagnosticOption(
          label: 'Inspirations',
          icon: Icons.bookmark_add_rounded,
          scores: {'expressive': 1, 'heritage': 1},
        ),
        _DiagnosticOption(
          label: 'Pros adaptés',
          icon: AppIcons.shop,
          scores: {'occasion': 2, 'modern': 1},
        ),
        _DiagnosticOption(
          label: 'Garde-robe',
          icon: Icons.checkroom_rounded,
          scores: {'practical': 2, 'minimal': 1},
        ),
        _DiagnosticOption(
          label: 'Composer',
          icon: Icons.style_rounded,
          scores: {'modern': 1, 'heritage': 1, 'practical': 1, 'bold': 1},
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        backgroundColor: ModernColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: const Text('Diagnostic style'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/${_questions.length}',
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: ModernColors.primary,
                  backgroundColor: ModernColors.line,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                physics: const BouncingScrollPhysics(),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: ModernColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Rituel Style',
                            style: TextStyle(
                              color: ModernColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          question.title,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 22,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.subtitle,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < question.options.length; i++) ...[
                    _DiagnosticOptionTile(
                      option: question.options[i],
                      selected: _selectedIndex == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedIndex = i);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton.icon(
                onPressed: _selectedIndex == null ? null : _next,
                icon: Icon(
                  _currentIndex == _questions.length - 1
                      ? AppIcons.style
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _currentIndex == _questions.length - 1
                      ? 'Voir mon profil style'
                      : 'Continuer',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    final selected = _selectedIndex;
    if (selected == null) return;
    final question = _questions[_currentIndex];
    final option = question.options[selected];
    for (final entry in option.scores.entries) {
      _scores[entry.key] = (_scores[entry.key] ?? 0) + entry.value;
    }
    _answers.add({
      'question': question.title,
      'answer': option.label,
      'scores': option.scores,
    });

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => StyleDiagnosticResultScreen(
              scores: Map<String, int>.from(_scores),
              answers: List<Map<String, dynamic>>.from(_answers),
            ),
      ),
    );
  }
}

class StyleDiagnosticResultScreen extends StatefulWidget {
  final Map<String, int> scores;
  final List<Map<String, dynamic>> answers;

  const StyleDiagnosticResultScreen({
    super.key,
    required this.scores,
    required this.answers,
  });

  @override
  State<StyleDiagnosticResultScreen> createState() =>
      _StyleDiagnosticResultScreenState();
}

class _StyleDiagnosticResultScreenState
    extends State<StyleDiagnosticResultScreen> {
  bool _saving = false;
  bool _saved = false;

  _StyleProfile get _profile => _StyleProfile.fromScores(widget.scores);

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        backgroundColor: ModernColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: const Text('Profil style'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const BouncingScrollPhysics(),
          children: [
            AppCard(
              elevated: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: profile.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(profile.icon, color: profile.color, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.title,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 25,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.description,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        profile.tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                avatar: const Icon(Icons.tag_rounded, size: 15),
                                side: const BorderSide(
                                  color: ModernColors.line,
                                ),
                                backgroundColor: ModernColors.surface,
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ResultSection(
              title: 'Plan Style',
              children: [
                _ResultBullet(
                  icon: Icons.palette_rounded,
                  text: profile.palette,
                ),
                _ResultBullet(icon: AppIcons.salon, text: profile.salonAction),
                _ResultBullet(
                  icon: Icons.checkroom_rounded,
                  text: profile.recommendations.first,
                ),
              ],
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveProfile,
              icon:
                  _saving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        _saved ? Icons.check_rounded : Icons.bookmark_rounded,
                      ),
              label: Text(_saved ? 'Profil sauvegardé' : 'Sauvegarder'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const StyleQuizScreen()),
                  ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refaire plus tard'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connectez-vous pour sauvegarder ce diagnostic.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final profile = _profile;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('style_profile')
        .doc('main');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        final lastRewardAt = _dateFrom(data?['lastRewardAt']);
        final now = DateTime.now();
        final eligibleReward =
            lastRewardAt == null || now.difference(lastRewardAt).inDays >= 7;
        final reward = snapshot.exists ? 50 : 150;

        transaction.set(ref, {
          'title': profile.title,
          'description': profile.description,
          'scores': widget.scores,
          'answers': widget.answers,
          'tags': profile.tags,
          'recommendations': profile.recommendations,
          'palette': profile.palette,
          'salonAction': profile.salonAction,
          'nextActions': [
            'Voir produits liés',
            'Trouver un pro',
            'Composer un look',
          ],
          'updatedAt': FieldValue.serverTimestamp(),
          if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
          if (eligibleReward) 'lastRewardAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(
          FirebaseFirestore.instance.collection('users').doc(user.uid),
          {
            'styleProfile': {
              'title': profile.title,
              'tags': profile.tags,
              'palette': profile.palette,
              'salonAction': profile.salonAction,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            if (eligibleReward)
              'gamification': {
                'points': FieldValue.increment(reward),
                'lifetimePoints': FieldValue.increment(reward),
                'lastActivityDate': _todayKey(),
                'completedChallengesToday': FieldValue.arrayUnion([
                  'style_diagnostic',
                ]),
                'updatedAt': FieldValue.serverTimestamp(),
              },
          },
          SetOptions(merge: true),
        );
      });

      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostic sauvegardé dans ton profil style.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegarde indisponible pour le moment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _DiagnosticOptionTile extends StatelessWidget {
  final _DiagnosticOption option;
  final bool selected;
  final VoidCallback onTap;

  const _DiagnosticOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color:
          selected
              ? ModernColors.primary.withValues(alpha: 0.08)
              : ModernColors.surface,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ModernColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(option.icon, color: ModernColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              option.label,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? ModernColors.primary : ModernColors.muted,
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ResultSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ResultBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ResultBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ModernColors.primary, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                height: 1.35,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleProfile {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> tags;
  final List<String> recommendations;
  final String palette;
  final String salonAction;

  const _StyleProfile({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tags,
    required this.recommendations,
    required this.palette,
    required this.salonAction,
  });

  factory _StyleProfile.fromScores(Map<String, int> scores) {
    final sorted =
        scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted.first.key;
    final second = sorted.length > 1 ? sorted[1].key : '';
    if (dominant == 'heritage' && second == 'modern') {
      return const _StyleProfile(
        title: 'Héritage contemporain',
        description:
            'Tu aimes les pièces qui portent une histoire, mais tu veux les porter avec des coupes actuelles et faciles à vivre.',
        icon: Icons.merge_type_rounded,
        color: ModernColors.creator,
        tags: ['tradition moderne', 'artisanat', 'coupe nette', 'culture'],
        palette: 'Tons naturels, ivoire, indigo ou accent textile.',
        salonAction: 'Voir ateliers avec créations modernes et textiles forts.',
        recommendations: [
          'Cherche des créations qui mélangent textile identitaire et silhouette moderne.',
          'Sauvegarde des tenues de cérémonie réutilisables en version plus simple.',
          'Compare les associations avec une base neutre.',
        ],
      );
    }
    if (dominant == 'heritage') {
      return const _StyleProfile(
        title: 'Ancrage culturel',
        description:
            'Ton style valorise les matières, symboles et savoir-faire traditionnels, sans se limiter à une seule région du monde.',
        icon: Icons.history_edu_rounded,
        color: ModernColors.primary,
        tags: ['tissage', 'broderie', 'motifs', 'cérémonie'],
        palette: 'Couleurs profondes, terre, indigo, doré discret.',
        salonAction: 'Trouver un créateur pour cérémonie ou pièce signature.',
        recommendations: [
          'Explore les talents qui travaillent les textiles culturels, les matières locales et les finitions artisanales.',
          'Privilégie les pièces fortes avec accessoires sobres.',
          'Garde une trace de tes inspirations pour les montrer à un créateur.',
        ],
      );
    }
    if (dominant == 'expressive') {
      return const _StyleProfile(
        title: 'Signature expressive',
        description:
            'Tu utilises la mode pour affirmer une présence : couleur, texture, contraste et détails qui se remarquent.',
        icon: AppIcons.style,
        color: ModernColors.rose,
        tags: ['couleur', 'imprimés', 'accessoires', 'audace'],
        palette: 'Contrastes assumés, imprimés, couleur en point focal.',
        salonAction:
            'Explorer inspirations fortes, accessoires et pièces photo.',
        recommendations: [
          'Teste les associations dans l’essayage avant de commander.',
          'Sauvegarde les looks forts dans tes souhaits pour comparer.',
          'Cherche des tutoriels coiffure ou accessoires liés au look.',
        ],
      );
    }
    if (dominant == 'minimal') {
      return const _StyleProfile(
        title: 'Épure soignée',
        description:
            'Tu préfères les silhouettes nettes, les couleurs maîtrisées et les détails subtils qui rendent une tenue durable.',
        icon: Icons.contrast_rounded,
        color: ModernColors.admin,
        tags: ['minimal', 'neutres', 'coupe', 'intemporel'],
        palette: 'Noir, blanc, gris, beige, puis un détail travaillé.',
        salonAction: 'Voir produits aux coupes nettes et détails subtils.',
        recommendations: [
          'Mise sur une belle coupe avant la quantité.',
          'Ajoute une touche culturelle subtile : bijou, texture ou détail tissé.',
          'Construis une garde-robe capsule autour de pièces compatibles.',
        ],
      );
    }
    if (dominant == 'practical') {
      return const _StyleProfile(
        title: 'Élégance pratique',
        description:
            'Tu veux des vêtements beaux, confortables et utiles plusieurs fois, sans perdre l’élégance.',
        icon: Icons.repeat_rounded,
        color: ModernColors.client,
        tags: ['confort', 'quotidien', 'polyvalent', 'facile'],
        palette: 'Neutres chauds, matières respirantes, accessoires utiles.',
        salonAction: 'Chercher des pièces faciles à porter souvent.',
        recommendations: [
          'Cherche des pièces qui passent du quotidien à une sortie.',
          'Ajoute tes vêtements réels dans la garde-robe pour de meilleurs conseils.',
          'Priorise les matières respirantes et faciles à entretenir.',
        ],
      );
    }
    return const _StyleProfile(
      title: 'Modernité maîtrisée',
      description:
          'Tu recherches un style actuel, lisible et bien construit, avec des pièces capables de rester élégantes longtemps.',
      icon: AppIcons.style,
      color: ModernColors.primary,
      tags: ['moderne', 'urbain', 'net', 'sélection'],
      palette: 'Base sobre, accent contemporain, finition propre.',
      salonAction: 'Comparer boutiques actuelles et ateliers sur mesure.',
      recommendations: [
        'Explore les boutiques avec silhouettes contemporaines.',
        'Associe une pièce moderne à un détail artisanal pour plus de personnalité.',
        'Adapte les looks à ton contexte avant de les sauvegarder.',
      ],
    );
  }
}

class _DiagnosticQuestion {
  final String title;
  final String subtitle;
  final List<_DiagnosticOption> options;

  const _DiagnosticQuestion({
    required this.title,
    required this.subtitle,
    required this.options,
  });
}

class _DiagnosticOption {
  final String label;
  final IconData icon;
  final Map<String, int> scores;

  const _DiagnosticOption({
    required this.label,
    required this.icon,
    required this.scores,
  });
}

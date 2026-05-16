import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/client/client_dashboard_summary.dart';
import '../../../../models/client/gamification/daily_challenge_model.dart';
import '../../../../models/client/gamification/daily_quiz_model.dart';
import '../../../../models/client/gamification/quiz_question_model.dart';
import '../../../../models/client/gamification/style_progress_model.dart';
import '../../../../services/client/client_gamification_service.dart';
import '../../../../services/client/daily_quiz_service.dart';

class ClientDailyChallengeCard extends StatelessWidget {
  final ClientDashboardSummary summary;
  final StyleProgressModel progress;
  final ClientGamificationService gamificationService;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenStyle;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenMessages;
  final VoidCallback? onOpenCommunity;
  final VoidCallback onOpenMeasurements;
  final VoidCallback onOpenTryOn;

  const ClientDailyChallengeCard({
    super.key,
    required this.summary,
    required this.progress,
    required this.gamificationService,
    required this.onOpenSalon,
    required this.onOpenStyle,
    required this.onOpenWardrobe,
    required this.onOpenMessages,
    this.onOpenCommunity,
    required this.onOpenMeasurements,
    required this.onOpenTryOn,
  });

  @override
  Widget build(BuildContext context) {
    final nextChallenge = progress.challenges.firstWhere(
      (challenge) => !challenge.completed && challenge.intent != 'messages',
      orElse: () => progress.challenges.first,
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(padding: EdgeInsets.zero, title: 'Rituel'),
          const SizedBox(height: 10),
          _ChallengeTile(
            challenge: nextChallenge,
            highlighted: true,
            onTap: () => _handleChallenge(context, nextChallenge),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChallenge(
    BuildContext context,
    DailyChallengeModel challenge,
  ) async {
    if (challenge.id == 'daily_quiz') {
      await _openQuiz(context, challenge);
      return;
    }

    final awarded = await _completeChallenge(context, challenge);
    if (!context.mounted) return;

    switch (challenge.intent) {
      case 'salon':
        onOpenSalon();
        break;
      case 'style':
        onOpenStyle();
        break;
      case 'wardrobe':
        onOpenWardrobe();
        break;
      case 'measurements':
        onOpenMeasurements();
        break;
      case 'try_on':
        onOpenTryOn();
        break;
      case 'messages':
        (onOpenCommunity ?? onOpenStyle)();
        break;
      case 'community':
        (onOpenCommunity ?? onOpenStyle)();
        break;
      default:
        onOpenStyle();
    }

    if (awarded > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$awarded pts ajoutés à ton parcours Style.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<int> _completeChallenge(
    BuildContext context,
    DailyChallengeModel challenge,
  ) async {
    if (challenge.completed) return 0;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;
    try {
      return await gamificationService.completeChallenge(
        userId: userId,
        challenge: challenge,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Points indisponibles pour le moment.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return 0;
    }
  }

  Future<void> _openQuiz(
    BuildContext context,
    DailyChallengeModel challenge,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final date = _todayKey();
    final service = DailyQuizService();
    final quiz = await service.getOrCreateDailyQuiz(
      date: date,
      context: DailyQuizContext(
        userId: user.uid,
        level: progress.levelLabel,
        points: progress.points,
        streak: progress.streak,
        preferredStyle:
            summary.savedItems.isNotEmpty
                ? summary.savedItems.first.subtitle
                : 'élégant',
        country: summary.city.isEmpty ? 'International' : summary.city,
      ),
    );

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _DailyQuizSheet(
            quiz: quiz,
            date: date,
            service: service,
            gamificationService: gamificationService,
            challenge: challenge,
            onOpenSalon: onOpenSalon,
            onOpenStyle: onOpenStyle,
            onOpenMessages: onOpenMessages,
            onOpenCommunity: onOpenCommunity,
          ),
    );
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class _ChallengeTile extends StatelessWidget {
  final DailyChallengeModel challenge;
  final bool highlighted;
  final VoidCallback onTap;

  const _ChallengeTile({
    required this.challenge,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          highlighted
              ? ModernColors.primary.withValues(alpha: 0.08)
              : ModernColors.canvas,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  highlighted
                      ? ModernColors.primary.withValues(alpha: 0.16)
                      : ModernColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      challenge.completed
                          ? ModernColors.success.withValues(alpha: 0.12)
                          : ModernColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  challenge.completed ? Icons.check_rounded : challenge.icon,
                  color:
                      challenge.completed
                          ? ModernColors.success
                          : ModernColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      challenge.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    challenge.completed ? 'Fait' : challenge.actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    challenge.completed ? 'validé' : '+${challenge.points}',
                    style: TextStyle(
                      color:
                          challenge.completed
                              ? ModernColors.success
                              : ModernColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0,
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
}

class _DailyQuizSheet extends StatefulWidget {
  final DailyQuizModel quiz;
  final String date;
  final DailyQuizService service;
  final ClientGamificationService gamificationService;
  final DailyChallengeModel challenge;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenStyle;
  final VoidCallback onOpenMessages;
  final VoidCallback? onOpenCommunity;

  const _DailyQuizSheet({
    required this.quiz,
    required this.date,
    required this.service,
    required this.gamificationService,
    required this.challenge,
    required this.onOpenSalon,
    required this.onOpenStyle,
    required this.onOpenMessages,
    this.onOpenCommunity,
  });

  @override
  State<_DailyQuizSheet> createState() => _DailyQuizSheetState();
}

class _DailyQuizSheetState extends State<_DailyQuizSheet> {
  int _index = 0;
  int? _selected;
  bool _revealed = false;
  int _score = 0;
  bool _submitting = false;
  late bool _completed = widget.quiz.completed;
  int _earnedPoints = 0;
  final List<Map<String, dynamic>> _missed = [];

  QuizQuestionModel get _question => widget.quiz.questions[_index];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.52,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children:
                _completed
                    ? _completionContent(context)
                    : [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ModernColors.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.quiz.title,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.quiz.subtitle} • ${_index + 1}/${widget.quiz.questions.length}',
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (_index + 1) / widget.quiz.questions.length,
                          minHeight: 8,
                          color: ModernColors.primary,
                          backgroundColor: ModernColors.line,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _question.question,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < _question.options.length; i++) ...[
                        _QuizOption(
                          label: _question.options[i],
                          selected: _selected == i,
                          correct: _revealed && i == _question.correctAnswer,
                          wrong:
                              _revealed &&
                              _selected == i &&
                              i != _question.correctAnswer,
                          onTap:
                              _revealed
                                  ? null
                                  : () => setState(() => _selected = i),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_revealed) ...[
                        const SizedBox(height: 4),
                        AppCard(
                          color: ModernColors.canvas,
                          child: Text(
                            _question.explanation,
                            style: const TextStyle(
                              color: ModernColors.inkSoft,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            _selected == null || _submitting ? null : _next,
                        child: Text(
                          _revealed
                              ? (_index == widget.quiz.questions.length - 1
                                  ? 'Terminer'
                                  : 'Question suivante')
                              : 'Valider',
                        ),
                      ),
                    ],
          ),
        );
      },
    );
  }

  List<Widget> _completionContent(BuildContext context) {
    final missedCategories =
        _missed
            .map((question) => question['category']?.toString() ?? 'style')
            .toSet()
            .toList();
    return [
      Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: ModernColors.line,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ModernColors.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: ModernColors.primary.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: ModernColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: ModernColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rituel terminé',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _earnedPoints > 0 ? '+$_earnedPoints points' : 'Enregistré',
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Signal du jour',
        style: TextStyle(
          color: ModernColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      const SizedBox(height: 8),
      AppCard(
        color: ModernColors.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.quiz.learnedToday,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                height: 1.35,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.palette_rounded,
                  color: ModernColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.quiz.styleTip,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.inkSoft,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (missedCategories.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              missedCategories
                  .map(
                    (category) => Chip(
                      label: Text('À revoir: $category'),
                      avatar: const Icon(Icons.refresh_rounded, size: 16),
                      backgroundColor: ModernColors.surface,
                      side: const BorderSide(color: ModernColors.line),
                    ),
                  )
                  .toList(),
        ),
      ],
      const SizedBox(height: 18),
      const Text(
        'Maintenant',
        style: TextStyle(
          color: ModernColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      const SizedBox(height: 10),
      _QuizNextAction(
        icon: AppIcons.salon,
        title: 'Explorer Salon',
        subtitle: widget.quiz.outfitSuggestion,
        onTap: () {
          Navigator.pop(context);
          widget.onOpenSalon();
        },
      ),
      const SizedBox(height: 10),
      _QuizNextAction(
        icon: AppIcons.style,
        title: 'Composer',
        subtitle: 'Partir de ce signal',
        onTap: () {
          Navigator.pop(context);
          widget.onOpenStyle();
        },
      ),
      const SizedBox(height: 10),
      _QuizNextAction(
        icon: AppIcons.messages,
        title: 'Demander avis',
        subtitle: 'Partager une idée',
        onTap: () {
          Navigator.pop(context);
          (widget.onOpenCommunity ?? widget.onOpenStyle)();
        },
      ),
      const SizedBox(height: 8),
    ];
  }

  Future<void> _next() async {
    if (!_revealed) {
      final correct = _selected == _question.correctAnswer;
      if (correct) {
        _score++;
      } else {
        _missed.add(_question.toMap());
      }
      setState(() => _revealed = true);
      return;
    }

    if (_index < widget.quiz.questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    setState(() => _submitting = true);
    final earned = 20 + (_score * 10);
    await widget.service.completeQuiz(
      userId: userId,
      date: widget.date,
      quiz: widget.quiz,
      result: DailyQuizResult(
        score: _score,
        totalQuestions: widget.quiz.questions.length,
        earnedPoints: earned,
        missedQuestions: _missed,
      ),
    );
    final awardedPoints = await widget.gamificationService.awardQuizPoints(
      userId: userId,
      points: earned,
      quizDate: widget.date,
    );
    if (!mounted) return;
    setState(() {
      _earnedPoints = awardedPoints;
      _completed = true;
      _submitting = false;
    });
  }
}

class _QuizNextAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuizNextAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.canvas,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ModernColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: ModernColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: ModernColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  const _QuizOption({
    required this.label,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        correct
            ? ModernColors.success
            : wrong
            ? ModernColors.rose
            : selected
            ? ModernColors.primary
            : ModernColors.line;
    return Material(
      color:
          selected || correct || wrong
              ? color.withValues(alpha: 0.08)
              : ModernColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (correct)
                const Icon(Icons.check_rounded, color: ModernColors.success)
              else if (wrong)
                const Icon(Icons.close_rounded, color: ModernColors.rose),
            ],
          ),
        ),
      ),
    );
  }
}

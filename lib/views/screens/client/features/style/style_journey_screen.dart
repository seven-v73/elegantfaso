import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/client/client_dashboard_summary.dart';
import '../../../../../models/client/gamification/daily_challenge_model.dart';
import '../../../../../models/client/gamification/style_badge_model.dart';
import '../../../../../models/client/gamification/style_progress_model.dart';
import '../../../../../services/client/client_gamification_service.dart';
import '../../widgets/client_daily_challenge_card.dart';

class StyleJourneyScreen extends StatelessWidget {
  final ClientDashboardSummary summary;
  final StyleProgressModel progress;
  final ClientGamificationService gamificationService;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenStyle;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenMeasurements;
  final VoidCallback onOpenTryOn;

  const StyleJourneyScreen({
    super.key,
    required this.summary,
    required this.progress,
    required this.gamificationService,
    required this.onOpenSalon,
    required this.onOpenStyle,
    required this.onOpenWardrobe,
    required this.onOpenMessages,
    required this.onOpenCommunity,
    required this.onOpenMeasurements,
    required this.onOpenTryOn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcours Style')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _JourneyHero(progress: progress),
          const SizedBox(height: 14),
          _StyleCompassCard(
            progress: progress,
            onOpenSalon: () => _openFromJourney(context, onOpenSalon),
            onOpenWardrobe: () => _openFromJourney(context, onOpenWardrobe),
            onOpenMessages: () => _openFromJourney(context, onOpenMessages),
          ),
          const SizedBox(height: 14),
          ClientDailyChallengeCard(
            summary: summary,
            progress: progress,
            gamificationService: gamificationService,
            onOpenSalon: () => _openFromJourney(context, onOpenSalon),
            onOpenStyle: () => _openFromJourney(context, onOpenStyle),
            onOpenWardrobe: () => _openFromJourney(context, onOpenWardrobe),
            onOpenMessages: () => _openFromJourney(context, onOpenMessages),
            onOpenCommunity: () => _openFromJourney(context, onOpenCommunity),
            onOpenMeasurements:
                () => _openFromJourney(context, onOpenMeasurements),
            onOpenTryOn: () => _openFromJourney(context, onOpenTryOn),
          ),
          const SizedBox(height: 14),
          _PointsActionCard(
            progress: progress,
            onOpenSalon: () => _openFromJourney(context, onOpenSalon),
            onOpenStyle: () => _openFromJourney(context, onOpenStyle),
            onOpenWardrobe: () => _openFromJourney(context, onOpenWardrobe),
            onOpenMessages: () => _openFromJourney(context, onOpenMessages),
          ),
          const SizedBox(height: 14),
          _SocialNudgeCard(
            progress: progress,
            gamificationService: gamificationService,
            onOpenCommunity: () => _openFromJourney(context, onOpenCommunity),
            onOpenMessages: () => _openFromJourney(context, onOpenMessages),
            onOpenSalon: () => _openFromJourney(context, onOpenSalon),
            onShowAll: () => _showJourneyDetails(context, includeSocial: true),
          ),
          const SizedBox(height: 14),
          _SignalsPreviewCard(
            progress: progress,
            onShowDetails: () => _showJourneyDetails(context),
          ),
        ],
      ),
    );
  }

  void _showJourneyDetails(BuildContext context, {bool includeSocial = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _JourneyDetailsSheet(
            progress: progress,
            maxBucketPoints: _maxBucketPoints(progress),
            bucketColor: _bucketColor,
            includeSocial: includeSocial,
            gamificationService: gamificationService,
            onOpenSalon: () => _openFromJourney(context, onOpenSalon),
            onOpenStyle: () => _openFromJourney(context, onOpenStyle),
            onOpenWardrobe: () => _openFromJourney(context, onOpenWardrobe),
            onOpenMessages: () => _openFromJourney(context, onOpenMessages),
            onOpenCommunity: () => _openFromJourney(context, onOpenCommunity),
          ),
    );
  }

  void _openFromJourney(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  int _maxBucketPoints(StyleProgressModel progress) {
    final max = progress.pointBuckets.fold<int>(
      0,
      (value, bucket) => bucket.points > value ? bucket.points : value,
    );
    return max <= 0 ? 1 : max;
  }

  Color _bucketColor(String id) {
    switch (id) {
      case 'discovery':
        return ModernColors.creator;
      case 'community':
        return ModernColors.client;
      case 'trust':
        return ModernColors.success;
      default:
        return ModernColors.primary;
    }
  }
}

class _WeeklyRhythmStrip extends StatelessWidget {
  final String currentTheme;

  const _WeeklyRhythmStrip({required this.currentTheme});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final days = _styleWeek();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: ModernColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Semaine Style',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Text(
                'Demain: ${days[_nextWeekday(today)]!.theme}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final weekday = index + 1;
                final day = days[weekday]!;
                final selected = weekday == today || day.theme == currentTheme;
                return _WeekdayPill(day: day, selected: selected);
              },
            ),
          ),
        ],
      ),
    );
  }

  int _nextWeekday(int weekday) => weekday == DateTime.sunday ? 1 : weekday + 1;

  Map<int, _StyleWeekDay> _styleWeek() {
    return const {
      DateTime.monday: _StyleWeekDay(
        day: 'Lun',
        theme: 'Couleurs',
        prompt: 'voir les palettes qui reviennent',
      ),
      DateTime.tuesday: _StyleWeekDay(
        day: 'Mar',
        theme: 'Occasions',
        prompt: 'lier style et moments réels',
      ),
      DateTime.wednesday: _StyleWeekDay(
        day: 'Mer',
        theme: 'Silhouette',
        prompt: 'comprendre volume et aisance',
      ),
      DateTime.thursday: _StyleWeekDay(
        day: 'Jeu',
        theme: 'Budget',
        prompt: 'choisir achat, sur mesure ou garde-robe',
      ),
      DateTime.friday: _StyleWeekDay(
        day: 'Ven',
        theme: 'Matières',
        prompt: 'choisir selon climat et entretien',
      ),
      DateTime.saturday: _StyleWeekDay(
        day: 'Sam',
        theme: 'Beauté',
        prompt: 'relier coiffure, peau et accessoires',
      ),
      DateTime.sunday: _StyleWeekDay(
        day: 'Dim',
        theme: 'Résumé',
        prompt: 'retenir ce qui revient souvent',
      ),
    };
  }
}

class _StyleCompassCard extends StatelessWidget {
  final StyleProgressModel progress;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenMessages;

  const _StyleCompassCard({
    required this.progress,
    required this.onOpenSalon,
    required this.onOpenWardrobe,
    required this.onOpenMessages,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = _lessonForTheme(progress.dailyTheme);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lesson.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(lesson.icon, color: lesson.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.focus,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CompassAction(
                  icon: Icons.visibility_rounded,
                  label: 'Observer',
                  onTap: onOpenSalon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompassAction(
                  icon: Icons.checkroom_rounded,
                  label: 'Essayer',
                  onTap: onOpenWardrobe,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompassAction(
                  icon: Icons.forum_rounded,
                  label: 'Demander',
                  onTap: onOpenMessages,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _StyleLesson _lessonForTheme(String theme) {
    final normalized = theme.toLowerCase();
    if (normalized.contains('couleur')) {
      return const _StyleLesson(
        title: 'Boussole couleur',
        focus: 'Repère ce qui t’attire avant de choisir une pièce.',
        icon: Icons.palette_rounded,
        color: ModernColors.primary,
      );
    }
    if (normalized.contains('occasion')) {
      return const _StyleLesson(
        title: 'Style en contexte',
        focus: 'Une tenue devient claire quand le moment est clair.',
        icon: Icons.event_available_rounded,
        color: ModernColors.creator,
      );
    }
    if (normalized.contains('silhouette') ||
        normalized.contains('morphologie')) {
      return const _StyleLesson(
        title: 'Volumes et aisance',
        focus: 'Cherche l’équilibre qui te fait te sentir naturel.',
        icon: Icons.accessibility_new_rounded,
        color: ModernColors.client,
      );
    }
    if (normalized.contains('budget')) {
      return const _StyleLesson(
        title: 'Choix utile',
        focus: 'Acheter moins, mais choisir ce qui servira vraiment.',
        icon: Icons.savings_rounded,
        color: ModernColors.success,
      );
    }
    if (normalized.contains('mati')) {
      return const _StyleLesson(
        title: 'Matière vivante',
        focus: 'Le confort, le climat et l’entretien guident le style.',
        icon: Icons.texture_rounded,
        color: ModernColors.admin,
      );
    }
    if (normalized.contains('beaut')) {
      return const _StyleLesson(
        title: 'Finition personnelle',
        focus: 'Coiffure, peau et accessoire peuvent signer le look.',
        icon: Icons.face_retouching_natural_rounded,
        color: ModernColors.rose,
      );
    }
    return const _StyleLesson(
      title: 'Ce qui revient',
      focus: 'Tes répétitions révèlent ton style plus que les tendances.',
      icon: Icons.bookmark_added_rounded,
      color: ModernColors.primary,
    );
  }
}

class _StyleLesson {
  final String title;
  final String focus;
  final IconData icon;
  final Color color;

  const _StyleLesson({
    required this.title,
    required this.focus,
    required this.icon,
    required this.color,
  });
}

class _StyleMemoryCard extends StatelessWidget {
  final StyleProgressModel progress;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenWardrobe;

  const _StyleMemoryCard({
    required this.progress,
    required this.onOpenSalon,
    required this.onOpenWardrobe,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: ModernColors.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: ModernColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ce que ton style raconte',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            progress.styleInsight,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          if (progress.recentThemes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  progress.recentThemes
                      .take(5)
                      .map(
                        (theme) => _StyleSignalChip(
                          label: theme,
                          selected: theme == progress.dailyTheme,
                        ),
                      )
                      .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenSalon,
                  icon: const Icon(AppIcons.salon, size: 18),
                  label: const Text('Observer'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpenWardrobe,
                  icon: const Icon(Icons.checkroom_rounded, size: 18),
                  label: const Text('Appliquer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            progress.nextStyleAction,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleSignalChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _StyleSignalChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            selected
                ? ModernColors.primary.withValues(alpha: 0.12)
                : ModernColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              selected
                  ? ModernColors.primary.withValues(alpha: 0.2)
                  : ModernColors.line,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: selected ? ModernColors.primary : ModernColors.inkSoft,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StyleDirectionCard extends StatelessWidget {
  final StyleProgressModel progress;
  final VoidCallback onOpenStyle;

  const _StyleDirectionCard({
    required this.progress,
    required this.onOpenStyle,
  });

  @override
  Widget build(BuildContext context) {
    final topBuckets =
        ([...progress.pointBuckets]
          ..sort((a, b) => b.points.compareTo(a.points))).take(2).toList();
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Direction',
            style: TextStyle(
              color: ModernColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress.styleDirection,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < topBuckets.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(child: _DirectionPillar(bucket: topBuckets[index])),
              ],
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenStyle,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Affiner'),
          ),
        ],
      ),
    );
  }
}

class _DirectionPillar extends StatelessWidget {
  final StylePointBucket bucket;

  const _DirectionPillar({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final color = switch (bucket.id) {
      'discovery' => ModernColors.creator,
      'community' => ModernColors.client,
      'trust' => ModernColors.success,
      _ => ModernColors.primary,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              bucket.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPulseCard extends StatelessWidget {
  final StyleProgressModel progress;

  const _WeeklyPulseCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final socialDone =
        progress.completedTodayIds
            .where(
              (id) =>
                  id == 'ask_community_style' ||
                  id == 'message_a_pro' ||
                  id == 'kind_exchange',
            )
            .length;
    final exploredThemes = progress.recentThemes.toSet().length;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: ModernColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pulse de semaine',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PulseMetric(
                  label: 'Rythme',
                  value: '${progress.streak}j',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PulseMetric(label: 'Thèmes', value: '$exploredThemes'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PulseMetric(label: 'Social', value: '$socialDone'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _pulseText(exploredThemes, socialDone),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  String _pulseText(int exploredThemes, int socialDone) {
    if (progress.streak <= 0) {
      return 'Commence doucement : un choix par jour suffit à révéler une direction.';
    }
    if (socialDone > 0) {
      return 'Ton style avance avec ton regard et celui des autres.';
    }
    if (exploredThemes >= 3) {
      return 'Plusieurs thèmes reviennent déjà : ton profil devient lisible.';
    }
    return 'Continue à observer : les répétitions finissent par dessiner ton style.';
  }
}

class _PulseMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PulseMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialNudgeCard extends StatelessWidget {
  final StyleProgressModel progress;
  final ClientGamificationService gamificationService;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenSalon;
  final VoidCallback onShowAll;

  const _SocialNudgeCard({
    required this.progress,
    required this.gamificationService,
    required this.onOpenCommunity,
    required this.onOpenMessages,
    required this.onOpenSalon,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final mission = _nextMission();
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: ModernColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Social',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(onPressed: onShowAll, child: const Text('Voir plus')),
            ],
          ),
          const SizedBox(height: 10),
          _SocialMissionTile(
            mission: mission,
            onTap: () => _openMission(context, mission),
          ),
        ],
      ),
    );
  }

  _SocialMission _nextMission() {
    final completed = progress.completedTodayIds.toSet();
    final missions = [
      _SocialMission(
        challenge: DailyChallengeModel(
          id: 'ask_community_style',
          title: 'Demander un regard',
          subtitle: 'Un avis sur une idée',
          intent: 'community',
          pointCategory: 'community',
          points: 35,
          icon: Icons.forum_rounded,
          completed: completed.contains('ask_community_style'),
          actionLabel: 'Avis',
        ),
        onOpen: onOpenCommunity,
      ),
      _SocialMission(
        challenge: DailyChallengeModel(
          id: 'message_a_pro',
          title: 'Parler à un pro',
          subtitle: 'Une question courte',
          intent: 'messages',
          pointCategory: 'community',
          points: 30,
          icon: AppIcons.messages,
          completed: completed.contains('message_a_pro'),
          actionLabel: 'Message',
        ),
        onOpen: onOpenMessages,
      ),
      _SocialMission(
        challenge: DailyChallengeModel(
          id: 'discover_certified_talent',
          title: 'Découvrir un talent',
          subtitle: 'Un atelier lié au thème',
          intent: 'salon',
          pointCategory: 'discovery',
          points: 30,
          icon: AppIcons.talents,
          completed: completed.contains('discover_certified_talent'),
          actionLabel: 'Salon',
        ),
        onOpen: onOpenSalon,
      ),
    ];
    return missions.firstWhere(
      (mission) => !mission.challenge.completed,
      orElse: () => missions.first,
    );
  }

  Future<void> _openMission(
    BuildContext context,
    _SocialMission mission,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    var awarded = 0;
    if (userId != null && !mission.challenge.completed) {
      try {
        awarded = await gamificationService.completeChallenge(
          userId: userId,
          challenge: mission.challenge,
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
      }
    }
    if (!context.mounted) return;
    if (awarded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$awarded pts ajoutés.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    mission.onOpen();
  }
}

class _SignalsPreviewCard extends StatelessWidget {
  final StyleProgressModel progress;
  final VoidCallback onShowDetails;

  const _SignalsPreviewCard({
    required this.progress,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.badges.where((badge) => badge.unlocked).length;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bookmark_added_rounded,
                color: ModernColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Repères',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton(
                onPressed: onShowDetails,
                child: const Text('Détails'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SignalStat(value: '$unlocked', label: 'badges'),
              const SizedBox(width: 8),
              _SignalStat(
                value: '${progress.recentThemes.toSet().length}',
                label: 'thèmes',
              ),
              const SizedBox(width: 8),
              _SignalStat(value: '${progress.streak}j', label: 'rythme'),
            ],
          ),
          if (progress.recentThemes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  progress.recentThemes
                      .take(4)
                      .map(
                        (theme) => _StyleSignalChip(
                          label: theme,
                          selected: theme == progress.dailyTheme,
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignalStat extends StatelessWidget {
  final String value;
  final String label;

  const _SignalStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: ModernColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ModernColors.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyDetailsSheet extends StatelessWidget {
  final StyleProgressModel progress;
  final int maxBucketPoints;
  final Color Function(String id) bucketColor;
  final bool includeSocial;
  final ClientGamificationService gamificationService;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenStyle;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenCommunity;

  const _JourneyDetailsSheet({
    required this.progress,
    required this.maxBucketPoints,
    required this.bucketColor,
    required this.includeSocial,
    required this.gamificationService,
    required this.onOpenSalon,
    required this.onOpenStyle,
    required this.onOpenWardrobe,
    required this.onOpenMessages,
    required this.onOpenCommunity,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
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
              const Text(
                'Repères Style',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 14),
              _WeeklyPulseCard(progress: progress),
              const SizedBox(height: 12),
              _StyleMemoryCard(
                progress: progress,
                onOpenSalon: onOpenSalon,
                onOpenWardrobe: onOpenWardrobe,
              ),
              const SizedBox(height: 12),
              _StyleDirectionCard(progress: progress, onOpenStyle: onOpenStyle),
              const SizedBox(height: 12),
              _WeeklyRhythmStrip(currentTheme: progress.dailyTheme),
              if (includeSocial) ...[
                const SizedBox(height: 12),
                _SocialMomentsCard(
                  progress: progress,
                  gamificationService: gamificationService,
                  onOpenCommunity: onOpenCommunity,
                  onOpenMessages: onOpenMessages,
                  onOpenSalon: onOpenSalon,
                ),
              ],
              const SizedBox(height: 12),
              const _RecentPointsCard(),
              const SizedBox(height: 18),
              const SectionHeader(padding: EdgeInsets.zero, title: 'Signaux'),
              const SizedBox(height: 10),
              for (final bucket in progress.pointBuckets) ...[
                _BucketProgressTile(
                  label: bucket.label,
                  description: bucket.description,
                  points: bucket.points,
                  maxPoints: maxBucketPoints,
                  color: bucketColor(bucket.id),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              const SectionHeader(padding: EdgeInsets.zero, title: 'Badges'),
              const SizedBox(height: 10),
              _BadgeGrid(badges: progress.badges),
              const SizedBox(height: 12),
              _HabitLoopCard(progress: progress),
              const SizedBox(height: 12),
              _NextStepCard(
                icon: AppIcons.salon,
                title: 'Découvrir',
                subtitle: progress.dailyTheme,
                onTap: onOpenSalon,
              ),
              const SizedBox(height: 8),
              _NextStepCard(
                icon: AppIcons.style,
                title: 'Transformer une idée',
                subtitle: 'Conseil court et action concrète',
                onTap: onOpenStyle,
              ),
              const SizedBox(height: 8),
              _NextStepCard(
                icon: AppIcons.wardrobe,
                title: 'Composer avec l’existant',
                subtitle: 'Garde-robe comme point de départ',
                onTap: onOpenWardrobe,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SocialMomentsCard extends StatelessWidget {
  final StyleProgressModel progress;
  final ClientGamificationService gamificationService;
  final VoidCallback onOpenCommunity;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenSalon;

  const _SocialMomentsCard({
    required this.progress,
    required this.gamificationService,
    required this.onOpenCommunity,
    required this.onOpenMessages,
    required this.onOpenSalon,
  });

  @override
  Widget build(BuildContext context) {
    final missions = _missions();
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: ModernColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Moments sociaux',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Apprendre aussi avec les autres.',
            style: TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          for (final mission in missions) ...[
            _SocialMissionTile(
              mission: mission,
              onTap: () => _openMission(context, mission),
            ),
            if (mission != missions.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  List<_SocialMission> _missions() {
    final completed = progress.completedTodayIds.toSet();
    return [
      _SocialMission(
        challenge: DailyChallengeModel(
          id: 'ask_community_style',
          title: 'Demander un regard',
          subtitle: 'Publie une hésitation ou réponds à un look',
          intent: 'community',
          pointCategory: 'community',
          points: 35,
          icon: Icons.forum_rounded,
          completed: completed.contains('ask_community_style'),
          actionLabel: 'Communauté',
        ),
        onOpen: onOpenCommunity,
      ),
      _SocialMission(
        challenge: DailyChallengeModel(
          id: 'message_a_pro',
          title: 'Parler à un pro',
          subtitle: 'Pose une question courte à une boutique ou un atelier',
          intent: 'messages',
          pointCategory: 'community',
          points: 30,
          icon: AppIcons.messages,
          completed: completed.contains('message_a_pro'),
          actionLabel: 'Message',
        ),
        onOpen: onOpenMessages,
      ),
      _SocialMission(
        challenge: DailyChallengeModel(
          id: 'discover_certified_talent',
          title: 'Découvrir un talent',
          subtitle: 'Observe un atelier lié à ton thème du jour',
          intent: 'salon',
          pointCategory: 'discovery',
          points: 30,
          icon: AppIcons.talents,
          completed: completed.contains('discover_certified_talent'),
          actionLabel: 'Salon',
        ),
        onOpen: onOpenSalon,
      ),
    ];
  }

  Future<void> _openMission(
    BuildContext context,
    _SocialMission mission,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    var awarded = 0;
    if (userId != null && !mission.challenge.completed) {
      try {
        awarded = await gamificationService.completeChallenge(
          userId: userId,
          challenge: mission.challenge,
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
      }
    }
    if (!context.mounted) return;
    if (awarded > 0 && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$awarded pts pour ce moment social.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    mission.onOpen();
  }
}

class _SocialMissionTile extends StatelessWidget {
  final _SocialMission mission;
  final VoidCallback onTap;

  const _SocialMissionTile({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final challenge = mission.challenge;
    final color =
        challenge.pointCategory == 'discovery'
            ? ModernColors.creator
            : ModernColors.client;
    return Material(
      color:
          challenge.completed
              ? ModernColors.success.withValues(alpha: 0.06)
              : ModernColors.canvas,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  challenge.completed
                      ? ModernColors.success.withValues(alpha: 0.16)
                      : ModernColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  challenge.completed ? Icons.check_rounded : challenge.icon,
                  color: challenge.completed ? ModernColors.success : color,
                  size: 20,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                challenge.completed ? 'Fait' : '+${challenge.points}',
                style: TextStyle(
                  color:
                      challenge.completed
                          ? ModernColors.success
                          : ModernColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialMission {
  final DailyChallengeModel challenge;
  final VoidCallback onOpen;

  const _SocialMission({required this.challenge, required this.onOpen});
}

class _PointsActionCard extends StatelessWidget {
  final StyleProgressModel progress;
  final VoidCallback onOpenSalon;
  final VoidCallback onOpenStyle;
  final VoidCallback onOpenWardrobe;
  final VoidCallback onOpenMessages;

  const _PointsActionCard({
    required this.progress,
    required this.onOpenSalon,
    required this.onOpenStyle,
    required this.onOpenWardrobe,
    required this.onOpenMessages,
  });

  @override
  Widget build(BuildContext context) {
    final next = _nextPointAction(progress);
    final tier = progress.visibilityTier;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: ModernColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(AppIcons.award, color: tier.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progress.lifetimePoints} pts',
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress.pointsToNextLevel > 0
                          ? '${progress.pointsToNextLevel} pts avant ${_nextTierLabel(progress)}'
                          : 'Niveau maximum atteint',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (progress.visibilityPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${progress.visibilityPercent}%',
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.progressToNextLevel,
              minHeight: 7,
              color: tier.color,
              backgroundColor: ModernColors.line,
            ),
          ),
          const SizedBox(height: 14),
          _PointCategoryRow(progress: progress),
          const SizedBox(height: 14),
          _NextPointActionTile(action: next),
        ],
      ),
    );
  }

  _PointAction _nextPointAction(StyleProgressModel progress) {
    final buckets = [...progress.pointBuckets]
      ..sort((a, b) => a.points.compareTo(b.points));
    final target = buckets.first;
    switch (target.id) {
      case 'discovery':
        return _PointAction(
          icon: AppIcons.salon,
          label: 'Renforcer Découverte',
          hint: 'Sauvegarde une inspiration ou découvre un talent.',
          points: 30,
          onTap: onOpenSalon,
        );
      case 'community':
        return _PointAction(
          icon: AppIcons.messages,
          label: 'Renforcer Communauté',
          hint: 'Demande un avis ou réponds utilement.',
          points: 35,
          onTap: onOpenMessages,
        );
      case 'trust':
        return _PointAction(
          icon: AppIcons.wardrobe,
          label: 'Renforcer Confiance',
          hint: 'Ajoute une pièce ou complète tes mesures.',
          points: 40,
          onTap: onOpenWardrobe,
        );
      default:
        return _PointAction(
          icon: AppIcons.style,
          label: 'Renforcer Style',
          hint: 'Fais le rituel, compose ou teste une silhouette.',
          points: 25,
          onTap: onOpenStyle,
        );
    }
  }

  String _nextTierLabel(StyleProgressModel progress) {
    final current = progress.visibilityTier.id;
    if (current == 'explorer') return 'Curateur';
    if (current == 'curator') return 'Confiance';
    if (current == 'trusted') return 'Ambassadeur';
    return progress.visibilityTier.label;
  }
}

class _PointCategoryRow extends StatelessWidget {
  final StyleProgressModel progress;

  const _PointCategoryRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final buckets = [...progress.pointBuckets]
      ..sort((a, b) => b.points.compareTo(a.points));
    return Row(
      children: [
        for (var index = 0; index < buckets.take(4).length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(child: _PointMiniBucket(bucket: buckets[index])),
        ],
      ],
    );
  }
}

class _PointMiniBucket extends StatelessWidget {
  final StylePointBucket bucket;

  const _PointMiniBucket({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final color = switch (bucket.id) {
      'discovery' => ModernColors.creator,
      'community' => ModernColors.client,
      'trust' => ModernColors.success,
      _ => ModernColors.primary,
    };
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bucket.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${bucket.points}',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPointActionTile extends StatelessWidget {
  final _PointAction action;

  const _NextPointActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.canvas,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
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
                child: Icon(action.icon, color: ModernColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
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
                      action.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${action.points}',
                style: const TextStyle(
                  color: ModernColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointAction {
  final IconData icon;
  final String label;
  final String hint;
  final int points;
  final VoidCallback onTap;

  const _PointAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.points,
    required this.onTap,
  });
}

class _RecentPointsCard extends StatelessWidget {
  const _RecentPointsCard();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    final stream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('visibility_activity')
            .orderBy('createdAt', descending: true)
            .limit(4)
            .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final activities =
            snapshot.data?.docs
                .map((doc) => _PointActivity.fromMap(doc.data()))
                .where((activity) => activity.points > 0)
                .toList() ??
            const <_PointActivity>[];

        if (activities.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ModernColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    color: ModernColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tes points apparaîtront ici',
                        style: TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Quiz, looks, favoris et échanges utiles.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    color: ModernColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Derniers points',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final activity in activities) ...[
                _RecentPointTile(activity: activity),
                if (activity != activities.last) const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecentPointTile extends StatelessWidget {
  final _PointActivity activity;

  const _RecentPointTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final color = switch (activity.category) {
      'discovery' => ModernColors.creator,
      'community' => ModernColors.client,
      'trust' => ModernColors.success,
      _ => ModernColors.primary,
    };
    final icon = switch (activity.type) {
      'quiz' => Icons.quiz_rounded,
      'challenge' => Icons.check_circle_rounded,
      _ => Icons.add_circle_outline_rounded,
    };
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.categoryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '+${activity.points}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PointActivity {
  final String title;
  final String type;
  final String category;
  final int points;

  const _PointActivity({
    required this.title,
    required this.type,
    required this.category,
    required this.points,
  });

  String get categoryLabel {
    return switch (category) {
      'discovery' => 'Découverte',
      'community' => 'Communauté',
      'trust' => 'Confiance',
      _ => 'Style',
    };
  }

  factory _PointActivity.fromMap(Map<String, dynamic> map) {
    return _PointActivity(
      title: map['title']?.toString() ?? 'Action Style',
      type: map['type']?.toString() ?? 'challenge',
      category: map['pointCategory']?.toString() ?? 'style',
      points: (map['points'] as num?)?.toInt() ?? 0,
    );
  }
}

class _CompassAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompassAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.canvas,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: ModernColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ModernColors.primary, size: 19),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleWeekDay {
  final String day;
  final String theme;
  final String prompt;

  const _StyleWeekDay({
    required this.day,
    required this.theme,
    required this.prompt,
  });
}

class _WeekdayPill extends StatelessWidget {
  final _StyleWeekDay day;
  final bool selected;

  const _WeekdayPill({required this.day, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color:
            selected
                ? ModernColors.primary.withValues(alpha: 0.1)
                : ModernColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              selected
                  ? ModernColors.primary.withValues(alpha: 0.22)
                  : ModernColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                day.day,
                style: TextStyle(
                  color: selected ? ModernColors.primary : ModernColors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                const Icon(Icons.circle, size: 8, color: ModernColors.primary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            day.theme,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day.prompt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 10,
              height: 1.12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitLoopCard extends StatelessWidget {
  final StyleProgressModel progress;

  const _HabitLoopCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _LoopStep(
            icon: Icons.school_rounded,
            label: 'Apprendre',
            description:
                progress.quizCompletedToday
                    ? 'Quiz terminé, notion du jour enregistrée'
                    : 'Commence par le quiz pour ouvrir le thème',
            color: ModernColors.primary,
          ),
          const _LoopDivider(),
          _LoopStep(
            icon: Icons.checkroom_rounded,
            label: 'Appliquer',
            description: 'Essaie une idée dans Iris, la garde-robe ou le Salon',
            color: ModernColors.creator,
          ),
          const _LoopDivider(),
          _LoopStep(
            icon: Icons.forum_rounded,
            label: 'Partager',
            description: 'Demande un avis, réponds utilement ou sauvegarde',
            color: ModernColors.client,
          ),
        ],
      ),
    );
  }
}

class _LoopStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _LoopStep({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoopDivider extends StatelessWidget {
  const _LoopDivider();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
        color: ModernColors.line,
      ),
    );
  }
}

class _JourneyHero extends StatelessWidget {
  final StyleProgressModel progress;

  const _JourneyHero({required this.progress});

  @override
  Widget build(BuildContext context) {
    final tier = progress.visibilityTier;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: ModernColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.dailyTheme,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.ritualLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            progress.dailyPrompt,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.progressToNextLevel,
              minHeight: 8,
              color: tier.color,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${progress.levelLabel} • ${progress.lifetimePoints} points cumulés',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progress.pointsToNextLevel > 0
                ? '${progress.pointsToNextLevel} points avant le prochain niveau'
                : 'Niveau maximum atteint',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketProgressTile extends StatelessWidget {
  final String label;
  final String description;
  final int points;
  final int maxPoints;
  final Color color;

  const _BucketProgressTile({
    required this.label,
    required this.description,
    required this.points,
    required this.maxPoints,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = (points / maxPoints).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.insights_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Text(
                      '$points pts',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    color: color,
                    backgroundColor: ModernColors.line,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<StyleBadgeModel> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 116,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final badge = badges[index];
        return AppCard(
          padding: const EdgeInsets.all(12),
          color:
              badge.unlocked
                  ? ModernColors.primary.withValues(alpha: 0.06)
                  : ModernColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                badge.icon,
                size: 18,
                color:
                    badge.unlocked ? ModernColors.primary : ModernColors.muted,
              ),
              const SizedBox(height: 7),
              Text(
                badge.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                badge.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NextStepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
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
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: ModernColors.inkSoft),
        ],
      ),
    );
  }
}

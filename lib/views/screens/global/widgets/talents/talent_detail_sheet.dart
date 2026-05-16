import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../core/account_roles.dart';
import '../../../../../design/app_icons.dart';
import '../../../../../design/ecommerce_widgets.dart';
import '../../../../../design/modern_design_system.dart';
import '../../../../../models/messages/conversation_context.dart';
import '../../../../../models/talent/talent_portfolio_item.dart';
import '../../../../../models/talent/talent_profile.dart';
import '../../../../../services/salon/salon_analytics_service.dart';
import '../../../../../services/talent/follow_service.dart';
import '../../../messages/chat_screen.dart';
import '../../../messages/user_model.dart';
import '../../salon_search_screen.dart';
import 'talent_contact_actions.dart';
import 'talent_portfolio_strip.dart';

class TalentDetailSheet extends StatefulWidget {
  const TalentDetailSheet({
    super.key,
    required this.talent,
    required this.portfolio,
  });

  final TalentProfile talent;
  final List<TalentPortfolioItem> portfolio;

  @override
  State<TalentDetailSheet> createState() => _TalentDetailSheetState();
}

class _TalentDetailSheetState extends State<TalentDetailSheet> {
  final FollowService _followService = FollowService();
  final SalonAnalyticsService _analyticsService = SalonAnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.trackProfileView(
      profileId: widget.talent.accountId,
      title: widget.talent.displayName,
      role: widget.talent.professionalRole,
    );
  }

  Future<void> _toggleFollow() async {
    if (!_followService.isSignedIn) {
      _showLoginPrompt('Connectez-vous pour suivre ce talent.');
      return;
    }
    await _followService.toggleFollow(
      talentId: widget.talent.id,
      talentName: widget.talent.displayName,
      professionalId: widget.talent.accountId,
      professionalRole: widget.talent.professionalRole,
    );
  }

  void _showAppointmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppointmentRequestSheet(talent: widget.talent),
    );
  }

  void _openPortfolioItem(TalentPortfolioItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonSearchScreen(
              initialQuery: '${item.title} ${widget.talent.displayName}',
            ),
      ),
    );
  }

  void _openAlternateShowcase() {
    final isShop = widget.talent.primaryRole == 'Boutique';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SalonSearchScreen(
              initialQuery:
                  '${widget.talent.displayName} ${isShop ? 'créateur atelier' : 'boutique produits'}',
            ),
      ),
    );
  }

  bool get _hasAlternateShowcase {
    final roles = AccountRoles.normalize(widget.talent.raw);
    return roles.contains(AccountRoles.createur) &&
        roles.contains(AccountRoles.boutique);
  }

  void _showLoginPrompt(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final talent = widget.talent;
    final isShop = talent.primaryRole == 'Boutique';
    final portfolioTitle = isShop ? 'Produits' : 'Créations';
    final portfolioCount =
        isShop ? talent.productsCount : talent.creationsCount;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: ModernColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              _Hero(talent: talent),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 350;
                        final name = Text(
                          talent.displayName,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                        final followButton = StreamBuilder<bool>(
                          stream: _followService.watchFollowing(talent.id),
                          builder: (context, snapshot) {
                            final following = snapshot.data == true;
                            return AppButton(
                              label: following ? 'Suivi' : 'Suivre',
                              onPressed: _toggleFollow,
                              icon:
                                  following
                                      ? Icons.check_rounded
                                      : Icons.person_add_alt_rounded,
                              variant: AppButtonVariant.secondary,
                              compact: true,
                            );
                          },
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              name,
                              const SizedBox(height: 10),
                              followButton,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: name),
                            const SizedBox(width: 10),
                            followButton,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${talent.primaryRole} · ${talent.place}',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(AppIcons.talents, talent.speciality),
                        _Chip(
                          Icons.people_rounded,
                          '${talent.followersCount} abonnés',
                        ),
                        if (talent.responseTime.isNotEmpty)
                          _Chip(Icons.schedule_rounded, talent.responseTime),
                        if (talent.verified)
                          const _Chip(Icons.verified_rounded, 'Vérifié'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      talent.description,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TalentContactActions(
                      talent: talent,
                      onAppointment: _showAppointmentSheet,
                    ),
                    if (_hasAlternateShowcase) ...[
                      const SizedBox(height: 14),
                      _AlternateShowcaseCard(
                        isShop: isShop,
                        onTap: _openAlternateShowcase,
                      ),
                    ],
                    const SizedBox(height: 22),
                    SectionHeader(
                      padding: EdgeInsets.zero,
                      title: portfolioTitle,
                      subtitle:
                          portfolioCount == 0
                              ? 'Aucun contenu publié'
                              : '$portfolioCount ${portfolioTitle.toLowerCase()}',
                    ),
                    const SizedBox(height: 12),
                    TalentPortfolioStrip(
                      items: widget.portfolio,
                      onOpenItem: _openPortfolioItem,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.talent});

  final TalentProfile talent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            talent.photoUrl.isEmpty
                ? ColoredBox(
                  color: ModernColors.creator.withValues(alpha: 0.15),
                  child: const Icon(
                    AppIcons.talents,
                    color: ModernColors.creator,
                    size: 68,
                  ),
                )
                : CachedNetworkImage(
                  imageUrl: talent.photoUrl,
                  fit: BoxFit.cover,
                ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 24,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Text(
                talent.speciality,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlternateShowcaseCard extends StatelessWidget {
  const _AlternateShowcaseCard({required this.isShop, required this.onTap});

  final bool isShop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isShop ? ModernColors.creator : ModernColors.shop;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isShop ? AppIcons.boutique : AppIcons.creator,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isShop ? 'Voir l’atelier' : 'Voir sa boutique',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      side: const BorderSide(color: ModernColors.line),
      backgroundColor: Colors.white,
    );
  }
}

class _AppointmentRequestSheet extends StatefulWidget {
  const _AppointmentRequestSheet({required this.talent});

  final TalentProfile talent;

  @override
  State<_AppointmentRequestSheet> createState() =>
      _AppointmentRequestSheetState();
}

class _AppointmentRequestSheetState extends State<_AppointmentRequestSheet> {
  String _reason = 'Conseil style';
  final TextEditingController _messageController = TextEditingController();
  bool _openingChat = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openAppointmentChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connectez-vous pour demander un rendez-vous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (currentUser.uid == widget.talent.accountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas demander un RDV à votre profil.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _openingChat = true);
    try {
      final currentDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
      final currentModel =
          currentDoc.exists
              ? UserModel.fromDocument(currentDoc)
              : UserModel.fromMap({
                'id': currentUser.uid,
                'email': currentUser.email ?? '',
                'displayName': currentUser.displayName ?? 'Client',
                'role': 'client',
                'photoUrl': currentUser.photoURL,
              });
      final otherRole = _roleForTalent(widget.talent);
      final talentModel = UserModel.fromMap({
        'id': widget.talent.accountId,
        'displayName': widget.talent.displayName,
        'role': otherRole,
        'roles': [otherRole],
        'photoUrl': widget.talent.photoUrl,
        'phone': widget.talent.phone,
        'specialty': widget.talent.speciality,
        'location': widget.talent.place,
      });
      final note = _messageController.text.trim();

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                utilisateurCourant: currentModel,
                autreUtilisateur: talentModel,
                currentRole: 'client',
                otherRole: otherRole,
                primaryColor: ModernColors.primary,
                conversationContext: ConversationContext(
                  type: ConversationContextTypes.appointment,
                  id: widget.talent.accountId,
                  title: 'RDV $_reason',
                  subtitle:
                      note.isEmpty
                          ? widget.talent.displayName
                          : '$note · ${widget.talent.displayName}',
                  imageUrl: widget.talent.photoUrl,
                  metadata: {
                    'talentId': widget.talent.accountId,
                    'reason': _reason,
                    if (note.isNotEmpty) 'message': note,
                  },
                ),
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir la demande de rendez-vous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  String _roleForTalent(TalentProfile talent) {
    if (talent.primaryRole == 'Boutique') return 'boutique';
    return 'createur';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ModernColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: ModernShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demander un rendez-vous',
              style: TextStyle(
                color: ModernColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items:
                  const [
                        'Mesure',
                        'Coiffure',
                        'Essayage',
                        'Commande',
                        'Conseil style',
                      ]
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText:
                    'Bonjour ${widget.talent.displayName}, je souhaite échanger pour $_reason.',
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Envoyer',
              onPressed: _openingChat ? null : _openAppointmentChat,
              icon: Icons.send_rounded,
              loading: _openingChat,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

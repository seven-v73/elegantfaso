import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/commerce/platform_revenue.dart';
import '../../../services/commerce/pro_access_service.dart';
import '../../../services/commerce/pro_growth_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../../services/preferences/currency_service.dart';
import 'catalogue_express_screen.dart';

class PlanVisibilityScreen extends StatefulWidget {
  const PlanVisibilityScreen({
    super.key,
    required this.role,
    required this.accent,
  });

  final String role;
  final Color accent;

  @override
  State<PlanVisibilityScreen> createState() => _PlanVisibilityScreenState();
}

class _PlanVisibilityScreenState extends State<PlanVisibilityScreen> {
  final _accessService = ProAccessService();
  final _growthService = ProGrowthService();
  final _mediaUploadService = MediaUploadService();
  final _firestore = FirebaseFirestore.instance;
  String? _usageCacheUserId;
  Future<_PlanUsage>? _usageFuture;
  String? _historyCacheUserId;
  Future<_PlanHistory>? _historyFuture;

  Future<_PlanUsage> _usageFutureFor(ProAccessState access) {
    final userId = access.userId;
    if (_usageFuture == null || _usageCacheUserId != userId) {
      _usageCacheUserId = userId;
      _usageFuture = _loadUsage(access);
    }
    return _usageFuture!;
  }

  Future<_PlanHistory> _historyFutureFor(String? userId) {
    if (_historyFuture == null || _historyCacheUserId != userId) {
      _historyCacheUserId = userId;
      _historyFuture = _loadHistory(userId);
    }
    return _historyFuture!;
  }

  void _refreshPlanData() {
    _usageFuture = null;
    _historyFuture = null;
    if (mounted) setState(() {});
  }

  Future<_PlanUsage> _loadUsage(ProAccessState access) async {
    final userId = access.userId;
    if (userId == null) return _PlanUsage.empty;
    final results = await Future.wait<int>([
      _accessService.countOwnedProducts(userId),
      _accessService.countOwnedCreations(userId),
      _accessService.countOwnedCommunities(userId),
      _countEventsThisMonth(userId),
    ]);
    return _PlanUsage(
      products: results[0],
      creations: results[1],
      communities: results[2],
      eventsThisMonth: results[3],
    );
  }

  Future<int> _countEventsThisMonth(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    final snapshot =
        await _firestore
            .collection('events')
            .where('organizerId', isEqualTo: userId)
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('createdAt', isLessThan: Timestamp.fromDate(end))
            .limit(60)
            .get();
    return snapshot.size;
  }

  Future<_PlanHistory> _loadHistory(String? userId) async {
    if (userId == null) return _PlanHistory.empty;
    final planRequests =
        await _firestore
            .collection('pro_upgrade_requests')
            .where('userId', isEqualTo: userId)
            .limit(8)
            .get();
    final boosts =
        await _firestore
            .collection('boost_campaigns')
            .where('ownerId', isEqualTo: userId)
            .limit(8)
            .get();
    final entries = <_HistoryEntry>[
      ...planRequests.docs.map(
        (doc) => _HistoryEntry.fromMap(doc.data(), fallbackLabel: 'Plan'),
      ),
      ...boosts.docs.map(
        (doc) =>
            _HistoryEntry.fromMap(doc.data(), fallbackLabel: 'Mise en avant'),
      ),
    ];
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _PlanHistory(entries.take(8).toList());
  }

  Future<void> _requestPlan({
    required String plan,
    required double price,
    required String currency,
    required Map<String, String> paymentMethods,
  }) async {
    final draft = await _collectPaymentProof(
      title: plan == 'premium' ? 'Plan Signature' : 'Plan Pro',
      amount: price,
      currency: currency,
      description:
          'Payez sur un compte ElegantStyle, puis ajoutez la capture. La demande ira en vérification admin.',
      paymentMethods: paymentMethods,
    );
    if (draft == null) return;
    try {
      final upload = await _mediaUploadService.uploadImage(
        file: draft.proof,
        folder:
            'business_payment_proofs/${_growthService.currentUserId ?? 'pro'}',
        publicId: 'plan_${plan}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final reference = await _growthService.requestPlanUpgrade(
        plan: plan,
        monthlyPrice: price,
        paymentMethod: draft.paymentMethod,
        proofImageUrl: upload.optimizedUrl,
        proofMedia: upload.toMap(),
      );
      if (!mounted) return;
      _snack('Preuve envoyée. Référence admin: $reference');
      _refreshPlanData();
    } catch (e) {
      if (!mounted) return;
      _snack('Demande impossible: $e', danger: true);
    }
  }

  Future<void> _requestBoost(
    double budget,
    String currency,
    Map<String, String> paymentMethods,
  ) async {
    final draft = await _collectPaymentProof(
      title: 'Mise en avant Signature',
      amount: budget,
      currency: currency,
      description:
          'Ajoutez la preuve du paiement. Le boost démarre seulement après validation admin.',
      paymentMethods: paymentMethods,
    );
    if (draft == null) return;
    try {
      final upload = await _mediaUploadService.uploadImage(
        file: draft.proof,
        folder:
            'business_payment_proofs/${_growthService.currentUserId ?? 'pro'}',
        publicId: 'boost_${DateTime.now().millisecondsSinceEpoch}',
      );
      final reference = await _growthService.requestAccountBoost(
        sourceRole: widget.role,
        budget: budget,
        paymentMethod: draft.paymentMethod,
        proofImageUrl: upload.optimizedUrl,
        proofMedia: upload.toMap(),
      );
      if (!mounted) return;
      _snack('Preuve boost envoyée. Référence admin: $reference');
      _refreshPlanData();
    } catch (e) {
      if (!mounted) return;
      _snack('Boost impossible: $e', danger: true);
    }
  }

  Future<_BusinessPaymentDraft?> _collectPaymentProof({
    required String title,
    required double amount,
    required String currency,
    required String description,
    required Map<String, String> paymentMethods,
  }) {
    return showDialog<_BusinessPaymentDraft>(
      context: context,
      builder:
          (context) => _BusinessPaymentDialog(
            title: title,
            amount: amount,
            currency: currency,
            description: description,
            paymentMethods: paymentMethods,
          ),
    );
  }

  void _snack(String message, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: danger ? ModernColors.danger : ModernColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCatalogueExpress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CatalogueExpressScreen(role: widget.role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        backgroundColor: ModernColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Plan & visibilité'),
      ),
      body: StreamBuilder<ProAccessState>(
        stream: _accessService.watchCurrentAccess(),
        builder: (context, accessSnapshot) {
          final access = accessSnapshot.data ?? ProAccessState.guest;
          return StreamBuilder<CommerceRevenueConfig>(
            stream: _growthService.watchRevenueConfig(),
            builder: (context, configSnapshot) {
              final config =
                  configSnapshot.data ?? const CommerceRevenueConfig();
              return FutureBuilder<List<Object>>(
                future: Future.wait<Object>([
                  _usageFutureFor(access),
                  _historyFutureFor(access.userId),
                ]),
                builder: (context, usageSnapshot) {
                  final data = usageSnapshot.data;
                  final usage =
                      data != null && data.isNotEmpty
                          ? data[0] as _PlanUsage
                          : _PlanUsage.empty;
                  final history =
                      data != null && data.length > 1
                          ? data[1] as _PlanHistory
                          : _PlanHistory.empty;
                  return ListView(
                    cacheExtent: 900,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _PlanHero(
                        access: access,
                        accent: widget.accent,
                        onPro:
                            () => _requestPlan(
                              plan: 'pro',
                              price: config.proMonthlyPrice,
                              currency: config.currency,
                              paymentMethods: config.platformPaymentMethods,
                            ),
                        onSignature:
                            () => _requestPlan(
                              plan: 'premium',
                              price: config.premiumMonthlyPrice,
                              currency: config.currency,
                              paymentMethods: config.platformPaymentMethods,
                            ),
                      ),
                      const SizedBox(height: 14),
                      _PlanDecisionPanel(
                        access: access,
                        accent: widget.accent,
                        boostPrice: config.boostBasePrice,
                        currency: config.currency,
                        onPro:
                            () => _requestPlan(
                              plan: 'pro',
                              price: config.proMonthlyPrice,
                              currency: config.currency,
                              paymentMethods: config.platformPaymentMethods,
                            ),
                        onSignature:
                            () => _requestPlan(
                              plan: 'premium',
                              price: config.premiumMonthlyPrice,
                              currency: config.currency,
                              paymentMethods: config.platformPaymentMethods,
                            ),
                        onBoost:
                            () => _requestBoost(
                              config.boostBasePrice,
                              config.currency,
                              config.platformPaymentMethods,
                            ),
                      ),
                      const SizedBox(height: 14),
                      _UsageGrid(access: access, usage: usage),
                      const SizedBox(height: 18),
                      _HistoryPanel(history: history),
                      const SizedBox(height: 18),
                      _PlanDetailsExpansion(
                        children: [
                          _PremiumPositioningPanel(
                            access: access,
                            accent: widget.accent,
                            proPrice: config.proMonthlyPrice,
                            signaturePrice: config.premiumMonthlyPrice,
                            currency: config.currency,
                            onCatalogueExpress: _openCatalogueExpress,
                            onSignature:
                                () => _requestPlan(
                                  plan: 'premium',
                                  price: config.premiumMonthlyPrice,
                                  currency: config.currency,
                                  paymentMethods: config.platformPaymentMethods,
                                ),
                          ),
                          const SizedBox(height: 14),
                          _BenefitsPanel(access: access),
                          const SizedBox(height: 14),
                          _SignatureShowcasePanel(access: access),
                          const SizedBox(height: 14),
                          _VisibilityPanel(
                            access: access,
                            boostPrice: config.boostBasePrice,
                            currency: config.currency,
                            onBoost:
                                () => _requestBoost(
                                  config.boostBasePrice,
                                  config.currency,
                                  config.platformPaymentMethods,
                                ),
                          ),
                          const SizedBox(height: 14),
                          _StatsPreview(access: access, usage: usage),
                          const SizedBox(height: 14),
                          _SeasonalPacksPanel(
                            access: access,
                            boostPrice: config.boostBasePrice,
                            currency: config.currency,
                            onSignature:
                                () => _requestPlan(
                                  plan: 'premium',
                                  price: config.premiumMonthlyPrice,
                                  currency: config.currency,
                                  paymentMethods: config.platformPaymentMethods,
                                ),
                            onBoost:
                                () => _requestBoost(
                                  config.boostBasePrice,
                                  config.currency,
                                  config.platformPaymentMethods,
                                ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BusinessPaymentDraft {
  const _BusinessPaymentDraft({
    required this.paymentMethod,
    required this.proof,
  });

  final String paymentMethod;
  final File proof;
}

class _BusinessPaymentDialog extends StatefulWidget {
  const _BusinessPaymentDialog({
    required this.title,
    required this.amount,
    required this.currency,
    required this.description,
    required this.paymentMethods,
  });

  final String title;
  final double amount;
  final String currency;
  final String description;
  final Map<String, String> paymentMethods;

  @override
  State<_BusinessPaymentDialog> createState() => _BusinessPaymentDialogState();
}

class _BusinessPaymentDialogState extends State<_BusinessPaymentDialog> {
  final _picker = ImagePicker();
  late String _selectedMethod;
  File? _proof;

  Map<String, String> get _methods {
    if (widget.paymentMethods.isNotEmpty) return widget.paymentMethods;
    return const {
      'Paiement admin ElegantStyle':
          'Configurez le numéro dans Admin > Commerce',
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedMethod = _methods.keys.first;
  }

  Future<void> _pickProof(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 86);
    if (picked == null || !mounted) return;
    setState(() => _proof = File(picked.path));
  }

  void _submit() {
    final proof = _proof;
    if (proof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez une capture du dépôt avant d’envoyer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _BusinessPaymentDraft(paymentMethod: _selectedMethod, proof: proof),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentNumber = _methods[_selectedMethod] ?? '';
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.description),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ModernColors.surfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ModernColors.line),
              ),
              child: Text(
                CurrencyService.format(widget.amount, code: widget.currency),
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Moyen de paiement',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              items:
                  _methods.keys
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => setState(() => _selectedMethod = value ?? ''),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ModernColors.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ModernColors.line),
              ),
              child: Text(
                paymentNumber,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pickProof(ImageSource.gallery),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ModernColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ModernColors.line),
                ),
                child:
                    _proof == null
                        ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              color: ModernColors.primary,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ajouter la preuve du paiement',
                              style: TextStyle(
                                color: ModernColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        )
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_proof!, fit: BoxFit.cover),
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickProof(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galerie'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickProof(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Caméra'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Envoyer preuve'),
        ),
      ],
    );
  }
}

class _PlanDecisionPanel extends StatelessWidget {
  const _PlanDecisionPanel({
    required this.access,
    required this.accent,
    required this.boostPrice,
    required this.currency,
    required this.onPro,
    required this.onSignature,
    required this.onBoost,
  });

  final ProAccessState access;
  final Color accent;
  final double boostPrice;
  final String currency;
  final VoidCallback onPro;
  final VoidCallback onSignature;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    final model = _PlanDecisionModel.fromAccess(
      access,
      boostPrice: boostPrice,
      currency: currency,
      onPro: onPro,
      onSignature: onSignature,
      onBoost: onBoost,
    );
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: model.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(model.icon, color: model.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (model.actionLabel != null && model.onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: model.onAction,
                icon: Icon(model.actionIcon, size: 18),
                label: Text(model.actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanDecisionModel {
  const _PlanDecisionModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.actionLabel,
    this.actionIcon = Icons.arrow_forward_rounded,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  factory _PlanDecisionModel.fromAccess(
    ProAccessState access, {
    required double boostPrice,
    required String currency,
    required VoidCallback onPro,
    required VoidCallback onSignature,
    required VoidCallback onBoost,
  }) {
    if (access.pendingPlan) {
      return const _PlanDecisionModel(
        title: 'Validation admin en cours',
        subtitle:
            'Votre preuve est en attente. Les avantages seront activés après validation.',
        icon: Icons.hourglass_top_rounded,
        color: ModernColors.warning,
      );
    }
    if (access.hasExpiredPlan) {
      return _PlanDecisionModel(
        title: 'Plan expiré',
        subtitle: 'Renouvelez pour retrouver vos avantages pro.',
        icon: Icons.event_busy_rounded,
        color: ModernColors.danger,
        actionLabel: 'Renouveler',
        actionIcon: Icons.refresh_rounded,
        onAction: access.expiredPlanLabel == 'Signature' ? onSignature : onPro,
      );
    }
    if (!access.hasBusinessPlan) {
      return _PlanDecisionModel(
        title: 'Activer votre espace pro',
        subtitle: 'Pro pour publier plus, Signature pour booster.',
        icon: Icons.workspace_premium_rounded,
        color: ModernColors.primary,
        actionLabel: 'Passer Pro',
        actionIcon: Icons.verified_rounded,
        onAction: onPro,
      );
    }
    if (access.isPro) {
      return _PlanDecisionModel(
        title: 'Pro actif',
        subtitle:
            'Passez Signature pour accéder aux boosts et à la vitrine avancée.',
        icon: Icons.verified_rounded,
        color: ModernColors.success,
        actionLabel: 'Passer Signature',
        actionIcon: Icons.diamond_rounded,
        onAction: onSignature,
      );
    }
    if (access.hasPendingBoost) {
      return const _PlanDecisionModel(
        title: 'Boost en validation',
        subtitle: 'La mise en avant démarrera après validation du paiement.',
        icon: Icons.schedule_rounded,
        color: ModernColors.warning,
      );
    }
    if (access.hasActiveBoost) {
      final suffix =
          access.boostEndsAt == null
              ? ''
              : ' jusqu’au ${_shortDate(access.boostEndsAt!)}';
      return _PlanDecisionModel(
        title: 'Boost actif',
        subtitle: 'Votre vitrine est mise en avant$suffix.',
        icon: Icons.trending_up_rounded,
        color: ModernColors.success,
      );
    }
    if (access.hasExpiredBoost) {
      return _PlanDecisionModel(
        title: 'Boost expiré',
        subtitle: 'Relancez une mise en avant quand vous avez une nouveauté.',
        icon: Icons.history_toggle_off_rounded,
        color: ModernColors.warning,
        actionLabel: 'Relancer boost',
        actionIcon: Icons.trending_up_rounded,
        onAction: onBoost,
      );
    }
    return _PlanDecisionModel(
      title: 'Signature active',
      subtitle:
          '${CurrencyService.format(boostPrice, code: currency)} pour 7 jours de visibilité renforcée.',
      icon: Icons.diamond_rounded,
      color: ModernColors.creator,
      actionLabel: 'Booster 7 jours',
      actionIcon: Icons.trending_up_rounded,
      onAction: onBoost,
    );
  }

  static String _shortDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }
}

class _PlanDetailsExpansion extends StatelessWidget {
  const _PlanDetailsExpansion({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.tune_rounded, color: ModernColors.primary),
          title: const Text(
            'Détails et avantages',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: const Text(
            'Plans, boost, stats et packs',
            style: TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

class _PremiumPositioningPanel extends StatelessWidget {
  const _PremiumPositioningPanel({
    required this.access,
    required this.accent,
    required this.proPrice,
    required this.signaturePrice,
    required this.currency,
    required this.onCatalogueExpress,
    required this.onSignature,
  });

  final ProAccessState access;
  final Color accent;
  final double proPrice;
  final double signaturePrice;
  final String currency;
  final VoidCallback onCatalogueExpress;
  final VoidCallback onSignature;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Plans pro',
            subtitle: 'Gérer. Être choisi.',
          ),
          const SizedBox(height: 14),
          _PlanPromiseCard(
            icon: Icons.inventory_2_rounded,
            title: 'Plan Pro',
            price: CurrencyService.format(proPrice, code: currency),
            color: accent,
            active: access.isPro || access.isSignature,
            lines: const [
              'Publier plus vite et plus souvent',
              'Badge certifié dans les parcours clés',
              'Communautés, agenda et stats essentielles',
            ],
          ),
          const SizedBox(height: 10),
          _PlanPromiseCard(
            icon: Icons.diamond_rounded,
            title: 'Plan Signature',
            price: CurrencyService.format(signaturePrice, code: currency),
            color: ModernColors.creator,
            active: access.isSignature,
            lines: const [
              'Vitrine immersive et éléments épinglés',
              'Boosts transparents de 7 jours',
              'Analytics, packs saisonniers et priorité Salon',
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCatalogueExpress,
                  icon: const Icon(Icons.auto_awesome_motion_rounded),
                  label: const Text('Catalogue Express'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: access.isSignature ? null : onSignature,
                  icon: const Icon(Icons.diamond_rounded, size: 18),
                  label: Text(access.isSignature ? 'Actif' : 'Signature'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanPromiseCard extends StatelessWidget {
  const _PlanPromiseCard({
    required this.icon,
    required this.title,
    required this.price,
    required this.color,
    required this.active,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final String price;
  final Color color;
  final bool active;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.55) : ModernColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
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
                        title,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_rounded, color: color, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: ModernColors.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SignatureShowcasePanel extends StatelessWidget {
  const _SignatureShowcasePanel({required this.access});

  final ProAccessState access;

  @override
  Widget build(BuildContext context) {
    final locked = !access.isSignature;
    return AppCard(
      padding: EdgeInsets.zero,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 128,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: ModernColors.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    locked ? Icons.lock_rounded : Icons.play_circle_rounded,
                    color: Colors.white70,
                    size: 34,
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vitrine Signature',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Cover vidéo, univers visuel et sélection éditoriale',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: const [
                _SignatureFeatureLine(
                  icon: Icons.push_pin_rounded,
                  title: 'Sélection épinglée',
                  subtitle: 'Pièce signature, nouveauté, sur mesure.',
                ),
                SizedBox(height: 10),
                _SignatureFeatureLine(
                  icon: Icons.auto_stories_rounded,
                  title: 'Mini-story permanente',
                  subtitle: 'Atelier visible.',
                ),
                SizedBox(height: 10),
                _SignatureFeatureLine(
                  icon: Icons.palette_rounded,
                  title: 'Ambiance personnalisée',
                  subtitle: 'Couleurs et spécialité.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureFeatureLine extends StatelessWidget {
  const _SignatureFeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ModernColors.creator.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: ModernColors.creator, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanHero extends StatelessWidget {
  const _PlanHero({
    required this.access,
    required this.accent,
    required this.onPro,
    required this.onSignature,
  });

  final ProAccessState access;
  final Color accent;
  final VoidCallback onPro;
  final VoidCallback onSignature;

  @override
  Widget build(BuildContext context) {
    final color = access.isSignature ? ModernColors.creator : accent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernColors.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  access.isSignature
                      ? Icons.diamond_rounded
                      : Icons.workspace_premium_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      access.planLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      access.hasBusinessPlan
                          ? access.badgeLabel
                          : access.pendingPlan
                          ? 'Activation en attente'
                          : 'Profil visible avec limites de base',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (access.hasCertifiedBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            access.isSignature
                ? 'Signature active.'
                : access.isPro
                ? 'Pro actif.'
                : 'Activez votre vitrine pro.',
            style: const TextStyle(
              color: Colors.white,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: access.isPro || access.isSignature ? null : onPro,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ModernColors.ink,
                  ),
                  child: const Text('Passer Pro'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: access.isSignature ? null : onSignature,
                  style: FilledButton.styleFrom(
                    backgroundColor: ModernColors.creator,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Signature'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageGrid extends StatelessWidget {
  const _UsageGrid({required this.access, required this.usage});

  final ProAccessState access;
  final _PlanUsage usage;

  @override
  Widget build(BuildContext context) {
    final items = [
      _UsageItem(
        icon: AppIcons.shop,
        label: 'Produits',
        used: usage.products,
        limit: access.limits.productLimit,
        color: ModernColors.shop,
      ),
      _UsageItem(
        icon: AppIcons.creations,
        label: 'Créations',
        used: usage.creations,
        limit: access.limits.creationLimit,
        color: ModernColors.creator,
      ),
      _UsageItem(
        icon: Icons.groups_3_rounded,
        label: 'Communautés',
        used: usage.communities,
        limit: access.limits.communityLimit,
        color: ModernColors.primary,
      ),
      _UsageItem(
        icon: AppIcons.calendar,
        label: 'Événements/mois',
        used: usage.eventsThisMonth,
        limit: access.limits.eventLimitPerMonth,
        color: ModernColors.accent,
      ),
      _UsageItem(
        icon: Icons.photo_library_rounded,
        label: 'Photos par fiche',
        used: access.limits.photosPerItem,
        limit: access.limits.photosPerItem,
        color: ModernColors.rose,
        showAsCapacity: true,
      ),
      _UsageItem(
        icon: Icons.push_pin_rounded,
        label: 'À la une',
        used: access.limits.featuredSlots,
        limit: access.limits.featuredSlots,
        color: ModernColors.success,
        showAsCapacity: true,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.28,
      children: items,
    );
  }
}

class _UsageItem extends StatelessWidget {
  const _UsageItem({
    required this.icon,
    required this.label,
    required this.used,
    required this.limit,
    required this.color,
    this.showAsCapacity = false,
  });

  final IconData icon;
  final String label;
  final int used;
  final int limit;
  final Color color;
  final bool showAsCapacity;

  @override
  Widget build(BuildContext context) {
    final ratio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(13),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                showAsCapacity ? '$limit' : '$used/$limit',
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: showAsCapacity ? 1 : ratio,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsPanel extends StatelessWidget {
  const _BenefitsPanel({required this.access});

  final ProAccessState access;

  @override
  Widget build(BuildContext context) {
    final benefits = [
      _Benefit('Badge certifié', access.hasCertifiedBadge),
      _Benefit('Communautés autonomes', access.canCreateCommunity),
      _Benefit('Agenda professionnel', access.canCreateAgendaEvent),
      _Benefit('Statistiques essentielles', access.canUseBasicAnalytics),
      _Benefit('Boost prioritaire', access.canBoost),
      _Benefit('Vitrine éditoriale', access.canCustomizeShowcase),
      _Benefit('Analytics 7/30 jours', access.canUseAdvancedAnalytics),
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Avantages débloqués',
            subtitle: 'Actifs aujourd’hui',
          ),
          const SizedBox(height: 12),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(
                    benefit.enabled
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    color:
                        benefit.enabled
                            ? ModernColors.success
                            : ModernColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit.label,
                      style: TextStyle(
                        color:
                            benefit.enabled
                                ? ModernColors.ink
                                : ModernColors.inkSoft,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityPanel extends StatelessWidget {
  const _VisibilityPanel({
    required this.access,
    required this.boostPrice,
    required this.currency,
    required this.onBoost,
  });

  final ProAccessState access;
  final double boostPrice;
  final String currency;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ModernColors.creator.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: ModernColors.creator,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mise en avant Signature',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  access.isSignature
                      ? '${CurrencyService.format(boostPrice, code: currency)} / 7 jours.'
                      : 'Réservé Signature.',
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: access.isSignature ? onBoost : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(92, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Booster'),
          ),
        ],
      ),
    );
  }
}

class _StatsPreview extends StatelessWidget {
  const _StatsPreview({required this.access, required this.usage});

  final ProAccessState access;
  final _PlanUsage usage;

  @override
  Widget build(BuildContext context) {
    final locked = !access.canUseBasicAnalytics;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            padding: EdgeInsets.zero,
            title: access.isSignature ? 'Analyses Signature' : 'Stats Pro',
            subtitle:
                locked
                    ? 'Réservé Pro.'
                    : access.isSignature
                    ? 'Vue avancée.'
                    : 'Vue simple.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Catalogue',
                  value: '${usage.products + usage.creations}',
                  locked: locked,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Espaces',
                  value: '${usage.communities}',
                  locked: locked,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: 'Agenda',
                  value: '${usage.eventsThisMonth}',
                  locked: locked,
                ),
              ),
            ],
          ),
          if (access.isSignature) ...[
            const SizedBox(height: 12),
            const Text(
              'Astuce: publiez une pièce forte cette semaine.',
              style: TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.locked,
  });

  final String label;
  final String value;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        children: [
          Icon(
            locked ? Icons.lock_rounded : Icons.insights_rounded,
            color: locked ? ModernColors.muted : ModernColors.primary,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            locked ? '-' : value,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalPacksPanel extends StatelessWidget {
  const _SeasonalPacksPanel({
    required this.access,
    required this.boostPrice,
    required this.currency,
    required this.onSignature,
    required this.onBoost,
  });

  final ProAccessState access;
  final double boostPrice;
  final String currency;
  final VoidCallback onSignature;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    final actionLabel =
        access.isSignature ? 'Booster 7 jours' : 'Débloquer Signature';
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Packs saisonniers',
            subtitle:
                access.isSignature
                    ? '${CurrencyService.format(boostPrice, code: currency)} par boost validé.'
                    : 'Campagnes prêtes.',
          ),
          const SizedBox(height: 12),
          _SeasonalPackRow(
            icon: Icons.celebration_rounded,
            title: 'Mariage & cérémonies',
            subtitle: 'Robes, ensembles, accessoires.',
            color: ModernColors.creator,
          ),
          const SizedBox(height: 10),
          _SeasonalPackRow(
            icon: Icons.school_rounded,
            title: 'Rentrée & bureau',
            subtitle: 'Pièces pratiques.',
            color: ModernColors.shop,
          ),
          const SizedBox(height: 10),
          _SeasonalPackRow(
            icon: Icons.local_fire_department_rounded,
            title: 'Fêtes & offres locales',
            subtitle: 'Story et vitrine.',
            color: ModernColors.warning,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: access.isSignature ? onBoost : onSignature,
              icon: Icon(
                access.isSignature
                    ? Icons.trending_up_rounded
                    : Icons.diamond_rounded,
                size: 18,
              ),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonalPackRow extends StatelessWidget {
  const _SeasonalPackRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
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
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.history});

  final _PlanHistory history;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            padding: EdgeInsets.zero,
            title: 'Demandes & paiements',
            subtitle: 'Suivi admin',
          ),
          const SizedBox(height: 12),
          if (history.entries.isEmpty)
            const Text(
              'Aucune demande enregistrée pour le moment.',
              style: TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...history.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(entry.icon, color: entry.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            entry.reference.isEmpty
                                ? entry.status
                                : '${entry.reference} · ${entry.status}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanUsage {
  const _PlanUsage({
    required this.products,
    required this.creations,
    required this.communities,
    required this.eventsThisMonth,
  });

  final int products;
  final int creations;
  final int communities;
  final int eventsThisMonth;

  static const empty = _PlanUsage(
    products: 0,
    creations: 0,
    communities: 0,
    eventsThisMonth: 0,
  );
}

class _PlanHistory {
  const _PlanHistory(this.entries);

  final List<_HistoryEntry> entries;

  static const empty = _PlanHistory([]);
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.label,
    required this.status,
    required this.reference,
    required this.createdAt,
    required this.icon,
    required this.color,
  });

  final String label;
  final String status;
  final String reference;
  final DateTime createdAt;
  final IconData icon;
  final Color color;

  factory _HistoryEntry.fromMap(
    Map<String, dynamic> data, {
    required String fallbackLabel,
  }) {
    final status = data['status']?.toString() ?? 'pending';
    final isBoost = fallbackLabel.toLowerCase().contains('avant');
    final rawPlan = data['plan']?.toString();
    final planLabel =
        rawPlan == null ? null : ProGrowthService.planDisplayLabel(rawPlan);
    return _HistoryEntry(
      label:
          data['requestLabel']?.toString() ??
          (planLabel == null ? null : 'Plan $planLabel') ??
          fallbackLabel,
      status: status,
      reference:
          data['paymentReference']?.toString() ??
          data['reference']?.toString() ??
          '',
      createdAt: _dateFrom(data['createdAt']) ?? DateTime(2000),
      icon:
          isBoost ? Icons.trending_up_rounded : Icons.workspace_premium_rounded,
      color:
          status == 'active' || status == 'approved'
              ? ModernColors.success
              : status.contains('reject')
              ? ModernColors.danger
              : ModernColors.warning,
    );
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class _Benefit {
  const _Benefit(this.label, this.enabled);

  final String label;
  final bool enabled;
}

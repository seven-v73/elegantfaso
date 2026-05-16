part of 'admin_dashboard.dart';

class _CommerceSettingsPanel extends StatefulWidget {
  const _CommerceSettingsPanel();

  @override
  State<_CommerceSettingsPanel> createState() => _CommerceSettingsPanelState();
}

class _CommerceSettingsPanelState extends State<_CommerceSettingsPanel> {
  final _revenueService = CommerceRevenueService();
  final _adminService = AdminCommerceConfigService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _settingsScrollController = ScrollController(keepScrollOffset: false);
  final _commissionController = TextEditingController();
  final _appointmentRateController = TextEditingController();
  final _appointmentFeeController = TextEditingController();
  final _boostController = TextEditingController();
  final _proController = TextEditingController();
  final _premiumController = TextEditingController();
  final _freeDeliveryThresholdController = TextEditingController();
  final _baseDeliveryFeeController = TextEditingController();
  final _serviceFeeRateController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _couponValueController = TextEditingController();
  final _couponMinController = TextEditingController();
  final _couponMaxController = TextEditingController();
  final _couponDescriptionController = TextEditingController();

  bool _saving = false;
  bool _controllersReady = false;
  String _currency = CurrencyService.defaultCode;
  Map<String, String> _platformPaymentMethods = {};
  CheckoutCouponType _couponType = CheckoutCouponType.percent;
  bool _couponActive = true;

  @override
  void dispose() {
    _settingsScrollController.dispose();
    _commissionController.dispose();
    _appointmentRateController.dispose();
    _appointmentFeeController.dispose();
    _boostController.dispose();
    _proController.dispose();
    _premiumController.dispose();
    _freeDeliveryThresholdController.dispose();
    _baseDeliveryFeeController.dispose();
    _serviceFeeRateController.dispose();
    _couponCodeController.dispose();
    _couponValueController.dispose();
    _couponMinController.dispose();
    _couponMaxController.dispose();
    _couponDescriptionController.dispose();
    super.dispose();
  }

  void _syncControllers(CommerceRevenueConfig config) {
    if (_controllersReady) return;
    _commissionController.text = _formatNumber(config.commissionRatePercent);
    _appointmentRateController.text = _formatNumber(
      config.appointmentCommissionRatePercent,
    );
    _appointmentFeeController.text = _formatNumber(config.appointmentFixedFee);
    _boostController.text = _formatNumber(config.boostBasePrice);
    _proController.text = _formatNumber(config.proMonthlyPrice);
    _premiumController.text = _formatNumber(config.premiumMonthlyPrice);
    _freeDeliveryThresholdController.text = _formatNumber(
      config.freeDeliveryThreshold,
    );
    _baseDeliveryFeeController.text = _formatNumber(config.baseDeliveryFee);
    _serviceFeeRateController.text = _formatNumber(
      config.serviceFeeRatePercent,
    );
    _platformPaymentMethods = Map<String, String>.from(
      config.platformPaymentMethods,
    );
    _currency = CurrencyService.normalize(config.currency);
    _controllersReady = true;
  }

  Future<void> _save() async {
    final nextConfig = _currentConfigFromForm();
    final currentConfig = await _revenueService.loadConfig();
    if (!mounted) return;
    final confirmed = await _confirmCommerceSave(currentConfig, nextConfig);
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      await _adminService.saveRevenueConfig(nextConfig);
      await _logCommerceConfigChange(currentConfig, nextConfig);
      if (!mounted) return;
      _showSnack('Configuration commerce enregistrée', Colors.green);
    } catch (e) {
      debugPrint('Erreur admin configuration commerce: $e');
      if (!mounted) return;
      _showSnack('Configuration impossible pour le moment', Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  CommerceRevenueConfig _currentConfigFromForm() {
    return CommerceRevenueConfig(
      commissionRatePercent: _number(_commissionController.text, 8),
      appointmentCommissionRatePercent: _number(
        _appointmentRateController.text,
        5,
      ),
      appointmentFixedFee: _number(_appointmentFeeController.text, 500),
      boostBasePrice: _number(_boostController.text, 1000),
      proMonthlyPrice: _number(_proController.text, 2500),
      premiumMonthlyPrice: _number(_premiumController.text, 7500),
      freeDeliveryThreshold: _number(
        _freeDeliveryThresholdController.text,
        25000,
      ),
      baseDeliveryFee: _number(_baseDeliveryFeeController.text, 1000),
      serviceFeeRatePercent: _number(_serviceFeeRateController.text, 1),
      currency: _currency,
      platformPaymentMethods: Map<String, String>.from(_platformPaymentMethods),
    );
  }

  Future<bool> _confirmCommerceSave(
    CommerceRevenueConfig current,
    CommerceRevenueConfig next,
  ) async {
    final changes = _commerceConfigChanges(current, next);
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmer les réglages commerce'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ces valeurs influencent checkout, commissions, forfaits et paiements admin.',
                    ),
                    const SizedBox(height: 12),
                    if (changes.isEmpty)
                      const Text('Aucun changement détecté.')
                    else
                      ...changes
                          .take(8)
                          .map(
                            (change) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.tune_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(change)),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  List<String> _commerceConfigChanges(
    CommerceRevenueConfig current,
    CommerceRevenueConfig next,
  ) {
    final changes = <String>[];
    void add(String label, Object oldValue, Object newValue) {
      if (oldValue.toString() == newValue.toString()) return;
      changes.add('$label : $oldValue → $newValue');
    }

    add('Devise', current.currency, next.currency);
    add(
      'Commission ventes',
      '${current.commissionRatePercent}%',
      '${next.commissionRatePercent}%',
    );
    add(
      'Frais service',
      '${current.serviceFeeRatePercent}%',
      '${next.serviceFeeRatePercent}%',
    );
    add('Plan Pro', current.proMonthlyPrice, next.proMonthlyPrice);
    add(
      'Plan Signature',
      current.premiumMonthlyPrice,
      next.premiumMonthlyPrice,
    );
    add('Boost', current.boostBasePrice, next.boostBasePrice);
    add('Livraison', current.baseDeliveryFee, next.baseDeliveryFee);
    add(
      'Paiements admin',
      current.platformPaymentMethods.length,
      next.platformPaymentMethods.length,
    );
    return changes;
  }

  Future<void> _logCommerceConfigChange(
    CommerceRevenueConfig current,
    CommerceRevenueConfig next,
  ) async {
    final payload = {
      'action': 'commerce_config_updated',
      'targetId': 'commerce',
      'targetType': 'platform_settings',
      'note': 'Configuration commerce mise à jour',
      'adminId': _auth.currentUser?.uid,
      'adminEmail': _auth.currentUser?.email,
      'details': {
        'changed': _commerceConfigChanges(current, next),
        'before': _commerceAuditMap(current),
        'after': _commerceAuditMap(next),
      },
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('admin_audit_logs').add({
      ...payload,
      'immutable': true,
      'auditVersion': 1,
    });
  }

  Map<String, dynamic> _commerceAuditMap(CommerceRevenueConfig config) {
    final map = config.toMap()..remove('updatedAt');
    map['platformPaymentMethods'] = config.platformPaymentMethods.map(
      (method, account) => MapEntry(method, _maskPaymentAccount(account)),
    );
    return map;
  }

  String _maskPaymentAccount(String account) {
    final cleaned = account.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length <= 4) return '****';
    return '****${cleaned.substring(cleaned.length - 4)}';
  }

  Future<void> _seedDefaults() async {
    final confirmed = await _confirmDefaultRulesPublish();
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      await _adminService.seedDefaultCheckoutRules();
      await _logCommerceAction(
        action: 'commerce_defaults_seeded',
        note: 'Règles commerce par défaut publiées',
        details: const {
          'collections': [
            'checkout_coupons',
            'platform_settings/commerce',
            'seller_subscriptions',
            'boost_campaigns',
            'platform_commissions',
          ],
        },
      );
      if (!mounted) return;
      _controllersReady = false;
      _showSnack('Règles par défaut publiées dans Firestore', Colors.green);
    } catch (e) {
      debugPrint('Erreur admin règles commerce: $e');
      if (!mounted) return;
      _showSnack('Publication impossible pour le moment', Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runBusinessLifecycleMaintenance() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Nettoyer les accès expirés ?'),
                content: const Text(
                  'Cette action marque comme expirés les plans et boosts arrivés à échéance. Elle ne valide aucun paiement.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.cleaning_services_rounded),
                    label: const Text('Nettoyer'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      final result = await _adminService.expireOverdueBusinessAccess();
      await _logCommerceAction(
        action: 'business_access_maintenance',
        note: 'Expiration manuelle des accès business',
        details: {
          'expiredPlans': result.expiredPlans,
          'expiredBoosts': result.expiredBoosts,
          'total': result.total,
        },
      );
      if (!mounted) return;
      _showSnack(
        result.total == 0
            ? 'Aucun accès expiré à nettoyer'
            : '${result.expiredPlans} plan(s), ${result.expiredBoosts} boost(s) expiré(s)',
        Colors.green,
      );
    } catch (e) {
      debugPrint('Erreur maintenance accès business: $e');
      if (!mounted) return;
      _showSnack('Maintenance impossible pour le moment', Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDefaultRulesPublish() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Publier les règles par défaut ?'),
                content: const Text(
                  'Cette action met à jour les règles commerce, coupons, forfaits et commissions de référence. Vérifiez que les valeurs actuelles vous conviennent.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Publier'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _logCommerceAction({
    required String action,
    required String note,
    Map<String, dynamic> details = const {},
  }) async {
    await _firestore.collection('admin_audit_logs').add({
      'action': action,
      'targetId': 'commerce',
      'targetType': 'platform_settings',
      'note': note,
      'adminId': _auth.currentUser?.uid,
      'adminEmail': _auth.currentUser?.email,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
      'immutable': true,
      'auditVersion': 1,
    });
  }

  Future<void> _saveCoupon() async {
    final code = _couponCodeController.text.trim().toUpperCase();
    final value = _number(_couponValueController.text, 0);
    if (code.isEmpty) {
      _showSnack('Ajoutez un code coupon.', ModernColors.danger);
      return;
    }
    if (_couponType != CheckoutCouponType.freeShipping && value <= 0) {
      _showSnack(
        'Ajoutez une valeur de réduction valide.',
        ModernColors.danger,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _adminService.upsertCoupon(
        CheckoutCouponRule(
          code: code,
          type: _couponType,
          value: _couponType == CheckoutCouponType.freeShipping ? 100 : value,
          active: _couponActive,
          minSubtotal: _number(_couponMinController.text, 0),
          maxDiscount:
              _couponMaxController.text.trim().isEmpty
                  ? null
                  : _number(_couponMaxController.text, 0),
          description: _couponDescriptionController.text.trim(),
        ),
      );
      await _logCommerceAction(
        action: 'checkout_coupon_upserted',
        note: 'Coupon checkout publié',
        details: {
          'code': code,
          'type': _couponType.name,
          'active': _couponActive,
          'value': _couponType == CheckoutCouponType.freeShipping ? 100 : value,
          'minSubtotal': _number(_couponMinController.text, 0),
        },
      );
      if (!mounted) return;
      _couponCodeController.clear();
      _couponValueController.clear();
      _couponMinController.clear();
      _couponMaxController.clear();
      _couponDescriptionController.clear();
      _showSnack('Coupon $code publié.', ModernColors.success);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Impossible de publier le coupon: $e', ModernColors.danger);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CommerceRevenueConfig>(
      stream: _revenueService.watchConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? CommerceRevenueService.fallbackConfig;
        _syncControllers(config);

        return RefreshIndicator(
          onRefresh: () async => setState(() => _controllersReady = false),
          child: ListView(
            controller: _settingsScrollController,
            primary: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              _HeaderCard(config: config),
              const SizedBox(height: 16),
              _CommerceSafetyChecklist(config: config),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Revenus marketplace',
                subtitle:
                    'Pilote la commission sur ventes, les frais RDV et les offres pro.',
                child: Column(
                  children: [
                    const _CommerceImpactPanel(
                      clientImpact:
                          'Le client voit un prix clair et une devise cohérente au checkout.',
                      sellerImpact:
                          'Le vendeur comprend ce qui sera reversé après validation.',
                      risk:
                          'Une commission mal réglée peut créer des reversements incohérents.',
                    ),
                    const SizedBox(height: 12),
                    AppSelectField<String>(
                      value: _currency,
                      items:
                          CurrencyService.options
                              .map((option) => option.code)
                              .toList(),
                      label: 'Devise plateforme',
                      icon: Icons.payments_rounded,
                      onChanged:
                          (value) => setState(
                            () => _currency = CurrencyService.normalize(value),
                          ),
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _commissionController,
                      label: 'Commission sur ventes (%)',
                      icon: Icons.percent_rounded,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _appointmentRateController,
                      label: 'Commission rendez-vous (%)',
                      icon: Icons.event_available_rounded,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _appointmentFeeController,
                      label: 'Frais fixe rendez-vous',
                      icon: Icons.payments_rounded,
                      suffix: CurrencyService.optionFor(_currency).symbol,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Checkout et livraison',
                subtitle:
                    'Règles appliquées au panier: livraison, frais service et seuil gratuité.',
                child: Column(
                  children: [
                    const _CommerceImpactPanel(
                      clientImpact:
                          'Ces règles influencent directement le total à payer.',
                      sellerImpact:
                          'Les vendeurs évitent les négociations floues sur livraison et service.',
                      risk:
                          'Des frais trop élevés peuvent bloquer la conversion au paiement.',
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _freeDeliveryThresholdController,
                      label: 'Seuil livraison offerte',
                      icon: Icons.local_shipping_rounded,
                      suffix: CurrencyService.optionFor(_currency).symbol,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _baseDeliveryFeeController,
                      label: 'Frais livraison standard',
                      icon: Icons.delivery_dining_rounded,
                      suffix: CurrencyService.optionFor(_currency).symbol,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _serviceFeeRateController,
                      label: 'Frais service checkout (%)',
                      icon: Icons.percent_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Compte de suivi paiement',
                subtitle:
                    'Moyens admin affichés au checkout avec une référence unique. Ajoutez Mobile Money, Wave, carte, banque ou tout autre canal utile.',
                child: Column(
                  children: [
                    const _CommerceImpactPanel(
                      clientImpact:
                          'Le client reçoit le bon contact de paiement selon son choix.',
                      sellerImpact:
                          'Le vendeur est rattaché à une commande traçable avant retrait.',
                      risk:
                          'Un numéro erroné peut créer un paiement perdu ou impossible à vérifier.',
                    ),
                    const SizedBox(height: 12),
                    PaymentMethodsEditor(
                      methods: _platformPaymentMethods,
                      enabled: true,
                      title: 'Paiements admin',
                      subtitle: 'Checkout plateforme',
                      emptyLabel: 'Aucun moyen admin',
                      warningLabel:
                          'Ajoutez le compte qui reçoit les paiements clients.',
                      readyLabel: 'Actif',
                      onChanged:
                          (methods) =>
                              setState(() => _platformPaymentMethods = methods),
                      availableMethods: const [
                        'Orange Money ElegantStyle',
                        'Wave ElegantStyle',
                        'Mobile Money admin',
                        'Carte / TPE',
                        'Banque',
                        'Autre canal',
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Offres Pro et visibilité',
                subtitle: 'Prix des abonnements et des mises en avant Salon.',
                child: Column(
                  children: [
                    const _CommerceImpactPanel(
                      clientImpact:
                          'Les contenus mis en avant restent identifiés comme professionnels.',
                      sellerImpact:
                          'Les comptes Pro et Signature savent ce qu’ils paient et obtiennent.',
                      risk:
                          'Un boost trop peu encadré peut donner une impression de favoritisme.',
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _boostController,
                      label: 'Mise en avant / 7 jours',
                      icon: Icons.trending_up_rounded,
                      suffix: CurrencyService.optionFor(_currency).symbol,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _proController,
                      label: 'Plan Pro mensuel',
                      icon: Icons.workspace_premium_rounded,
                      suffix: CurrencyService.optionFor(_currency).symbol,
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _premiumController,
                      label: 'Plan Signature mensuel',
                      icon: Icons.diamond_rounded,
                      suffix: CurrencyService.optionFor(_currency).symbol,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Nettoyer expirations',
                      onPressed:
                          _saving ? null : _runBusinessLifecycleMaintenance,
                      icon: Icons.cleaning_services_rounded,
                      variant: AppButtonVariant.outline,
                      expand: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Créer un coupon',
                subtitle:
                    'Publie une réduction utilisable immédiatement dans le checkout.',
                child: _CouponForm(
                  codeController: _couponCodeController,
                  valueController: _couponValueController,
                  minController: _couponMinController,
                  maxController: _couponMaxController,
                  descriptionController: _couponDescriptionController,
                  type: _couponType,
                  active: _couponActive,
                  currency: _currency,
                  saving: _saving,
                  onTypeChanged: (value) => setState(() => _couponType = value),
                  onActiveChanged:
                      (value) => setState(() => _couponActive = value),
                  onSave: _saveCoupon,
                ),
              ),
              const SizedBox(height: 16),
              _AdminCard(
                title: 'Coupons checkout',
                subtitle:
                    'Publie les coupons STYLE5, STYLE10 et FREESHIP. Les points clients restent dédiés à la visibilité Vide-dressing.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'Publier les règles par défaut',
                      onPressed: _saving ? null : _seedDefaults,
                      icon: Icons.cloud_upload_rounded,
                      variant: AppButtonVariant.outline,
                      expand: true,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Les collections utilisées sont checkout_coupons, platform_settings/commerce, seller_subscriptions, boost_campaigns et platform_commissions.',
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppStickyFormBar(
                primaryLabel: 'Enregistrer commerce',
                onPrimary: _save,
                isLoading: _saving,
              ),
            ],
          ),
        );
      },
    );
  }

  static double _number(String value, double fallback) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? fallback;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.config});

  final CommerceRevenueConfig config;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      title: 'Commerce & monétisation',
      subtitle:
          config.loadedFromFirestore
              ? 'Configuration active depuis Firestore'
              : 'Fallback local actif, publie la configuration pour piloter l’app.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetricPill(
            label: 'Commission',
            value: '${config.commissionRatePercent.toStringAsFixed(0)}%',
          ),
          _MetricPill(
            label: 'Pro',
            value: CurrencyService.format(
              config.proMonthlyPrice,
              code: config.currency,
            ),
          ),
          _MetricPill(
            label: 'Signature',
            value: CurrencyService.format(
              config.premiumMonthlyPrice,
              code: config.currency,
            ),
          ),
          _MetricPill(
            label: 'Livraison',
            value: CurrencyService.format(
              config.baseDeliveryFee,
              code: config.currency,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommerceSafetyChecklist extends StatelessWidget {
  const _CommerceSafetyChecklist({required this.config});

  final CommerceRevenueConfig config;

  @override
  Widget build(BuildContext context) {
    final methods =
        config.platformPaymentMethods.entries
            .where(
              (entry) =>
                  entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
            )
            .length;
    final items = [
      _CommerceSafetyItem(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Moyens de paiement admin',
        description:
            methods > 0
                ? '$methods moyen(s) renseigné(s) pour recevoir les paiements.'
                : 'Ajoutez au moins un numéro ou canal de paiement avant les ventes.',
        ok: methods > 0,
      ),
      _CommerceSafetyItem(
        icon: Icons.percent_rounded,
        title: 'Commission plateforme',
        description:
            config.commissionRatePercent > 0
                ? '${config.commissionRatePercent.toStringAsFixed(1)}% appliqué aux ventes marketplace.'
                : 'Aucune commission ne sera calculée sur les ventes.',
        ok: config.commissionRatePercent >= 0,
        warning: config.commissionRatePercent == 0,
      ),
      _CommerceSafetyItem(
        icon: Icons.local_shipping_rounded,
        title: 'Livraison',
        description:
            config.baseDeliveryFee >= 0
                ? 'Frais standard ${CurrencyService.format(config.baseDeliveryFee, code: config.currency)}.'
                : 'Vérifiez les frais de livraison.',
        ok: config.baseDeliveryFee >= 0,
      ),
      _CommerceSafetyItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Plans Pro / Signature',
        description:
            'Pro ${CurrencyService.format(config.proMonthlyPrice, code: config.currency)} • Signature ${CurrencyService.format(config.premiumMonthlyPrice, code: config.currency)}.',
        ok: config.proMonthlyPrice > 0 && config.premiumMonthlyPrice > 0,
      ),
    ];

    return _AdminCard(
      title: 'Checklist commerce',
      subtitle:
          'Contrôle rapide avant d’ouvrir ou de valider les paiements de la plateforme.',
      child: Column(
        children:
            items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CommerceSafetyTile(item: item),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _CommerceSafetyItem {
  const _CommerceSafetyItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.ok,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool ok;
  final bool warning;

  Color get color {
    if (!ok) return ModernColors.danger;
    if (warning) return ModernColors.warning;
    return ModernColors.success;
  }

  IconData get statusIcon {
    if (!ok) return Icons.error_rounded;
    if (warning) return Icons.warning_rounded;
    return Icons.check_circle_rounded;
  }
}

class _CommerceSafetyTile extends StatelessWidget {
  const _CommerceSafetyTile({required this.item});

  final _CommerceSafetyItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(item.statusIcon, color: item.color),
        ],
      ),
    );
  }
}

class _CommerceImpactPanel extends StatelessWidget {
  const _CommerceImpactPanel({
    required this.clientImpact,
    required this.sellerImpact,
    required this.risk,
  });

  final String clientImpact;
  final String sellerImpact;
  final String risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          _ImpactLine(
            icon: Icons.person_rounded,
            label: 'Client',
            text: clientImpact,
            color: ModernColors.client,
          ),
          const SizedBox(height: 8),
          _ImpactLine(
            icon: Icons.storefront_rounded,
            label: 'Vendeur',
            text: sellerImpact,
            color: ModernColors.shop,
          ),
          const SizedBox(height: 8),
          _ImpactLine(
            icon: Icons.shield_rounded,
            label: 'Risque',
            text: risk,
            color: ModernColors.warning,
          ),
        ],
      ),
    );
  }
}

class _ImpactLine extends StatelessWidget {
  const _ImpactLine({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$label : ',
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ModernColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: ModernColors.inkSoft, height: 1.35),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      icon: icon,
      suffixText: suffix,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

class _CouponForm extends StatelessWidget {
  const _CouponForm({
    required this.codeController,
    required this.valueController,
    required this.minController,
    required this.maxController,
    required this.descriptionController,
    required this.type,
    required this.active,
    required this.currency,
    required this.saving,
    required this.onTypeChanged,
    required this.onActiveChanged,
    required this.onSave,
  });

  final TextEditingController codeController;
  final TextEditingController valueController;
  final TextEditingController minController;
  final TextEditingController maxController;
  final TextEditingController descriptionController;
  final CheckoutCouponType type;
  final bool active;
  final String currency;
  final bool saving;
  final ValueChanged<CheckoutCouponType> onTypeChanged;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: codeController,
          label: 'Code coupon',
          hint: 'Ex: WELCOME10',
          icon: Icons.confirmation_number_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        AppSelectField<String>(
          value: type.name,
          items: const ['percent', 'fixedAmount', 'freeShipping'],
          label: 'Type de remise',
          icon: Icons.local_offer_outlined,
          onChanged: (value) {
            if (value == null) return;
            onTypeChanged(
              CheckoutCouponType.values.firstWhere(
                (item) => item.name == value,
                orElse: () => CheckoutCouponType.percent,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (type != CheckoutCouponType.freeShipping) ...[
          AppTextField(
            controller: valueController,
            label:
                type == CheckoutCouponType.percent
                    ? 'Pourcentage de remise'
                    : 'Montant de remise',
            icon:
                type == CheckoutCouponType.percent
                    ? Icons.percent_rounded
                    : Icons.payments_rounded,
            prefixText:
                type == CheckoutCouponType.percent
                    ? null
                    : '${CurrencyService.optionFor(currency).symbol} ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
        ],
        AppMoneyField(
          controller: minController,
          label: 'Minimum commande',
          currencySymbol: CurrencyService.optionFor(currency).symbol,
        ),
        const SizedBox(height: 12),
        AppMoneyField(
          controller: maxController,
          label: 'Plafond remise',
          currencySymbol: CurrencyService.optionFor(currency).symbol,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: descriptionController,
          label: 'Description',
          hint: 'Ex: 10% dès le minimum choisi',
          icon: Icons.notes_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 6),
        SwitchListTile.adaptive(
          value: active,
          onChanged: saving ? null : onActiveChanged,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Coupon actif',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text(
            'Désactivez-le pour le préparer sans l’exposer.',
          ),
          activeThumbColor: ModernColors.primary,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: 'Publier le coupon',
          onPressed: saving ? null : onSave,
          icon: Icons.publish_rounded,
          loading: saving,
          expand: true,
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: ModernColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

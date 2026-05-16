import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../design/app_icons.dart';
import '../../../design/ecommerce_widgets.dart';
import '../../../design/modern_design_system.dart';
import '../../../models/commerce/checkout_promotion.dart';
import '../../../models/commerce/platform_revenue.dart';
import '../../../models/global/cart_item.dart';
import '../../../services/commerce/commerce_revenue_service.dart';
import '../../../services/commerce/checkout_promotion_service.dart';
import '../../../services/client/client_purchase_service.dart';
import '../../../services/global/cart_service.dart';
import '../../../services/media/media_asset_service.dart';
import '../../../services/media/media_upload_service.dart';
import '../../../services/preferences/currency_service.dart';
import '../../../services/shop/checkout_service.dart';
import '../../widgets/forms/app_select_field.dart';
import '../../widgets/forms/app_text_field.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.vendor,
  });

  final List<CartItem> cartItems;
  final Vendor vendor;

  String get _currency =>
      cartItems.isEmpty
          ? CurrencyService.defaultCode
          : cartItems.first.currency;

  @override
  Widget build(BuildContext context) {
    final totals = CartService.calculateTotals(cartItems);

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Commande'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _VendorAvatar(imageUrl: vendor.photoUrl, radius: 17),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVendorHeader(context),
              const SizedBox(height: 14),
              Expanded(child: _buildProductList()),
              const SizedBox(height: 14),
              _buildTotalSection(context, totals, _currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorHeader(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          _VendorAvatar(imageUrl: vendor.photoUrl, radius: 25),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (vendor.speciality.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vendor.speciality,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon:
                          vendor.role == 'boutique'
                              ? AppIcons.boutique
                              : AppIcons.talents,
                      label:
                          vendor.role == 'boutique' ? 'Boutique' : 'Créateur',
                      color:
                          vendor.role == 'boutique'
                              ? ModernColors.shop
                              : ModernColors.creator,
                    ),
                    _MetaPill(
                      icon: Icons.people_alt_rounded,
                      label: '${vendor.followersCount} abonnés',
                      color: ModernColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return AppCard(
      padding: EdgeInsets.zero,
      elevated: false,
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: cartItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ModernColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ModernColors.line),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const _ImageFallback(),
                    errorWidget: (_, _, _) => const _ImageFallback(),
                    errorListener: (_) {},
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} x ${_CheckoutPrice.format(item.price, item.currency)}',
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _CheckoutPrice.format(
                    item.price * item.quantity,
                    item.currency,
                  ),
                  style: const TextStyle(
                    color: ModernColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalSection(
    BuildContext context,
    CartTotals totals,
    String currency,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        children: [
          _TotalLine(
            label: 'Sous-total',
            value: totals.subtotal,
            currency: currency,
          ),
          _TotalLine(
            label: 'Livraison estimée',
            value: totals.deliveryFee,
            currency: currency,
          ),
          _TotalLine(
            label: 'Frais service',
            value: totals.serviceFee,
            currency: currency,
          ),
          if (totals.discount > 0)
            _TotalLine(
              label: 'Réduction',
              value: -totals.discount,
              currency: currency,
            ),
          const Divider(height: 22),
          _TotalLine(
            label: 'Total',
            value: totals.grandTotal,
            strong: true,
            currency: currency,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Payer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CheckoutFormScreen(
                        cartItems: cartItems,
                        vendor: vendor,
                      ),
                ),
              );
            },
            icon: Icons.lock_outline_rounded,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class CheckoutFormScreen extends StatefulWidget {
  const CheckoutFormScreen({
    super.key,
    required this.cartItems,
    required this.vendor,
  });

  final List<CartItem> cartItems;
  final Vendor vendor;

  @override
  State<CheckoutFormScreen> createState() => _CheckoutFormScreenState();
}

class _CheckoutFormScreenState extends State<CheckoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientNoteController = TextEditingController();
  final _couponController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _mediaUploadService = MediaUploadService();
  final _mediaAssetService = MediaAssetService();
  final _checkoutService = CheckoutService();
  final _purchaseService = ClientPurchaseService();
  final _promotionService = CheckoutPromotionService();
  final _revenueService = CommerceRevenueService();
  File? _proofImage;
  String? _selectedPaymentMethod;
  late final String _paymentReference = CartService.generatePaymentReference();
  String _deliveryMode = 'Livraison';
  String _recipientType = 'self';
  String _appliedCoupon = '';
  double _couponDiscountAmount = 0;
  CheckoutCouponRule? _appliedCouponRule;
  double? _customDeliveryFee;
  bool _deliveryFeeTouched = false;
  late Future<CheckoutPromotionConfig> _promotionFuture;
  late Future<CommerceRevenueConfig> _revenueFuture;
  CheckoutPromotionConfig? _promotionConfig;
  CommerceRevenueConfig _revenueConfig = CommerceRevenueService.fallbackConfig;
  bool _isSubmitting = false;

  String get _currency =>
      widget.cartItems.isEmpty
          ? CurrencyService.defaultCode
          : widget.cartItems.first.currency;

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod =
        widget.vendor.paymentMethods.keys.isNotEmpty
            ? widget.vendor.paymentMethods.keys.first
            : null;
    _promotionFuture = _loadPromotions();
    _revenueFuture = _loadRevenueConfig();
    _deliveryFeeController.text = _formatFee(
      _defaultDeliveryFee(CommerceRevenueService.fallbackConfig),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _recipientNameController.dispose();
    _recipientNoteController.dispose();
    _couponController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );
    if (pickedFile == null || !mounted) return;
    setState(() => _proofImage = File(pickedFile.path));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final methods = _effectivePaymentMethods;
    final paymentMethod = _validPaymentMethodFor(methods);
    if (paymentMethod == null) {
      _showSnack('Aucun moyen de paiement configuré', ModernColors.danger);
      return;
    }
    if (_proofImage == null) {
      _showSnack(
        'Ajoutez la capture du paiement pour envoyer la commande à l’admin.',
        ModernColors.danger,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _checkoutService.validateCartItems(widget.cartItems);
      final upload = await _mediaUploadService.uploadImage(
        file: _proofImage!,
        folder: 'payment_proofs/${CartService.userId}',
        publicId:
            'proof_${CartService.userId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final orderId = await CartService.createOrder(
        items: widget.cartItems,
        vendor: widget.vendor,
        paymentMethod: paymentMethod,
        customerPhone: _phoneController.text.trim(),
        proofImageUrl: upload.optimizedUrl,
        paymentReference: _paymentReference,
        proofMedia: upload.toMap(),
        platformPaymentMethods: _revenueConfig.platformPaymentMethods,
        sellerPaymentMethods: widget.vendor.paymentMethods,
        selectedPaymentAccount: methods[paymentMethod] ?? '',
        totals: _currentTotals(),
        deliveryAddress: _addressController.text.trim(),
        deliveryMode: _deliveryMode,
        sellerNote: _noteController.text.trim(),
        recipientType: _recipientType,
        recipientName: _recipientNameController.text.trim(),
        recipientNote: _recipientNoteController.text.trim(),
      );
      try {
        await _purchaseService.recordCheckout(
          userId: CartService.userId!,
          orderId: orderId,
          items: widget.cartItems,
          recipientType: _recipientType,
          recipientName: _recipientNameController.text.trim(),
          paymentReference: _paymentReference,
        );
      } catch (_) {
        // La commande reste valide même si l'historique local est retardé.
      }
      await _mediaAssetService.recordUpload(
        upload: upload,
        ownerId: CartService.userId!,
        ownerRole: 'client',
        usage: 'payment_proof',
        status: 'private',
        linkedCollection: 'orders',
        linkedDocumentId: orderId,
        extra: {'sellerId': widget.vendor.id},
      );

      if (!mounted) return;
      _showSnack(
        'Commande $orderId envoyée. Paiement en vérification admin.',
        ModernColors.success,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('Erreur validation commande: $e');
      if (!mounted) return;
      _showSnack('Commande impossible pour le moment.', ModernColors.danger);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _copyPaymentNumber() async {
    final methods = _effectivePaymentMethods;
    final paymentMethod = _validPaymentMethodFor(methods);
    final number = paymentMethod == null ? '' : methods[paymentMethod] ?? '';
    if (number.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: number));
    _showSnack('Numéro copié', ModernColors.success);
  }

  Future<void> _copyPaymentReference() async {
    await Clipboard.setData(ClipboardData(text: _paymentReference));
    _showSnack('Référence copiée', ModernColors.success);
  }

  Future<void> _callVendor() async {
    final phone = widget.vendor.phone.trim();
    if (phone.isEmpty) {
      return;
    }
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.vendor.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) return;
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent('Bonjour, je finalise une commande ElegantStyle.')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openUssd() async {
    final paymentMethod = _validPaymentMethodFor(_effectivePaymentMethods);
    final method = paymentMethod?.toLowerCase() ?? '';
    if (!method.contains('orange')) return;
    await launchUrl(Uri.parse('tel:*144%23'));
  }

  void _showProofPreview() {
    final image = _proofImage;
    if (image == null) return;
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.file(image, fit: BoxFit.contain),
              ),
            ),
          ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _selectDeliveryMode(Set<String> value) {
    final nextMode = value.first;
    FocusManager.instance.primaryFocus?.unfocus();
    if (nextMode == _deliveryMode) return;
    setState(() => _deliveryMode = nextMode);
  }

  CartTotals _currentTotals() {
    final deliveryFee = _deliveryFeeForTotals();
    final couponDiscount =
        _appliedCouponRule?.discountFor(
          subtotal: CartService.calculateSubtotal(widget.cartItems),
          deliveryFee: deliveryFee,
        ) ??
        _couponDiscountAmount;
    return CartService.calculateTotals(
      widget.cartItems,
      couponCode: _appliedCoupon,
      couponDiscountAmount: couponDiscount,
      commissionRatePercent: _revenueConfig.commissionRatePercent,
      revenueConfig: _revenueConfig,
      deliveryFeeOverride: deliveryFee,
    );
  }

  double _deliveryFeeForTotals() {
    if (_deliveryMode == 'Retrait') return 0;
    final parsed = _parseDeliveryFee(_deliveryFeeController.text);
    return parsed ?? _customDeliveryFee ?? _revenueConfig.baseDeliveryFee;
  }

  double? _parseDeliveryFee(String value) {
    final normalized =
        value.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized)?.clamp(0, double.infinity).toDouble();
  }

  String _formatFee(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  double _defaultDeliveryFee(CommerceRevenueConfig config) {
    return CartService.calculateTotals(
      widget.cartItems,
      revenueConfig: config,
      commissionRatePercent: config.commissionRatePercent,
    ).deliveryFee;
  }

  void _syncDeliveryFeeFromConfig(CommerceRevenueConfig config) {
    if (_deliveryFeeTouched) return;
    _deliveryFeeController.text = _formatFee(_defaultDeliveryFee(config));
  }

  Future<CommerceRevenueConfig> _loadRevenueConfig() async {
    final config = await _revenueService.loadConfig();
    _revenueConfig = config;
    _syncDeliveryFeeFromConfig(config);
    return config;
  }

  Map<String, String> get _effectivePaymentMethods {
    final platformMethods = _revenueConfig.platformPaymentMethods;
    return platformMethods.isNotEmpty
        ? platformMethods
        : widget.vendor.paymentMethods;
  }

  String? _validPaymentMethodFor(Map<String, String> methods) {
    final selected = _selectedPaymentMethod;
    if (selected != null && methods.containsKey(selected)) {
      return selected;
    }
    return methods.isEmpty ? null : methods.keys.first;
  }

  void _syncSelectedPaymentMethod(String? value) {
    if (_selectedPaymentMethod == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedPaymentMethod == value) return;
      setState(() => _selectedPaymentMethod = value);
    });
  }

  bool get _usesPlatformPaymentMethods =>
      _revenueConfig.platformPaymentMethods.isNotEmpty;

  Future<CheckoutPromotionConfig> _loadPromotions() {
    return _promotionService.loadConfig(
      userId: CartService.userId,
      subtotal: CartService.calculateSubtotal(widget.cartItems),
    );
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _appliedCoupon = '';
        _couponDiscountAmount = 0;
        _appliedCouponRule = null;
      });
      return;
    }
    final config = _promotionConfig ?? await _promotionFuture;
    final subtotal = CartService.calculateSubtotal(widget.cartItems);
    final deliveryFee = _deliveryFeeForTotals();
    final coupon = await _promotionService.findCoupon(
      code: code,
      config: config,
      subtotal: subtotal,
    );
    final discount =
        coupon?.discountFor(subtotal: subtotal, deliveryFee: deliveryFee) ?? 0;
    if (!mounted) return;
    if (coupon == null || discount <= 0) {
      _showSnack(
        'Coupon indisponible ou minimum non atteint',
        ModernColors.danger,
      );
      return;
    }
    setState(() {
      _appliedCoupon = coupon.code;
      _couponDiscountAmount = discount;
      _appliedCouponRule = coupon;
    });
    _showSnack('Coupon $code appliqué', ModernColors.success);
  }

  Widget _buildPromotionSection() {
    return FutureBuilder<CheckoutPromotionConfig>(
      future: _promotionFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final config =
            snapshot.data ?? CheckoutPromotionService.fallbackConfig();
        _promotionConfig = config;
        final couponHint =
            config.coupons.isEmpty
                ? 'Code coupon'
                : config.coupons
                    .take(3)
                    .map((coupon) => coupon.code)
                    .join(', ');
        return AppCard(
          padding: const EdgeInsets.all(16),
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _couponController,
                      enabled: !loading && !_isSubmitting,
                      label: 'Code coupon',
                      hint: couponHint,
                      icon: Icons.local_offer_outlined,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppButton(
                    label: 'OK',
                    onPressed: loading || _isSubmitting ? null : _applyCoupon,
                    loading: loading,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (config.coupons.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      config.coupons.take(4).map((coupon) {
                        return ActionChip(
                          label: Text(coupon.code),
                          onPressed:
                              loading || _isSubmitting
                                  ? null
                                  : () {
                                    _couponController.text = coupon.code;
                                    _applyCoupon();
                                  },
                        );
                      }).toList(),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ModernColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      color: ModernColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${config.availablePoints} points cumulés. Ils servent à renforcer ta visibilité Vide-dressing, pas à réduire le paiement des vendeurs.',
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                config.loadedFromFirestore
                    ? 'Offres synchronisées depuis l’administration.'
                    : 'Offres par défaut actives en attendant la configuration admin.',
                style: const TextStyle(
                  color: ModernColors.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _currentTotals();
    final methods = _effectivePaymentMethods;
    final selectedPaymentMethod = _validPaymentMethodFor(methods);
    _syncSelectedPaymentMethod(selectedPaymentMethod);
    final paymentNumber =
        selectedPaymentMethod == null
            ? 'Non configuré'
            : methods[selectedPaymentMethod] ?? 'Non configuré';

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VendorSummary(vendor: widget.vendor),
                const SizedBox(height: 18),
                _SectionTitle('Moyen de paiement'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSelectField<String>(
                        value: selectedPaymentMethod,
                        items: methods.keys.toList(),
                        label: 'Méthode',
                        icon: Icons.account_balance_wallet_rounded,
                        onChanged: (value) {
                          if (_isSubmitting) return;
                          setState(() => _selectedPaymentMethod = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      _PaymentReferenceCard(
                        reference: _paymentReference,
                        onCopy: _copyPaymentReference,
                      ),
                      const SizedBox(height: 14),
                      _ManagedPaymentNotice(
                        platformConfigured: _usesPlatformPaymentMethods,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _PaymentNumber(number: paymentNumber),
                          AppButton(
                            label: 'Copier',
                            onPressed:
                                paymentNumber == 'Non configuré'
                                    ? null
                                    : _copyPaymentNumber,
                            icon: Icons.copy_rounded,
                            variant: AppButtonVariant.outline,
                            compact: true,
                          ),
                          if (widget.vendor.phone.isNotEmpty)
                            AppButton(
                              label: 'Appeler',
                              onPressed: _callVendor,
                              icon: Icons.phone_rounded,
                              variant: AppButtonVariant.outline,
                              compact: true,
                            ),
                          if (widget.vendor.phone.isNotEmpty)
                            AppButton(
                              label: 'WhatsApp',
                              onPressed: _openWhatsApp,
                              icon: Icons.chat_rounded,
                              variant: AppButtonVariant.outline,
                              compact: true,
                            ),
                          if ((selectedPaymentMethod ?? '')
                              .toLowerCase()
                              .contains('orange'))
                            AppButton(
                              label: 'USSD',
                              onPressed: _openUssd,
                              icon: Icons.dialpad_rounded,
                              variant: AppButtonVariant.outline,
                              compact: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle('Votre numéro'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  elevated: false,
                  child: AppTextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isSubmitting,
                    label: 'Votre numéro Mobile Money',
                    hint: 'Ex: 07 XX XX XX',
                    icon: Icons.phone_rounded,
                    validator: (value) {
                      final cleaned =
                          value?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
                      if (cleaned.isEmpty) {
                        return 'Veuillez entrer votre numéro';
                      }
                      if (cleaned.length < 8) return 'Numéro invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle('Réception de la commande'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choisissez comment vous voulez recevoir les articles.',
                        style: TextStyle(
                          color: ModernColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'Livraison',
                            label: Text('Livrer'),
                            icon: Icon(Icons.local_shipping_rounded),
                          ),
                          ButtonSegment(
                            value: 'Retrait',
                            label: Text('Sur place'),
                            icon: Icon(AppIcons.shop),
                          ),
                        ],
                        selected: {_deliveryMode},
                        onSelectionChanged:
                            _isSubmitting ? null : _selectDeliveryMode,
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child:
                            _deliveryMode == 'Retrait'
                                ? const _DeliveryModeHint(
                                  key: ValueKey('pickup'),
                                  icon: AppIcons.shop,
                                  title: 'Récupération sur place',
                                  message:
                                      'Aucun frais de livraison n’est ajouté. Après validation du paiement, le vendeur confirmera le lieu et le moment de récupération.',
                                )
                                : const _DeliveryModeHint(
                                  key: ValueKey('delivery'),
                                  icon: Icons.local_shipping_rounded,
                                  title: 'Livraison par le vendeur',
                                  message:
                                      'Ajoutez une zone claire. Les frais estimés sont inclus dans le total et le vendeur coordonnera la livraison.',
                                ),
                      ),
                      const SizedBox(height: 14),
                      if (_deliveryMode == 'Livraison') ...[
                        AppTextField(
                          controller: _deliveryFeeController,
                          enabled: !_isSubmitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,. ]'),
                            ),
                          ],
                          label: 'Frais de livraison estimés',
                          hint: 'Ex: 1000, 1500, 2500...',
                          suffixText: _currency,
                          icon: Icons.payments_rounded,
                          onChanged: (value) {
                            setState(() {
                              _deliveryFeeTouched = true;
                              _customDeliveryFee = _parseDeliveryFee(value);
                            });
                          },
                          validator: (value) {
                            if (_deliveryMode != 'Livraison') return null;
                            final parsed = _parseDeliveryFee(value ?? '');
                            if (parsed == null) {
                              return 'Indiquez les frais convenus ou estimés';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        const _DeliveryFeeNotice(),
                        const SizedBox(height: 14),
                      ],
                      AppTextField(
                        controller: _addressController,
                        enabled: !_isSubmitting,
                        minLines: 1,
                        maxLines: 2,
                        label:
                            _deliveryMode == 'Livraison'
                                ? 'Adresse ou zone de livraison'
                                : 'Créneau ou consigne de récupération',
                        hint:
                            _deliveryMode == 'Livraison'
                                ? 'Quartier, ville, point de repère...'
                                : 'Ex: Samedi matin, après 16h, en boutique...',
                        icon: Icons.place_rounded,
                        validator: (value) {
                          if (_deliveryMode == 'Livraison' &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Veuillez indiquer une zone de livraison';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _noteController,
                        enabled: !_isSubmitting,
                        minLines: 1,
                        maxLines: 3,
                        label: 'Note au vendeur',
                        hint:
                            'Taille, couleur, contact alternatif, préférence...',
                        icon: Icons.edit_note_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle('Destinataire'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'self',
                            label: Text('Moi-même'),
                            icon: Icon(Icons.person_rounded),
                          ),
                          ButtonSegment(
                            value: 'third_party',
                            label: Text('Un tiers'),
                            icon: Icon(Icons.card_giftcard_rounded),
                          ),
                        ],
                        selected: {_recipientType},
                        onSelectionChanged:
                            _isSubmitting
                                ? null
                                : (value) => setState(
                                  () => _recipientType = value.first,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _recipientType == 'self'
                            ? 'Après paiement, ces pièces seront ajoutées automatiquement à votre garde-robe.'
                            : 'La commande ira dans votre historique, sans entrer dans votre garde-robe personnelle.',
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_recipientType == 'third_party') ...[
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: _recipientNameController,
                          enabled: !_isSubmitting,
                          label: 'Nom du destinataire',
                          hint: 'Ex: Maman, Aminata, cadeau...',
                          icon: Icons.person_add_rounded,
                          validator: (value) {
                            if (_recipientType == 'third_party' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Indiquez à qui est destiné le produit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _recipientNoteController,
                          enabled: !_isSubmitting,
                          minLines: 1,
                          maxLines: 2,
                          label: 'Note destinataire',
                          hint: 'Taille, préférence, occasion...',
                          icon: Icons.edit_note_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle('Paiement envoyé'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _isSubmitting ? null : _pickImage,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ModernColors.line,
                              width: 1.4,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            color: ModernColors.surfaceRaised,
                          ),
                          child:
                              _proofImage == null
                                  ? const _ProofPlaceholder()
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _proofImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children: [
                          AppButton(
                            label: _proofImage == null ? 'Ajouter' : 'Changer',
                            onPressed: _isSubmitting ? null : _pickImage,
                            icon: Icons.image_rounded,
                            variant: AppButtonVariant.outline,
                            compact: true,
                          ),
                          if (_proofImage != null)
                            AppButton(
                              label: 'Voir',
                              onPressed: _showProofPreview,
                              icon: Icons.zoom_out_map_rounded,
                              variant: AppButtonVariant.outline,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Après le dépôt sur le compte de suivi ElegantStyle, ajoutez obligatoirement la capture. L’admin vérifie la preuve avec la référence unique avant de libérer le traitement vendeur.',
                        style: TextStyle(
                          color: ModernColors.inkSoft,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle('Avantages'),
                _buildPromotionSection(),
                const SizedBox(height: 18),
                FutureBuilder<CommerceRevenueConfig>(
                  future: _revenueFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != _revenueConfig) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        final nextConfig = snapshot.data!;
                        final nextMethods =
                            nextConfig.platformPaymentMethods.isNotEmpty
                                ? nextConfig.platformPaymentMethods
                                : widget.vendor.paymentMethods;
                        setState(() {
                          _revenueConfig = nextConfig;
                          _syncDeliveryFeeFromConfig(nextConfig);
                          _selectedPaymentMethod = _validPaymentMethodFor(
                            nextMethods,
                          );
                        });
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  elevated: false,
                  child: Column(
                    children: [
                      _TotalLine(
                        label: 'Sous-total',
                        value: totals.subtotal,
                        currency: _currency,
                      ),
                      _TotalLine(
                        label:
                            _deliveryMode == 'Retrait'
                                ? 'Récupération sur place'
                                : 'Livraison estimée',
                        value: totals.deliveryFee,
                        currency: _currency,
                      ),
                      _TotalLine(
                        label: 'Frais service',
                        value: totals.serviceFee,
                        currency: _currency,
                      ),
                      if (totals.discount > 0)
                        _TotalLine(
                          label: 'Réduction',
                          value: -totals.discount,
                          currency: _currency,
                        ),
                      const Divider(height: 22),
                      _TotalLine(
                        label: 'Total à payer',
                        value: totals.grandTotal,
                        strong: true,
                        currency: _currency,
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Confirmer',
                        icon: Icons.check_circle_rounded,
                        onPressed:
                            selectedPaymentMethod == null ? null : _submitForm,
                        loading: _isSubmitting,
                        expand: true,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Le vendeur prépare la commande après confirmation du paiement par l’admin. Le solde devient retirable après réception confirmée.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: ModernColors.inkSoft,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryModeHint extends StatelessWidget {
  const _DeliveryModeHint({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: ModernColors.primary),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    fontSize: 12,
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

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.imageUrl, this.radius = 24});

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    Widget fallback() => Container(
      width: size,
      height: size,
      color: ModernColors.line,
      child: Icon(AppIcons.shop, color: ModernColors.inkSoft, size: radius),
    );

    return ClipOval(
      child:
          imageUrl.isEmpty
              ? fallback()
              : CachedNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback(),
                errorWidget: (_, _, _) => fallback(),
                errorListener: (_) {},
              ),
    );
  }
}

class _VendorSummary extends StatelessWidget {
  const _VendorSummary({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          _VendorAvatar(imageUrl: vendor.photoUrl, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon:
                          vendor.role == 'boutique'
                              ? AppIcons.boutique
                              : AppIcons.talents,
                      label:
                          vendor.role == 'boutique' ? 'Boutique' : 'Créateur',
                      color:
                          vendor.role == 'boutique'
                              ? ModernColors.shop
                              : ModernColors.creator,
                    ),
                    if (vendor.speciality.isNotEmpty)
                      _MetaPill(
                        icon: Icons.badge_rounded,
                        label: vendor.speciality,
                        color: ModernColors.accent,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.currency,
    this.strong = false,
  });

  final String label;
  final double value;
  final String? currency;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: strong ? ModernColors.ink : ModernColors.inkSoft,
              fontSize: strong ? 16 : 14,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          Text(
            _CheckoutPrice.format(value, currency),
            style: TextStyle(
              color: strong ? ModernColors.primary : ModernColors.ink,
              fontSize: strong ? 20 : 14,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutPrice {
  static String format(double value, [String? currency]) =>
      CurrencyService.format(value, code: currency);
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentNumber extends StatelessWidget {
  const _PaymentNumber({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ModernColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ModernColors.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: ModernColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PaymentReferenceCard extends StatelessWidget {
  const _PaymentReferenceCard({required this.reference, required this.onCopy});

  final String reference;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ModernColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ModernColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: ModernColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Référence à mettre dans le dépôt',
                  style: TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'Copier la référence',
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

class _ManagedPaymentNotice extends StatelessWidget {
  const _ManagedPaymentNotice({required this.platformConfigured});

  final bool platformConfigured;

  @override
  Widget build(BuildContext context) {
    final color =
        platformConfigured ? ModernColors.success : ModernColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            platformConfigured
                ? Icons.shield_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              platformConfigured
                  ? 'Paiement suivi ElegantStyle: le vendeur ne peut demander un retrait qu’après réception confirmée.'
                  : 'Compte de suivi non configuré: ce moyen peut pointer vers le vendeur. Configurez les numéros admin pour activer la protection complète.',
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: ModernColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ProofPlaceholder extends StatelessWidget {
  const _ProofPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_rounded, size: 46, color: ModernColors.primary),
        SizedBox(height: 12),
        Text(
          'Ajouter une capture',
          style: TextStyle(
            fontSize: 16,
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Image de confirmation Mobile Money',
          style: TextStyle(fontSize: 13, color: ModernColors.muted),
        ),
      ],
    );
  }
}

class _DeliveryFeeNotice extends StatelessWidget {
  const _DeliveryFeeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ModernColors.warning.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: ModernColors.warning,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ces frais peuvent changer selon la distance, la ville ou le point de repère. L’admin vérifiera que le dépôt correspond au total affiché.',
              style: TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ModernColors.surfaceRaised,
      child: const Center(
        child: Icon(Icons.image_outlined, color: ModernColors.muted, size: 22),
      ),
    );
  }
}

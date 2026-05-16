part of 'createur_profile_screen.dart';

extension _CreateurProfileEditSheet on _CreateurProfileScreenState {
  void _navigateToEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditProfileBottomSheet(),
    );
  }

  Widget _buildEditProfileBottomSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ModernRadius.xl),
            ),
            child: Scaffold(
              backgroundColor: ModernColors.canvas,
              bottomNavigationBar: AppStickyFormBar(
                primaryLabel: 'Enregistrer',
                onPrimary: _saveProfileChanges,
                secondaryLabel: 'Annuler',
                onSecondary: () => Navigator.pop(context),
              ),
              body: SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: ModernColors.line,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: ModernColors.creator.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.palette_rounded,
                                    color: ModernColors.creator,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Profil créateur',
                                        style: TextStyle(
                                          color: ModernColors.ink,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Les informations visibles dans le Salon.',
                                        style: TextStyle(
                                          color: ModernColors.inkSoft,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
                      sliver: SliverList.list(
                        children: [
                          AppFormSection(
                            title: 'Identité publique',
                            subtitle:
                                'Un nom clair et une spécialité précise aident les clients à vous trouver.',
                            icon: Icons.badge_rounded,
                            children: [
                              AppTextField(
                                controller: _nameController,
                                label: 'Nom public créateur',
                                hint: 'Ex: Atelier Awa, Maison Kente...',
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _specialityController,
                                label: 'Spécialité',
                                hint:
                                    'Styliste, couture cérémonie, coiffure, accessoires...',
                                icon: Icons.workspace_premium_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _websiteController,
                                label: 'Site web ou portfolio',
                                hint: 'https://...',
                                icon: Icons.link_rounded,
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _bioController,
                                label: 'Bio',
                                hint:
                                    'Parlez de votre univers, de vos influences et de vos services.',
                                icon: Icons.notes_rounded,
                                maxLines: 4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppFormSection(
                            title: 'Localisation Salon',
                            subtitle:
                                'Ajoutez votre ville ou votre position pour apparaître sur la carte du Salon.',
                            icon: Icons.place_outlined,
                            children: [
                              AppTextField(
                                controller: _addressController,
                                label: 'Adresse ou repère',
                                hint: 'Quartier, rue, atelier, showroom...',
                                icon: Icons.location_on_outlined,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _cityController,
                                      label: 'Ville',
                                      hint: 'Ex: Abidjan, Ouagadougou...',
                                      icon: Icons.location_city_outlined,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppTextField(
                                      controller: _countryController,
                                      label: 'Pays',
                                      hint: 'Pays',
                                      icon: Icons.public_outlined,
                                      textInputAction: TextInputAction.next,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                ],
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    _isLocating
                                        ? null
                                        : () => _useCurrentLocation(
                                          setModalState: setModalState,
                                        ),
                                icon:
                                    _isLocating
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Icon(
                                          _latitude != null &&
                                                  _longitude != null
                                              ? Icons.my_location_rounded
                                              : Icons.near_me_outlined,
                                        ),
                                label: Text(
                                  _isLocating
                                      ? 'Localisation...'
                                      : _latitude != null && _longitude != null
                                      ? 'Position ajoutée à la carte'
                                      : 'Utiliser la position du téléphone',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      _latitude != null && _longitude != null
                                          ? ModernColors.primary
                                          : ModernColors.ink,
                                  side: BorderSide(
                                    color:
                                        _latitude != null && _longitude != null
                                            ? ModernColors.primary
                                            : ModernColors.line,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppFormSection(
                            title: 'Compétences',
                            subtitle:
                                'Ajoutez des mots-clés utiles : mariage, sur mesure, wax, streetwear...',
                            icon: Icons.badge_rounded,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _competenceController,
                                      label: 'Nouvelle compétence',
                                      hint: 'Ex: robes de soirée',
                                      icon: Icons.add_circle_outline_rounded,
                                      textInputAction: TextInputAction.done,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.filled(
                                    onPressed:
                                        () => _addCompetence(setModalState),
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ],
                              ),
                              _EditableChipWrap(
                                items: _competences,
                                emptyText: 'Aucune compétence ajoutée.',
                                onDeleted:
                                    (item) => setModalState(
                                      () => _competences.remove(item),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppFormSection(
                            title: 'Certifications',
                            subtitle:
                                'Facultatif, mais utile pour rassurer sur votre expertise.',
                            icon: Icons.verified_rounded,
                            children: [
                              AppTextField(
                                controller: _certifTitleController,
                                label: 'Titre',
                                hint: 'Ex: Formation modélisme',
                                icon: Icons.school_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _certifInstitutionController,
                                label: 'Établissement',
                                hint: 'Atelier, école, centre de formation...',
                                icon: Icons.account_balance_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              AppTextField(
                                controller: _certifYearController,
                                label: 'Année',
                                hint: '2026',
                                icon: Icons.calendar_month_outlined,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      () => _addCertification(setModalState),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Ajouter'),
                                ),
                              ),
                              if (_certifications.isEmpty)
                                const Text(
                                  'Aucune certification ajoutée.',
                                  style: TextStyle(color: ModernColors.inkSoft),
                                )
                              else
                                Column(
                                  children:
                                      _certifications
                                          .map(
                                            (certif) => _CertificationTile(
                                              title: certif['title'] ?? '',
                                              subtitle:
                                                  '${certif['institution'] ?? ''} • ${certif['year'] ?? ''}',
                                              onDelete:
                                                  () => setModalState(
                                                    () => _certifications
                                                        .remove(certif),
                                                  ),
                                            ),
                                          )
                                          .toList(),
                                ),
                            ],
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
      },
    );
  }

  void _navigateToPaymentSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return FractionallySizedBox(
                heightFactor: 0.72,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(ModernRadius.xl),
                  ),
                  child: Scaffold(
                    backgroundColor: ModernColors.canvas,
                    bottomNavigationBar: AppStickyFormBar(
                      primaryLabel: 'Enregistrer',
                      onPrimary: _savePaymentSettings,
                      secondaryLabel: 'Annuler',
                      onSecondary: () => Navigator.pop(context),
                    ),
                    body: SafeArea(
                      top: false,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              child: Column(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: ModernColors.line,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: ModernColors.creator
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.payments_rounded,
                                          color: ModernColors.creator,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Paiement',
                                          style: TextStyle(
                                            color: ModernColors.ink,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 116),
                            sliver: SliverList.list(
                              children: [
                                AppFormSection(
                                  title: 'Devise',
                                  icon: Icons.payments_outlined,
                                  children: [
                                    CurrencyPreferenceTile(
                                      initialCurrency: _currency,
                                      onChanged: (value) {
                                        setModalState(() => _currency = value);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                PaymentMethodsEditor(
                                  methods: _paymentMethods,
                                  title: 'Retraits créateur',
                                  subtitle: 'Canaux de règlement',
                                  emptyLabel: 'Aucun moyen de retrait',
                                  warningLabel:
                                      'Ajoutez au moins un numéro pour recevoir vos paiements.',
                                  onChanged:
                                      (methods) => setModalState(
                                        () => _paymentMethods = methods,
                                      ),
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
            },
          ),
    );
  }

  void _addCompetence(StateSetter setModalState) {
    final text = _competenceController.text.trim();
    if (text.isEmpty || _competences.contains(text)) return;
    setModalState(() {
      _competences.add(text);
      _competenceController.clear();
    });
  }

  void _addCertification(StateSetter setModalState) {
    final title = _certifTitleController.text.trim();
    final institution = _certifInstitutionController.text.trim();
    if (title.isEmpty || institution.isEmpty) return;
    setModalState(() {
      _certifications.add({
        'title': title,
        'institution': institution,
        'year': _certifYearController.text.trim(),
      });
      _certifTitleController.clear();
      _certifInstitutionController.clear();
      _certifYearController.clear();
    });
  }
}

class _EditableChipWrap extends StatelessWidget {
  const _EditableChipWrap({
    required this.items,
    required this.emptyText,
    required this.onDeleted,
  });

  final List<String> items;
  final String emptyText;
  final ValueChanged<String> onDeleted;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(color: ModernColors.inkSoft),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items
              .map(
                (item) => InputChip(
                  label: Text(item),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => onDeleted(item),
                ),
              )
              .toList(),
    );
  }
}

class _CertificationTile extends StatelessWidget {
  const _CertificationTile({
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: ModernColors.primary),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: ModernColors.danger,
          ),
        ],
      ),
    );
  }
}

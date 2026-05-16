part of 'admin_dashboard.dart';

class SalesData {
  final String month;
  final double sales;

  SalesData(this.month, this.sales);
}

class _AdminTodayItem {
  const _AdminTodayItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;
}

class _AdminAttentionSnapshot {
  const _AdminAttentionSnapshot({
    required this.orderPayments,
    required this.withdrawals,
    required this.proPlans,
    required this.boosts,
    required this.reports,
  });

  final int orderPayments;
  final int withdrawals;
  final int proPlans;
  final int boosts;
  final int reports;

  static const empty = _AdminAttentionSnapshot(
    orderPayments: 0,
    withdrawals: 0,
    proPlans: 0,
    boosts: 0,
    reports: 0,
  );

  int get total => orderPayments + withdrawals + proPlans + boosts + reports;
}

class _AdminAttentionItem {
  const _AdminAttentionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;
}

class _AdminSearchResult {
  const _AdminSearchResult({
    required this.icon,
    required this.color,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.targetId,
    required this.collection,
    required this.onOpen,
  });

  final IconData icon;
  final Color color;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String targetId;
  final String collection;
  final VoidCallback onOpen;
}

class _AdminGlobalSearchSheet extends StatefulWidget {
  const _AdminGlobalSearchSheet({required this.onSearch, required this.onCopy});

  final Future<List<_AdminSearchResult>> Function(String query) onSearch;
  final void Function(String value, String message) onCopy;

  @override
  State<_AdminGlobalSearchSheet> createState() =>
      _AdminGlobalSearchSheetState();
}

class _AdminGlobalSearchSheetState extends State<_AdminGlobalSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<_AdminSearchResult> _results = const [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String value) async {
    final query = value.trim();
    _lastQuery = query;
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final results = await widget.onSearch(query);
    if (!mounted || _lastQuery != query) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.48,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: ModernColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: ModernColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.manage_search_rounded,
                            color: ModernColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recherche admin',
                                style: TextStyle(
                                  color: ModernColors.ink,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Référence, commande, client, vendeur, produit...',
                                style: TextStyle(
                                  color: ModernColors.inkSoft,
                                  fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _runSearch,
                      onSubmitted: _runSearch,
                      decoration: InputDecoration(
                        hintText: 'Ex: PAY-2026, téléphone, email, ID...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon:
                            _controller.text.isEmpty
                                ? null
                                : IconButton(
                                  onPressed: () {
                                    _controller.clear();
                                    _runSearch('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        filled: true,
                        fillColor: ModernColors.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: ModernColors.line,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: ModernColors.line,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child:
                    _controller.text.trim().length < 2
                        ? const _AdminSearchHint()
                        : _results.isEmpty && !_loading
                        ? const _AdminSearchEmpty()
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                          itemCount: _results.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final result = _results[index];
                            return _AdminSearchResultTile(
                              result: result,
                              onCopy:
                                  () => widget.onCopy(
                                    result.targetId,
                                    'Identifiant copié',
                                  ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSearchResultTile extends StatelessWidget {
  const _AdminSearchResultTile({required this.result, required this.onCopy});

  final _AdminSearchResult result;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) => result.onOpen());
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: result.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(result.icon, color: result.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AdminStatusChip(
                          icon: Icons.folder_rounded,
                          label: result.typeLabel,
                          color: result.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.collection,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      result.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copier ID',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSearchHint extends StatelessWidget {
  const _AdminSearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Tapez au moins 2 caractères pour rechercher dans les commandes, paiements, retraits, utilisateurs, produits, créations, annonces et signalements.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AdminSearchEmpty extends StatelessWidget {
  const _AdminSearchEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Aucun résultat. Essayez une référence, un nom, un téléphone, un email ou un identifiant plus court.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ModernColors.inkSoft,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AdminWorkQueueItem {
  const _AdminWorkQueueItem({
    required this.type,
    required this.priority,
    required this.priorityLabel,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.userLabel,
    required this.statusLabel,
    required this.createdAt,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onDetail,
  });

  final String type;
  final int priority;
  final String priorityLabel;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amountLabel;
  final String userLabel;
  final String statusLabel;
  final DateTime? createdAt;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onDetail;

  String get filter {
    return switch (type) {
      'payment' => 'payments',
      'withdrawal' => 'withdrawals',
      'pro' => 'pro',
      'boost' => 'boosts',
      'dispute' => 'disputes',
      'moderation' => 'moderation',
      _ => 'all',
    };
  }
}

class _AdminWorkQueuePanel extends StatelessWidget {
  const _AdminWorkQueuePanel({
    required this.loading,
    required this.error,
    required this.items,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  final bool loading;
  final Object? error;
  final List<_AdminWorkQueueItem> items;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;

  static const _filters = [
    ('all', 'Tout', Icons.all_inbox_rounded),
    ('payments', 'Paiements', Icons.receipt_long_rounded),
    ('withdrawals', 'Retraits', Icons.account_balance_wallet_rounded),
    ('pro', 'Pro', Icons.workspace_premium_rounded),
    ('boosts', 'Boosts', Icons.trending_up_rounded),
    ('disputes', 'Litiges', Icons.report_problem_rounded),
    ('moderation', 'Modération', Icons.shield_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final visible =
        selectedFilter == 'all'
            ? items
            : items.where((item) => item.filter == selectedFilter).toList();
    final critical = items.where((item) => item.priority <= 1).length;
    final finance =
        items
            .where(
              (item) =>
                  item.filter == 'payments' || item.filter == 'withdrawals',
            )
            .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminMetricGrid(
          items: [
            _AdminMetricItem(
              label: 'À traiter',
              value: items.length.toString(),
              icon: Icons.inbox_rounded,
              color: ModernColors.primary,
            ),
            _AdminMetricItem(
              label: 'Critiques',
              value: critical.toString(),
              icon: Icons.priority_high_rounded,
              color: ModernColors.danger,
            ),
            _AdminMetricItem(
              label: 'Finance',
              value: finance.toString(),
              icon: Icons.payments_rounded,
              color: ModernColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminWorkQueueFilters(
          filters: _filters,
          selectedFilter: selectedFilter,
          items: items,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: 'Actualiser',
            onPressed: onRefresh,
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.tertiary,
            compact: true,
          ),
        ),
        const SizedBox(height: 12),
        _AdminStreamBody(
          loading: loading,
          error: error,
          empty: visible.isEmpty,
          emptyTitle:
              selectedFilter == 'all'
                  ? 'Rien à traiter'
                  : 'Aucun élément dans ce filtre',
          emptySubtitle:
              'Les paiements, retraits, activations, litiges et signalements apparaissent ici dès qu’une décision admin est nécessaire.',
          child: Column(
            children:
                visible.map((item) => _AdminWorkQueueTile(item: item)).toList(),
          ),
        ),
      ],
    );
  }
}

class _AdminWorkQueueFilters extends StatelessWidget {
  const _AdminWorkQueueFilters({
    required this.filters,
    required this.selectedFilter,
    required this.items,
    required this.onChanged,
  });

  final List<(String, String, IconData)> filters;
  final String selectedFilter;
  final List<_AdminWorkQueueItem> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children:
            filters.map((filter) {
              final selected = selectedFilter == filter.$1;
              final count =
                  filter.$1 == 'all'
                      ? items.length
                      : items.where((item) => item.filter == filter.$1).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    filter.$3,
                    size: 17,
                    color: selected ? Colors.white : ModernColors.primary,
                  ),
                  label: Text('${filter.$2}${count > 0 ? ' $count' : ''}'),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : ModernColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                  selectedColor: ModernColors.primary,
                  backgroundColor: ModernColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: ModernColors.primary.withValues(alpha: 0.14),
                  ),
                  onSelected: (_) => onChanged(filter.$1),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _AdminWorkQueueTile extends StatelessWidget {
  const _AdminWorkQueueTile({required this.item});

  final _AdminWorkQueueItem item;

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: item.color),
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
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ModernColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _AdminStatusChip(
                          icon: Icons.flag_rounded,
                          label: item.priorityLabel,
                          color: item.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.amountLabel.isNotEmpty)
                _AdminStatusChip(
                  icon: Icons.payments_rounded,
                  label: item.amountLabel,
                  color: ModernColors.success,
                ),
              _AdminStatusChip(
                icon: Icons.person_rounded,
                label: item.userLabel,
                color: ModernColors.inkSoft,
              ),
              _AdminStatusChip(
                icon: Icons.timeline_rounded,
                label: item.statusLabel,
                color: item.color,
              ),
              if (date != null)
                _AdminStatusChip(
                  icon: Icons.schedule_rounded,
                  label: DateFormat('dd/MM HH:mm').format(date),
                  color: ModernColors.muted,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: Icon(item.icon, color: Colors.white, size: 17),
                label: Text(item.primaryLabel),
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
                backgroundColor: item.color,
                side: BorderSide.none,
                onPressed: item.onPrimary,
              ),
              ActionChip(
                avatar: const Icon(
                  Icons.open_in_new_rounded,
                  color: ModernColors.primary,
                  size: 17,
                ),
                label: const Text('Détail'),
                labelStyle: const TextStyle(
                  color: ModernColors.primary,
                  fontWeight: FontWeight.w900,
                ),
                backgroundColor: ModernColors.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: ModernColors.primary.withValues(alpha: 0.14),
                ),
                onPressed: item.onDetail,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAttentionCenter extends StatelessWidget {
  const _AdminAttentionCenter({
    required this.loading,
    required this.data,
    required this.onRefresh,
    required this.onOrders,
    required this.onWithdrawals,
    required this.onProPlans,
    required this.onBoosts,
    required this.onReports,
  });

  final bool loading;
  final _AdminAttentionSnapshot data;
  final VoidCallback onRefresh;
  final VoidCallback onOrders;
  final VoidCallback onWithdrawals;
  final VoidCallback onProPlans;
  final VoidCallback onBoosts;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminAttentionItem(
        icon: Icons.receipt_long_rounded,
        title: 'Paiements commandes',
        subtitle: 'Preuves client à vérifier',
        count: data.orderPayments,
        color: ModernColors.warning,
        onTap: onOrders,
      ),
      _AdminAttentionItem(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Retraits vendeurs',
        subtitle: 'Transferts à préparer',
        count: data.withdrawals,
        color: ModernColors.success,
        onTap: onWithdrawals,
      ),
      _AdminAttentionItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Plans Pro',
        subtitle: 'Demandes à activer',
        count: data.proPlans,
        color: ModernColors.creator,
        onTap: onProPlans,
      ),
      _AdminAttentionItem(
        icon: Icons.trending_up_rounded,
        title: 'Boosts Salon',
        subtitle: 'Visibilité à lancer',
        count: data.boosts,
        color: ModernColors.client,
        onTap: onBoosts,
      ),
      _AdminAttentionItem(
        icon: Icons.shield_rounded,
        title: 'Signalements',
        subtitle: 'Confiance à protéger',
        count: data.reports,
        color: ModernColors.danger,
        onTap: onReports,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ModernColors.line),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      data.total > 0
                          ? ModernColors.warning.withValues(alpha: 0.12)
                          : ModernColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  data.total > 0
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_rounded,
                  color:
                      data.total > 0
                          ? ModernColors.warning
                          : ModernColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.total > 0
                          ? '${data.total} décision(s) à traiter'
                          : 'Cockpit à jour',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.total > 0
                          ? 'Paiements, retraits et modération regroupés au même endroit.'
                          : 'Aucune urgence opérationnelle détectée pour le moment.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                IconButton(
                  tooltip: 'Actualiser les urgences',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.sync_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount =
                  width >= 1040
                      ? 5
                      : width >= 760
                      ? 3
                      : width >= 520
                      ? 2
                      : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: crossAxisCount == 1 ? 4.25 : 2.15,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children:
                    items
                        .map(
                          (item) =>
                              _AdminAttentionTile(item: item, muted: loading),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminAttentionTile extends StatelessWidget {
  const _AdminAttentionTile({required this.item, required this.muted});

  final _AdminAttentionItem item;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final active = item.count > 0;
    return Material(
      color:
          active
              ? item.color.withValues(alpha: 0.08)
              : ModernColors.surfaceRaised,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color:
                  active
                      ? item.color.withValues(alpha: 0.22)
                      : ModernColors.line,
            ),
          ),
          child: Opacity(
            opacity: muted ? 0.62 : 1,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: active ? 0.16 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.count > 99 ? '99+' : item.count.toString(),
                  style: TextStyle(
                    color: active ? item.color : ModernColors.muted,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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

class _AdminTransactionOverview extends StatelessWidget {
  const _AdminTransactionOverview({
    required this.loading,
    required this.data,
    required this.onOrderPayments,
    required this.onPlans,
    required this.onBoosts,
    required this.onWithdrawals,
    required this.onSettings,
  });

  final bool loading;
  final _AdminAttentionSnapshot data;
  final VoidCallback onOrderPayments;
  final VoidCallback onPlans;
  final VoidCallback onBoosts;
  final VoidCallback onWithdrawals;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final pendingBusiness = data.proPlans + data.boosts;
    final items = [
      _AdminAttentionItem(
        icon: Icons.receipt_long_rounded,
        title: 'Paiements clients',
        subtitle: 'Preuves commande',
        count: data.orderPayments,
        color: ModernColors.warning,
        onTap: onOrderPayments,
      ),
      _AdminAttentionItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Plans Pro',
        subtitle: 'Comptes à activer',
        count: data.proPlans,
        color: ModernColors.creator,
        onTap: onPlans,
      ),
      _AdminAttentionItem(
        icon: Icons.trending_up_rounded,
        title: 'Boosts',
        subtitle: 'Visibilité Salon',
        count: data.boosts,
        color: ModernColors.client,
        onTap: onBoosts,
      ),
      _AdminAttentionItem(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Retraits',
        subtitle: 'Transferts vendeurs',
        count: data.withdrawals,
        color: ModernColors.success,
        onTap: onWithdrawals,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.ink,
        borderRadius: BorderRadius.circular(22),
        boxShadow: ModernShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flux transactionnel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? 'Chargement des priorités...'
                          : '${data.orderPayments} paiement(s), $pendingBusiness activation(s), ${data.withdrawals} retrait(s)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Configurer les paiements',
                onPressed: onSettings,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AdminTransactionSteps(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                childAspectRatio: wide ? 2.05 : 1.55,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children:
                    items
                        .map(
                          (item) => _AdminDarkTransactionTile(
                            item: item,
                            loading: loading,
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTransactionSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = const [
      (Icons.fact_check_rounded, 'Vérifier preuve'),
      (Icons.verified_user_rounded, 'Valider / refuser'),
      (Icons.local_shipping_rounded, 'Suivre livraison'),
      (Icons.payments_rounded, 'Transférer retrait'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children:
            steps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white,
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(step.$1, color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        step.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _AdminDarkTransactionTile extends StatelessWidget {
  const _AdminDarkTransactionTile({required this.item, required this.loading});

  final _AdminAttentionItem item;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final active = item.count > 0;
    return Material(
      color:
          active
              ? item.color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color:
                  active
                      ? item.color.withValues(alpha: 0.32)
                      : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Opacity(
            opacity: loading ? 0.58 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, color: Colors.white, size: 20),
                    const Spacer(),
                    Text(
                      item.count > 99 ? '99+' : item.count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
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

class _AdminTodayPanel extends StatelessWidget {
  const _AdminTodayPanel({required this.items});

  final List<_AdminTodayItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Aujourd’hui',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 680;
              if (wide) {
                return Row(
                  children:
                      items
                          .map(
                            (item) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: item == items.last ? 0 : 10,
                                ),
                                child: _AdminTodayTile(item: item),
                              ),
                            ),
                          )
                          .toList(),
                );
              }

              return Column(
                children:
                    items
                        .map(
                          (item) => Padding(
                            padding: EdgeInsets.only(
                              bottom: item == items.last ? 0 : 10,
                            ),
                            child: _AdminTodayTile(item: item),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminTodayTile extends StatelessWidget {
  const _AdminTodayTile({required this.item});

  final _AdminTodayItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.64),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStatusChip extends StatelessWidget {
  const _AdminStatusChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActivityLogSheet extends StatelessWidget {
  const _AdminActivityLogSheet({
    required this.activities,
    required this.emptyTitle,
  });

  final List<Map<String, dynamic>> activities;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: ModernColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ModernColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: ModernColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Journal admin',
                            style: TextStyle(
                              color: ModernColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Dernières actions et événements',
                            style: TextStyle(
                              color: ModernColors.inkSoft,
                              fontWeight: FontWeight.w700,
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
              ),
              const Divider(height: 1, color: ModernColors.line),
              Expanded(
                child:
                    activities.isEmpty
                        ? Center(
                          child: Text(
                            emptyTitle,
                            style: const TextStyle(
                              color: ModernColors.inkSoft,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                        : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: activities.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            final color =
                                activity['color'] is Color
                                    ? activity['color'] as Color
                                    : ModernColors.primary;
                            final icon =
                                activity['icon'] is IconData
                                    ? activity['icon'] as IconData
                                    : Icons.notifications_rounded;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ModernColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: ModernColors.line),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (activity['title'] ?? 'Activité')
                                              .toString(),
                                          style: const TextStyle(
                                            color: ModernColors.ink,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (activity['description'] ?? '')
                                              .toString(),
                                          style: const TextStyle(
                                            color: ModernColors.inkSoft,
                                            fontWeight: FontWeight.w600,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          (activity['subtitle'] ?? '')
                                              .toString(),
                                          style: const TextStyle(
                                            color: ModernColors.muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

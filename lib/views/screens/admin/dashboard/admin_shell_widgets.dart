part of 'admin_dashboard.dart';

class _AdminPageScaffold extends StatelessWidget {
  const _AdminPageScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.onRefresh,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ModernColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ModernColors.line),
              boxShadow: ModernShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ModernColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ModernColors.inkSoft,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AdminTinyButton extends StatelessWidget {
  const _AdminTinyButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return SizedBox(
      width: compact ? 44 : 132,
      height: 44,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          backgroundColor: ModernColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child:
            compact
                ? Icon(icon, size: 20)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _AdminMetricItem {
  const _AdminMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _AdminMetricGrid extends StatelessWidget {
  const _AdminMetricGrid({required this.items});

  final List<_AdminMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? items.length.clamp(1, 3) : 1,
          childAspectRatio: wide ? 2.4 : 4.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children:
              items.map((item) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ModernColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ModernColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.inkSoft,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}

class _AdminStreamBody extends StatelessWidget {
  const _AdminStreamBody({
    required this.loading,
    required this.error,
    required this.empty,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.child,
  });

  final bool loading;
  final Object? error;
  final bool empty;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return _AdminInfoPanel(
        icon: Icons.error_outline_rounded,
        title: 'Chargement impossible',
        subtitle: '$error',
        color: ModernColors.danger,
      );
    }
    if (empty) {
      return _AdminInfoPanel(
        icon: Icons.inbox_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
        color: ModernColors.muted,
      );
    }
    return child;
  }
}

class _AdminInfoPanel extends StatelessWidget {
  const _AdminInfoPanel({
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCardAction {
  const _AdminCardAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
}

class _AdminDetailRow {
  const _AdminDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.meta = const [],
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> meta;
  final List<_AdminCardAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ModernColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.08),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: meta),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  actions.map((action) {
                    final color =
                        action.danger
                            ? ModernColors.danger
                            : ModernColors.primary;
                    return ActionChip(
                      avatar: Icon(action.icon, color: color, size: 17),
                      label: Text(action.label),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                      backgroundColor: color.withValues(alpha: 0.08),
                      side: BorderSide(color: color.withValues(alpha: 0.14)),
                      onPressed: action.onTap,
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminTransactionDetailSheet extends StatelessWidget {
  const _AdminTransactionDetailSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rows,
    required this.timeline,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<_AdminDetailRow> rows;
  final List<ManagedPaymentTimelineEntry> timeline;
  final List<_AdminCardAction> actions;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ModernColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ModernColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copier résumé',
                    onPressed: () => _copySummary(context),
                    icon: const Icon(Icons.content_copy_rounded),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AdminInfoPanel(
                icon: Icons.security_rounded,
                title: 'Décision sensible',
                subtitle:
                    'Vérifiez la référence, les montants, la preuve et le bénéficiaire avant toute validation.',
                color: ModernColors.warning,
              ),
              const SizedBox(height: 14),
              ...rows.map((row) => _AdminDetailRowTile(row: row)),
              if (timeline.isNotEmpty) ...[
                const SizedBox(height: 14),
                _AdminTimelinePreview(timeline: timeline),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      actions.map((action) {
                        final color =
                            action.danger
                                ? ModernColors.danger
                                : ModernColors.primary;
                        return ActionChip(
                          avatar: Icon(action.icon, color: color, size: 17),
                          label: Text(action.label),
                          labelStyle: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                          backgroundColor: color.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: color.withValues(alpha: 0.14),
                          ),
                          onPressed: action.onTap,
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _copySummary(BuildContext context) {
    final buffer =
        StringBuffer()
          ..writeln(title)
          ..writeln(subtitle);
    for (final row in rows) {
      final value = row.value.trim().isEmpty ? '-' : row.value.trim();
      buffer.writeln('${row.label}: $value');
    }
    if (timeline.isNotEmpty) {
      buffer.writeln('Historique:');
      for (final entry in timeline.take(5)) {
        final at = entry.at == null ? '' : ' (${entry.at})';
        buffer.writeln('- ${entry.label}$at');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Résumé dossier copié')));
  }
}

class _AdminDetailRowTile extends StatelessWidget {
  const _AdminDetailRowTile({required this.row});

  final _AdminDetailRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          Icon(row.icon, color: ModernColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    color: ModernColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value.isEmpty ? '-' : row.value,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (row.copyable && row.value.trim().isNotEmpty)
            IconButton(
              tooltip: 'Copier',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: row.value));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('${row.label} copié')));
              },
              icon: const Icon(Icons.copy_rounded),
            ),
        ],
      ),
    );
  }
}

class _AdminTimelinePreview extends StatelessWidget {
  const _AdminTimelinePreview({required this.timeline});

  final List<ManagedPaymentTimelineEntry> timeline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique',
            style: TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          for (final entry in timeline.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.radio_button_checked_rounded,
                    color: ModernColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.at == null
                          ? entry.label
                          : '${entry.label} • ${DateFormat('dd/MM HH:mm').format(entry.at!)}',
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        fontSize: 12,
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

class _AdminCollectionPanel extends StatelessWidget {
  const _AdminCollectionPanel({
    required this.title,
    required this.subtitle,
    required this.collection,
    required this.icon,
    required this.firestore,
    required this.primaryAction,
    required this.primaryLabel,
    this.secondaryAction,
    this.secondaryLabel,
    this.dangerAction,
    this.dangerLabel,
  });

  final String title;
  final String subtitle;
  final String collection;
  final IconData icon;
  final FirebaseFirestore firestore;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> primaryAction;
  final String primaryLabel;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>?
  secondaryAction;
  final String? secondaryLabel;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>? dangerAction;
  final String? dangerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ModernColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ModernColors.primary),
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
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: ModernColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firestore.collection(collection).limit(20).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? const [];
              return _AdminStreamBody(
                loading: snapshot.connectionState == ConnectionState.waiting,
                error: snapshot.error,
                empty: docs.isEmpty,
                emptyTitle: 'Aucune donnée',
                emptySubtitle: 'Collection $collection vide pour le moment.',
                child: Column(
                  children:
                      docs.map((doc) {
                        final data = doc.data();
                        final status = _AdminDashboardState._string(
                          data,
                          'status',
                          fallback:
                              (_AdminDashboardState._string(data, 'active') ==
                                      'false')
                                  ? 'inactive'
                                  : 'active',
                        );
                        final title = _bestTitle(data, doc.id);
                        final city = _AdminDashboardState._string(
                          data,
                          'city',
                          fallback: _AdminDashboardState._string(
                            data,
                            'country',
                          ),
                        );
                        final subtitle = [
                          _AdminDashboardState._string(data, 'type'),
                          _AdminDashboardState._string(data, 'ownerName'),
                          city,
                        ].where((part) => part.isNotEmpty).join(' • ');
                        final imageUrl = _firstImage(data);
                        final views =
                            _AdminDashboardState._number(data, 'viewsCount') ??
                            _AdminDashboardState._number(data, 'viewCount') ??
                            _AdminDashboardState._number(data, 'views');
                        final saves =
                            _AdminDashboardState._number(data, 'savesCount') ??
                            _AdminDashboardState._number(
                              data,
                              'favoritesCount',
                            ) ??
                            _AdminDashboardState._number(data, 'likes');
                        final visibility = _AdminDashboardState._string(
                          data,
                          'visibility',
                          fallback:
                              _AdminDashboardState._string(data, 'isPublic') ==
                                      'true'
                                  ? 'public'
                                  : '',
                        );

                        return _AdminActionCard(
                          icon: icon,
                          title: title,
                          subtitle:
                              subtitle.isEmpty
                                  ? 'Document ${_AdminDashboardState._shortId(doc.id)}'
                                  : subtitle,
                          meta: [
                            _AdminStatusChip(
                              icon: Icons.flag_rounded,
                              label: status,
                              color: _AdminDashboardState._statusColor(status),
                            ),
                            if (visibility.isNotEmpty)
                              _AdminStatusChip(
                                icon: Icons.visibility_rounded,
                                label: visibility,
                                color: ModernColors.primary,
                              ),
                            if (views != null)
                              _AdminStatusChip(
                                icon: Icons.remove_red_eye_rounded,
                                label: '${views.round()} vues',
                                color: ModernColors.inkSoft,
                              ),
                            if (saves != null)
                              _AdminStatusChip(
                                icon: Icons.bookmark_rounded,
                                label: '${saves.round()} saves',
                                color: ModernColors.creator,
                              ),
                            if (_AdminDashboardState._string(
                              data,
                              'reference',
                              fallback: _AdminDashboardState._string(
                                data,
                                'paymentReference',
                              ),
                            ).isNotEmpty)
                              _AdminStatusChip(
                                icon: Icons.tag_rounded,
                                label: _AdminDashboardState._string(
                                  data,
                                  'reference',
                                  fallback: _AdminDashboardState._string(
                                    data,
                                    'paymentReference',
                                  ),
                                ),
                                color: ModernColors.primary,
                              ),
                            if (_AdminDashboardState._number(data, 'amount') !=
                                null)
                              _AdminStatusChip(
                                icon: Icons.payments_rounded,
                                label: _AdminDashboardState._money(
                                  _AdminDashboardState._number(data, 'amount')!,
                                ),
                                color: ModernColors.success,
                              ),
                            if (_AdminDashboardState._string(
                                  data,
                                  'featured',
                                ) ==
                                'true')
                              const _AdminStatusChip(
                                icon: Icons.push_pin_rounded,
                                label: 'Mis en avant',
                                color: ModernColors.creator,
                              ),
                          ],
                          actions: [
                            if (imageUrl.isNotEmpty)
                              _AdminCardAction(
                                label: 'Aperçu',
                                icon: Icons.image_rounded,
                                onTap:
                                    () =>
                                        _showPreview(context, title, imageUrl),
                              ),
                            _AdminCardAction(
                              label: primaryLabel,
                              icon: Icons.check_circle_rounded,
                              onTap: () => primaryAction(doc),
                            ),
                            if (secondaryAction != null &&
                                secondaryLabel != null)
                              _AdminCardAction(
                                label: secondaryLabel!,
                                icon: Icons.trending_up_rounded,
                                onTap: () => secondaryAction!(doc),
                              ),
                            if (dangerAction != null && dangerLabel != null)
                              _AdminCardAction(
                                label: dangerLabel!,
                                icon: Icons.visibility_off_rounded,
                                danger: true,
                                onTap: () => dangerAction!(doc),
                              ),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _bestTitle(Map<String, dynamic> data, String id) {
    for (final key in [
      'requestLabel',
      'title',
      'name',
      'displayName',
      'productName',
      'code',
      'reference',
    ]) {
      final value = _AdminDashboardState._string(data, key);
      if (value.isNotEmpty) return value;
    }
    return 'Élément ${_AdminDashboardState._shortId(id)}';
  }

  static String _firstImage(Map<String, dynamic> data) {
    for (final key in [
      'imageUrl',
      'coverImage',
      'coverUrl',
      'photoUrl',
      'profileImageUrl',
      'thumbnailUrl',
    ]) {
      final value = _AdminDashboardState._string(data, key);
      if (value.isNotEmpty) return value;
    }
    final images = data['images'];
    if (images is Iterable) {
      for (final image in images) {
        final value = image.toString();
        if (value.trim().isNotEmpty) return value;
      }
    }
    return '';
  }

  static void _showPreview(
    BuildContext context,
    String title,
    String imageUrl,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ModernColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ModernColors.line),
                boxShadow: ModernShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ModernColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const ColoredBox(
                              color: ModernColors.surfaceRaised,
                              child: Center(
                                child: Icon(Icons.broken_image_rounded),
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

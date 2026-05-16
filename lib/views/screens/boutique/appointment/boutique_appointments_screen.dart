import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/messages/conversation_context.dart';
import '../../../../services/notifications/app_notification_service.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../messages/chat_screen.dart';
import '../../messages/user_model.dart';
import '../widgets/boutique_status_chip.dart';

class BoutiqueAppointmentsScreen extends StatefulWidget {
  const BoutiqueAppointmentsScreen({super.key});

  @override
  State<BoutiqueAppointmentsScreen> createState() =>
      _BoutiqueAppointmentsScreenState();
}

class _BoutiqueAppointmentsScreenState
    extends State<BoutiqueAppointmentsScreen> {
  final String _boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final AppNotificationService _notificationService = AppNotificationService();
  String _selectedFilter = 'today';

  static const _filters = [
    ('today', 'Aujourd’hui'),
    ('prepare', 'À préparer'),
    ('all', 'Tous'),
    ('pending', 'À confirmer'),
    ('confirmed', 'Confirmés'),
    ('cancelled', 'Annulés'),
  ];

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _appointmentsStream() {
    if (_boutiqueId.isEmpty) return Stream.value(const []);
    final byCreator =
        FirebaseFirestore.instance
            .collection('appointments')
            .where('creatorId', isEqualTo: _boutiqueId)
            .snapshots();
    final byBoutique =
        FirebaseFirestore.instance
            .collection('appointments')
            .where('boutiqueId', isEqualTo: _boutiqueId)
            .snapshots();
    final byCreateur =
        FirebaseFirestore.instance
            .collection('appointments')
            .where('createurId', isEqualTo: _boutiqueId)
            .snapshots();

    return Rx.combineLatest3(byCreator, byBoutique, byCreateur, (
      QuerySnapshot<Map<String, dynamic>> creatorSnapshot,
      QuerySnapshot<Map<String, dynamic>> boutiqueSnapshot,
      QuerySnapshot<Map<String, dynamic>> createurSnapshot,
    ) {
      final docs =
          {
            for (final doc in creatorSnapshot.docs) doc.id: doc,
            for (final doc in boutiqueSnapshot.docs) doc.id: doc,
            for (final doc in createurSnapshot.docs) doc.id: doc,
          }.values.toList();
      docs.sort((a, b) {
        final aDate = _readDate(a.data()) ?? DateTime(9999);
        final bDate = _readDate(b.data()) ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });
      return docs;
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterAppointments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
  ) {
    if (_selectedFilter == 'all') return appointments;
    return appointments.where((doc) {
      if (_selectedFilter == 'today') {
        final date = _readDate(doc.data());
        if (date == null) return false;
        final now = DateTime.now();
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }
      final status = doc.data()['status']?.toString().toLowerCase() ?? '';
      if (_selectedFilter == 'prepare') {
        final date = _readDate(doc.data());
        if (date == null) return false;
        final now = DateTime.now();
        return status == 'confirmed' &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }
      return status == _selectedFilter;
    }).toList();
  }

  Map<String, int> _stats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
  ) {
    var pending = 0;
    var confirmed = 0;
    var cancelled = 0;
    for (final doc in appointments) {
      switch (doc.data()['status']?.toString().toLowerCase()) {
        case 'confirmed':
          confirmed++;
        case 'cancelled':
          cancelled++;
        default:
          pending++;
      }
    }
    return {
      'total': appointments.length,
      'pending': pending,
      'confirmed': confirmed,
      'cancelled': cancelled,
    };
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _appointmentsToPrepare(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
  ) {
    final now = DateTime.now();
    return appointments.where((doc) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase() ?? '';
      final date = _readDate(data);
      return status == 'confirmed' &&
          date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  Future<void> _updateAppointmentStatus(
    String appointmentId,
    String newStatus,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .set({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      await _notifyClientStatus(appointmentId, newStatus, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusSnackLabel(newStatus)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre à jour ce rendez-vous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _notifyClientStatus(
    String appointmentId,
    String newStatus,
    Map<String, dynamic> data,
  ) async {
    final clientId =
        data['clientId']?.toString() ??
        data['customerId']?.toString() ??
        data['userId']?.toString() ??
        '';
    if (clientId.isEmpty) return;

    final date = _readDate(data);
    final dateLabel =
        date == null ? '' : DateFormat('EEE d MMM • HH:mm', 'fr').format(date);
    final title = switch (newStatus) {
      'confirmed' => 'Rendez-vous confirmé',
      'cancelled' => 'Rendez-vous annulé',
      'preparing' => 'Votre rendez-vous se prépare',
      'completed' => 'Rendez-vous terminé',
      _ => 'Rendez-vous mis à jour',
    };
    final body = switch (newStatus) {
      'confirmed' =>
        dateLabel.isEmpty
            ? 'La boutique a confirmé votre rendez-vous.'
            : 'La boutique vous attend $dateLabel.',
      'cancelled' =>
        dateLabel.isEmpty
            ? 'La boutique a annulé ce rendez-vous.'
            : 'La boutique a annulé le rendez-vous du $dateLabel.',
      'preparing' => 'La boutique prépare votre passage.',
      'completed' => 'Merci pour votre passage.',
      _ => 'Votre rendez-vous a été mis à jour.',
    };

    await _notificationService.createNotification(
      recipientId: clientId,
      title: title,
      body: body,
      type: 'appointment',
      priority: newStatus == 'cancelled' ? 'high' : 'normal',
      actionLabel: 'Voir',
      route: '/notifications',
      data: {
        'targetType': 'appointment',
        'targetId': appointmentId,
        'appointmentId': appointmentId,
        'status': newStatus,
      },
    );
  }

  String _statusSnackLabel(String status) {
    return switch (status) {
      'confirmed' => 'Rendez-vous confirmé.',
      'cancelled' => 'Rendez-vous annulé.',
      'preparing' => 'Rendez-vous marqué à préparer.',
      'completed' => 'Rendez-vous terminé.',
      _ => 'Rendez-vous mis à jour.',
    };
  }

  Future<void> _openAppointmentChat(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    final clientId =
        data['clientId']?.toString() ??
        data['customerId']?.toString() ??
        data['userId']?.toString() ??
        '';
    if (_boutiqueId.isEmpty || clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client indisponible pour ce rendez-vous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final docs = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(_boutiqueId).get(),
        FirebaseFirestore.instance.collection('users').doc(clientId).get(),
      ]);
      if (!mounted) return;
      if (!docs.first.exists || !docs.last.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation indisponible.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final date = _readDate(data);
      final reason =
          data['reason']?.toString() ??
          data['message']?.toString() ??
          'Rendez-vous';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                utilisateurCourant: UserModel.fromDocument(docs.first),
                autreUtilisateur: UserModel.fromDocument(docs.last),
                currentRole: 'boutique',
                otherRole: 'client',
                conversationContext: ConversationContext(
                  type: ConversationContextTypes.appointment,
                  id: appointmentId,
                  title: reason,
                  subtitle:
                      date == null
                          ? 'Rendez-vous'
                          : DateFormat('EEE d MMM • HH:mm', 'fr').format(date),
                  metadata: {'appointmentId': appointmentId},
                ),
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir la conversation.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAppointmentDetail(String appointmentId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AppointmentDetailSheet(
            appointmentId: appointmentId,
            data: data,
            onMessage: () {
              Navigator.pop(context);
              _openAppointmentChat(appointmentId, data);
            },
            onPrepare: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointmentId, 'preparing', data);
            },
            onComplete: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointmentId, 'completed', data);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _appointmentsStream(),
        builder: (context, snapshot) {
          final allAppointments = snapshot.data ?? const [];
          final appointments = _filterAppointments(allAppointments);
          final stats = _stats(allAppointments);
          final toPrepare = _appointmentsToPrepare(allAppointments);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _AppointmentsHeader(stats: stats),
                if (toPrepare.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PrepareTodayPanel(
                    count: toPrepare.length,
                    nextData: toPrepare.first.data(),
                    onTap: () => setState(() => _selectedFilter = 'prepare'),
                  ),
                ],
                const SizedBox(height: 12),
                _FilterRail(
                  selected: _selectedFilter,
                  onSelected: (value) {
                    setState(() => _selectedFilter = value);
                  },
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _LoadingAppointments()
                else if (snapshot.hasError)
                  const _AppointmentState(
                    icon: Icons.error_outline_rounded,
                    title: 'Rendez-vous indisponibles',
                    message: 'Réessayez.',
                  )
                else if (appointments.isEmpty)
                  _AppointmentState(
                    icon: Icons.event_available_outlined,
                    title:
                        _selectedFilter == 'today'
                            ? 'Aucun rendez-vous aujourd’hui'
                            : _selectedFilter == 'all'
                            ? 'Aucun rendez-vous'
                            : 'Aucun rendez-vous pour ce filtre',
                    message:
                        _selectedFilter == 'today'
                            ? 'Planning libre.'
                            : _selectedFilter == 'all'
                            ? 'Aucune demande.'
                            : 'Aucun résultat.',
                    actionLabel: _selectedFilter == 'all' ? null : 'Voir tous',
                    onAction:
                        _selectedFilter == 'all'
                            ? null
                            : () => setState(() => _selectedFilter = 'all'),
                  )
                else
                  for (final doc in appointments) ...[
                    _AppointmentCard(
                      appointmentId: doc.id,
                      data: doc.data(),
                      onTap: () => _showAppointmentDetail(doc.id, doc.data()),
                      onConfirm:
                          () => _updateAppointmentStatus(
                            doc.id,
                            'confirmed',
                            doc.data(),
                          ),
                      onCancel:
                          () => _updateAppointmentStatus(
                            doc.id,
                            'cancelled',
                            doc.data(),
                          ),
                      onPrepare:
                          () => _updateAppointmentStatus(
                            doc.id,
                            'preparing',
                            doc.data(),
                          ),
                      onComplete:
                          () => _updateAppointmentStatus(
                            doc.id,
                            'completed',
                            doc.data(),
                          ),
                      onMessage: () => _openAppointmentChat(doc.id, doc.data()),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader({required this.stats});

  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ModernColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: ModernColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rendez-vous',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Aujourd’hui et demandes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ModernColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((stats['total'] ?? 0) > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total',
                    value: stats['total'] ?? 0,
                    color: ModernColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'Attente',
                    value: stats['pending'] ?? 0,
                    color: ModernColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'OK',
                    value: stats['confirmed'] ?? 0,
                    color: ModernColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _BoutiqueAppointmentsScreenState._filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _BoutiqueAppointmentsScreenState._filters[index];
          return ChoiceChip(
            label: Text(filter.$2),
            selected: filter.$1 == selected,
            onSelected: (_) => onSelected(filter.$1),
          );
        },
      ),
    );
  }
}

class _PrepareTodayPanel extends StatelessWidget {
  const _PrepareTodayPanel({
    required this.count,
    required this.nextData,
    required this.onTap,
  });

  final int count;
  final Map<String, dynamic> nextData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clientName =
        nextData['clientName']?.toString() ??
        nextData['customerName']?.toString() ??
        'Client';
    final date = _readDate(nextData);
    final timeLabel =
        date == null ? '' : DateFormat('HH:mm', 'fr').format(date);
    return AppCard(
      onTap: onTap,
      color: ModernColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.room_service_outlined,
              color: ModernColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count à préparer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeLabel.isEmpty ? clientName : '$timeLabel • $clientName',
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
          const Icon(Icons.chevron_right_rounded, color: ModernColors.inkSoft),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointmentId,
    required this.data,
    required this.onTap,
    required this.onConfirm,
    required this.onCancel,
    required this.onPrepare,
    required this.onComplete,
    required this.onMessage,
  });

  final String appointmentId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onPrepare;
  final VoidCallback onComplete;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final clientName =
        data['clientName']?.toString() ??
        data['customerName']?.toString() ??
        'Client';
    final clientEmail = data['clientEmail']?.toString() ?? '';
    final reason =
        data['reason']?.toString() ??
        data['message']?.toString() ??
        'Motif non précisé';
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final date = _readDate(data);
    final formattedDate =
        date == null
            ? 'Date à préciser'
            : DateFormat('EEE d MMM • HH:mm', 'fr').format(date);
    final productLabel = _appointmentProductLabel(data);
    final intentionLabel = _appointmentIntentionLabel(data);
    final statusMeta = switch (status) {
      'confirmed' => ('Confirmé', ModernColors.success, Icons.check_rounded),
      'preparing' => (
        'À préparer',
        ModernColors.primary,
        Icons.room_service_outlined,
      ),
      'completed' ||
      'done' => ('Terminé', ModernColors.inkSoft, Icons.done_all_rounded),
      'cancelled' => ('Annulé', ModernColors.rose, Icons.close_rounded),
      _ => ('À confirmer', ModernColors.accent, Icons.schedule_rounded),
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ModernColors.canvas,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: ModernColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      clientEmail.isEmpty ? formattedDate : clientEmail,
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
              BoutiqueStatusChip(
                label: statusMeta.$1,
                color: statusMeta.$2,
                icon: statusMeta.$3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: ModernColors.inkSoft,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ModernColors.inkSoft),
          ),
          if (productLabel.isNotEmpty || intentionLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (productLabel.isNotEmpty)
                  _ContextPill(
                    icon: Icons.shopping_bag_outlined,
                    label: productLabel,
                  ),
                if (intentionLabel.isNotEmpty)
                  _ContextPill(
                    icon: Icons.auto_awesome_motion_outlined,
                    label: intentionLabel,
                  ),
              ],
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Confirmer',
                    onPressed: onConfirm,
                    icon: Icons.check_rounded,
                    expand: true,
                  ),
                ),
                const SizedBox(width: 10),
                AppIconAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Message',
                  onPressed: onMessage,
                ),
                const SizedBox(width: 8),
                AppOverflowMenu(
                  actions: [
                    AppOverflowAction(
                      label: 'Annuler',
                      icon: Icons.close_rounded,
                      danger: true,
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label:
                        status == 'confirmed'
                            ? 'Préparer'
                            : status == 'preparing'
                            ? 'Terminer'
                            : 'Message',
                    onPressed:
                        status == 'confirmed'
                            ? onPrepare
                            : status == 'preparing'
                            ? onComplete
                            : onMessage,
                    icon:
                        status == 'confirmed'
                            ? Icons.room_service_outlined
                            : status == 'preparing'
                            ? Icons.done_all_rounded
                            : Icons.chat_bubble_outline_rounded,
                    expand: true,
                  ),
                ),
                if (status == 'confirmed' || status == 'preparing') ...[
                  const SizedBox(width: 10),
                  AppIconAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    tooltip: 'Message',
                    onPressed: onMessage,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ModernColors.inkSoft),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailSheet extends StatelessWidget {
  const _AppointmentDetailSheet({
    required this.appointmentId,
    required this.data,
    required this.onMessage,
    required this.onPrepare,
    required this.onComplete,
  });

  final String appointmentId;
  final Map<String, dynamic> data;
  final VoidCallback onMessage;
  final VoidCallback onPrepare;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final clientName =
        data['clientName']?.toString() ??
        data['customerName']?.toString() ??
        'Client';
    final status = data['status']?.toString().toLowerCase() ?? 'pending';
    final date = _readDate(data);
    final productLabel = _appointmentProductLabel(data);
    final productImage = _appointmentProductImage(data);
    final intentionLabel = _appointmentIntentionLabel(data);
    final reason =
        data['reason']?.toString() ??
        data['message']?.toString() ??
        'Rendez-vous';
    final notes = data['notes']?.toString() ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: ModernColors.surface,
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ModernColors.canvas,
                    child: Text(
                      clientName.characters.take(1).toString().toUpperCase(),
                      style: const TextStyle(
                        color: ModernColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date == null
                              ? 'Date à préciser'
                              : DateFormat(
                                'EEEE d MMMM • HH:mm',
                                'fr',
                              ).format(date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: ModernColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (productLabel.isNotEmpty || intentionLabel.isNotEmpty)
                AppCard(
                  padding: const EdgeInsets.all(12),
                  color: ModernColors.canvas,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          image:
                              productImage.isEmpty
                                  ? null
                                  : DecorationImage(
                                    image: NetworkImage(productImage),
                                    fit: BoxFit.cover,
                                  ),
                        ),
                        child:
                            productImage.isEmpty
                                ? const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: ModernColors.primary,
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productLabel.isEmpty ? 'Intention' : productLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ModernColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (intentionLabel.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                intentionLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ModernColors.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              _DetailRow(label: 'Motif', value: reason),
              _DetailRow(label: 'Notes', value: notes),
              _DetailRow(
                label: 'Email',
                value: data['clientEmail']?.toString() ?? '',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Message'),
                    ),
                  ),
                  if (status == 'confirmed') ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onPrepare,
                        icon: const Icon(Icons.room_service_outlined),
                        label: const Text('Préparer'),
                      ),
                    ),
                  ] else if (status == 'preparing') ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('Terminer'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingAppointments extends StatelessWidget {
  const _LoadingAppointments();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 132,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentState extends StatelessWidget {
  const _AppointmentState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppActionEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      accent: ModernColors.primary,
    );
  }
}

String _appointmentProductLabel(Map<String, dynamic> data) {
  for (final key in const [
    'productName',
    'productTitle',
    'productLabel',
    'creationTitle',
    'creationName',
    'itemName',
    'articleName',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  final product = data['product'];
  if (product is Map) {
    for (final key in const ['name', 'title', 'label']) {
      final value = product[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

String _appointmentProductImage(Map<String, dynamic> data) {
  for (final key in const [
    'productImage',
    'productImageUrl',
    'creationImage',
    'imageUrl',
    'coverImage',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  final product = data['product'];
  if (product is Map) {
    for (final key in const ['imageUrl', 'coverImage', 'photoUrl']) {
      final value = product[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

String _appointmentIntentionLabel(Map<String, dynamic> data) {
  for (final key in const [
    'intention',
    'intent',
    'service',
    'appointmentType',
    'type',
    'category',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value != 'appointment') return value;
  }
  return '';
}

DateTime? _readDate(Map<String, dynamic> data) {
  final raw = data['date'] ?? data['startAt'] ?? data['scheduledAt'];
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

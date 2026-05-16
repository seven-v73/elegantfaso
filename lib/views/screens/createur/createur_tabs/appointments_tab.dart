import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/account_roles.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_appointment.dart';
import '../../../../services/createur/creator_appointment_service.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../messages/messages_entry_screen.dart';
import '../widgets/creator_appointment_card.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key, required this.user});

  final User user;

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  final CreatorAppointmentService _service = CreatorAppointmentService();
  String _filter = 'today';

  static const _filters = [
    ('today', 'Aujourd’hui'),
    ('prepare', 'À préparer'),
    ('pending', 'Demandes'),
    ('confirmed', 'Confirmés'),
    ('all', 'Tous'),
    ('completed', 'Terminés'),
    ('availability', 'Dispo.'),
  ];

  List<CreatorAppointment> _filterAppointments(
    List<CreatorAppointment> appointments,
  ) {
    if (_filter == 'all') {
      return appointments.where((appointment) => !appointment.isDone).toList();
    }
    if (_filter == 'today') {
      return appointments
          .where((appointment) => appointment.isToday && !appointment.isDone)
          .toList();
    }
    if (_filter == 'prepare') {
      return appointments
          .where(
            (appointment) =>
                appointment.isToday &&
                (appointment.isConfirmed || appointment.isPreparing),
          )
          .toList();
    }
    return appointments
        .where((appointment) => appointment.status == _filter)
        .toList();
  }

  List<CreatorAppointment> _appointmentsToPrepare(
    List<CreatorAppointment> appointments,
  ) {
    return appointments
        .where(
          (appointment) =>
              appointment.isToday &&
              (appointment.isConfirmed || appointment.isPreparing),
        )
        .toList();
  }

  Future<void> _next(CreatorAppointment appointment) async {
    await _service.updateStatus(appointment.id, appointment.nextStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rendez-vous : ${appointment.nextActionLabel}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _cancel(CreatorAppointment appointment) async {
    await _service.updateStatus(appointment.id, 'cancelled');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rendez-vous annulé.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDetail(CreatorAppointment appointment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AppointmentDetailSheet(
            appointment: appointment,
            onNext: () {
              Navigator.pop(context);
              _next(appointment);
            },
            onCancel: () {
              Navigator.pop(context);
              _cancel(appointment);
            },
            onMessage: () {
              Navigator.pop(context);
              _openMessages();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_filter == 'availability') {
      return _AvailabilityView(
        creatorId: widget.user.uid,
        service: _service,
        onBack: () => setState(() => _filter = 'all'),
      );
    }

    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: StreamBuilder<List<CreatorAppointment>>(
        stream: _service.watchAppointments(widget.user.uid),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const [];
          final appointments = _filterAppointments(all);
          final todayCount =
              all.where((appointment) => appointment.isToday).length;
          final pendingCount =
              all.where((appointment) => appointment.isPending).length;
          final toPrepare = _appointmentsToPrepare(all);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _AppointmentsHeader(
                  todayCount: todayCount,
                  pendingCount: pendingCount,
                  totalCount: all.length,
                ),
                if (toPrepare.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PreparePanel(
                    count: toPrepare.length,
                    onTap: () => setState(() => _filter = 'prepare'),
                  ),
                ],
                const SizedBox(height: 12),
                _FilterRail(
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const _LoadingAppointments()
                else if (snapshot.hasError)
                  const _AppointmentState(
                    icon: Icons.error_outline_rounded,
                    title: 'Rendez-vous indisponibles',
                    message: 'Impossible de charger votre pipeline.',
                  )
                else if (appointments.isEmpty)
                  _AppointmentState(
                    icon: Icons.event_busy_rounded,
                    title:
                        _filter == 'all'
                            ? 'Aucun rendez-vous'
                            : 'Aucun rendez-vous pour ce filtre',
                    message:
                        _filter == 'today'
                            ? 'Planning libre.'
                            : _filter == 'all'
                            ? 'Aucune demande active.'
                            : 'Essayez un autre statut ou revenez à tous les rendez-vous.',
                    actionLabel:
                        _filter == 'all' ? 'Ouvrir la messagerie' : 'Voir tous',
                    onAction:
                        _filter == 'all'
                            ? _openMessages
                            : () => setState(() => _filter = 'all'),
                  )
                else
                  for (final appointment in appointments) ...[
                    CreatorAppointmentCard(
                      appointment: appointment,
                      onTap: () => _showDetail(appointment),
                      onNext: () => _next(appointment),
                      onCancel: () => _cancel(appointment),
                      onMessage: _openMessages,
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

  void _openMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                const MessagesEntryScreen(roleOverride: AccountRoles.createur),
      ),
    );
  }
}

class _AppointmentsHeader extends StatelessWidget {
  const _AppointmentsHeader({
    required this.todayCount,
    required this.pendingCount,
    required this.totalCount,
  });

  final int todayCount;
  final int pendingCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rendez-vous',
            style: TextStyle(
              color: ModernColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aujourd’hui et demandes',
            style: TextStyle(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Aujourd’hui',
                  value: todayCount,
                  color: ModernColors.client,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'À confirmer',
                  value: pendingCount,
                  color: ModernColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Total',
                  value: totalCount,
                  color: ModernColors.creator,
                ),
              ),
            ],
          ),
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

class _PreparePanel extends StatelessWidget {
  const _PreparePanel({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      elevated: false,
      color: ModernColors.creator.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ModernColors.creator.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              color: ModernColors.creator,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count RDV à préparer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: ModernColors.inkSoft),
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
        itemCount: _AppointmentsTabState._filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _AppointmentsTabState._filters[index];
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

class _AppointmentDetailSheet extends StatelessWidget {
  const _AppointmentDetailSheet({
    required this.appointment,
    required this.onNext,
    required this.onCancel,
    required this.onMessage,
  });

  final CreatorAppointment appointment;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final date = appointment.date;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
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
              Text(
                appointment.clientName,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                date == null
                    ? 'Date non définie'
                    : DateFormat('EEEE d MMMM yyyy • HH:mm', 'fr').format(date),
                style: const TextStyle(color: ModernColors.inkSoft),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'Statut', value: appointment.statusLabel),
              _DetailRow(label: 'Motif', value: appointment.reason),
              _DetailRow(label: 'Notes', value: appointment.notes),
              _DetailRow(label: 'Email', value: appointment.clientEmail),
              const SizedBox(height: 12),
              AppButton(
                label: appointment.nextActionLabel,
                onPressed:
                    appointment.isCancelled || appointment.isDone
                        ? null
                        : onNext,
                icon: Icons.check_rounded,
                expand: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Message',
                      onPressed: onMessage,
                      icon: Icons.chat_bubble_outline_rounded,
                      variant: AppButtonVariant.secondary,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AppOverflowMenu(
                    actions: [
                      AppOverflowAction(
                        label: 'Annuler',
                        icon: Icons.close_rounded,
                        danger: true,
                        onPressed:
                            appointment.isCancelled || appointment.isDone
                                ? null
                                : onCancel,
                      ),
                    ],
                  ),
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
    if (value.isEmpty) return const SizedBox.shrink();
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ModernColors.inkSoft),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
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

class _AvailabilityView extends StatefulWidget {
  const _AvailabilityView({
    required this.creatorId,
    required this.service,
    required this.onBack,
  });

  final String creatorId;
  final CreatorAppointmentService service;
  final VoidCallback onBack;

  @override
  State<_AvailabilityView> createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<_AvailabilityView> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dayKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Disponibilités',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, _) {
              setState(() => _selectedDay = selectedDay);
            },
            locale: 'fr_FR',
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: ModernColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: ModernColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, bool>>(
          stream: widget.service.watchAvailability(widget.creatorId, dayKey),
          builder: (context, snapshot) {
            final availability = snapshot.data ?? const {};
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(24, (index) {
                final hour = index ~/ 2 + 8;
                final minute = (index % 2) * 30;
                final timeKey =
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                final isAvailable = availability[timeKey] ?? false;
                return _SlotChip(
                  label: timeKey,
                  selected: isAvailable,
                  onTap:
                      () => widget.service.setAvailability(
                        creatorId: widget.creatorId,
                        dayKey: dayKey,
                        timeKey: timeKey,
                        available: !isAvailable,
                      ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: ModernColors.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? ModernColors.primary : ModernColors.inkSoft,
        fontWeight: FontWeight.w800,
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
            height: 142,
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
      accent: ModernColors.creator,
    );
  }
}

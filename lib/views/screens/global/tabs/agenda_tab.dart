import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/account_roles.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/events/event_filter.dart';
import '../../../../models/events/salon_event.dart';
import '../../../../services/commerce/pro_access_service.dart';
import '../../../../services/events/event_registration_service.dart';
import '../../../../services/events/event_reminder_service.dart';
import '../../../../services/events/salon_event_service.dart';
import '../../../../services/preferences/currency_service.dart';
import '../widgets/events/event_calendar_strip.dart';
import '../widgets/events/event_card.dart';
import '../widgets/events/event_detail_sheet.dart';
import '../widgets/events/event_filter_rail.dart';

class AgendaTab extends StatefulWidget {
  const AgendaTab({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab>
    with AutomaticKeepAliveClientMixin {
  final SalonEventService _eventService = SalonEventService();
  final ProAccessService _accessService = ProAccessService();
  final EventRegistrationService _registrationService =
      EventRegistrationService();
  final EventReminderService _reminderService = EventReminderService();
  final AccountRoleService _roleService = AccountRoleService();

  String _selectedFilter = 'Tous';
  String _query = '';
  bool _showCalendar = false;
  bool _canCreateEvents = false;

  static const _filters = [
    EventFilterItem('Tous', AppIcons.calendar),
    EventFilterItem('Aujourd’hui', Icons.today_rounded),
    EventFilterItem('Cette semaine', Icons.date_range_rounded),
    EventFilterItem('Près de moi', Icons.near_me_rounded),
    EventFilterItem('Mode', Icons.run_circle_rounded),
    EventFilterItem('Beauté', Icons.content_cut_rounded),
    EventFilterItem('Live', Icons.live_tv_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _loadCreateEligibility();
  }

  @override
  void didUpdateWidget(covariant AgendaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextQuery = widget.initialQuery.trim();
    if (oldWidget.initialQuery.trim() != nextQuery) {
      setState(() => _query = nextQuery);
    }
  }

  EventFilter get _filter => EventFilter(label: _selectedFilter, query: _query);

  Future<void> _refresh() async {
    setState(() {});
    await _loadCreateEligibility();
    await _eventService.loadEvents(limit: 20);
  }

  Future<bool> _computeCreateEligibility() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final roleState = await _roleService.getCurrentState();
    final access = await _accessService.getCurrentAccess();
    final hasBusinessRole =
        roleState?.hasRole(AccountRoles.createur) == true ||
        roleState?.hasRole(AccountRoles.boutique) == true;
    return hasBusinessRole && access.canCreateAgendaEvent;
  }

  Future<void> _loadCreateEligibility() async {
    final canCreate = await _computeCreateEligibility();
    if (!mounted) return;
    setState(() => _canCreateEvents = canCreate);
  }

  void _showLoginRequired() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Connexion requise',
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'La réservation et les rappels demandent un compte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ModernColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _openEvent(SalonEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => EventDetailSheet(
            event: event,
            registrationService: _registrationService,
            reminderService: _reminderService,
            onLoginRequired: _showLoginRequired,
          ),
    );
  }

  Future<void> _toggleReminder(SalonEvent event) async {
    if (_reminderService.currentUserId == null) {
      _showLoginRequired();
      return;
    }
    try {
      await _reminderService.addReminder(event);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rappel activé.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => _reminderService.removeReminder(event.id),
          ),
        ),
      );
    } catch (_) {
      if (mounted) _showLoginRequired();
    }
  }

  void _showEventsForDate(DateTime day) {
    setState(() {
      _selectedFilter = 'Tous';
      _query = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Événements du ${day.day}/${day.month}/${day.year}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showCreateEventCta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequired();
      return;
    }
    final roleState = await _roleService.getCurrentState();
    final access = await _accessService.getCurrentAccess();
    final hasBusinessRole =
        roleState?.hasRole(AccountRoles.createur) == true ||
        roleState?.hasRole(AccountRoles.boutique) == true;
    if (!hasBusinessRole || !access.canCreateAgendaEvent) {
      if (!mounted) return;
      _showProRequired();
      return;
    }
    if (!_canCreateEvents) setState(() => _canCreateEvents = true);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ModernColors.surface,
      builder:
          (_) => _CreateEventSheet(
            eventService: _eventService,
            access: access,
            ownerId: user.uid,
            ownerName: user.displayName ?? user.email ?? '',
            onCreated: () {
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Événement publié dans l’Agenda du Salon.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
    );
  }

  void _showProRequired() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: ModernColors.creator,
                      size: 34,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Agenda réservé Pro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Les comptes Pro publient des ateliers et ventes privées. Signature ajoute la mise en avant dans l’Agenda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ModernColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<SalonEvent>>(
      stream: _eventService.watchEvents(_filter),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <SalonEvent>[];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            key: const PageStorageKey('salon_events_tab'),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const _AgendaLoading()
              else if (snapshot.hasError)
                _AgendaState(
                  icon: Icons.error_outline_rounded,
                  title: 'Agenda indisponible',
                  message:
                      'Impossible de charger les événements pour le moment.',
                  onRetry: _refresh,
                )
              else ...[
                _AgendaHero(
                  events: events,
                  onCreateEvent: _showCreateEventCta,
                  canCreateEvent: _canCreateEvents,
                ),
                if (_query.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _AgendaContextPill(
                    query: _query,
                    onClear: () => setState(() => _query = ''),
                  ),
                ],
                const SizedBox(height: 14),
                EventFilterRail(
                  filters: _filters,
                  selected: _selectedFilter,
                  onSelected:
                      (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(height: 12),
                _AgendaModeBar(
                  showCalendar: _showCalendar,
                  onToggleCalendar:
                      () => setState(() => _showCalendar = !_showCalendar),
                  onCreateEvent: _showCreateEventCta,
                  canCreateEvent: _canCreateEvents,
                ),
                if (_showCalendar) ...[
                  const SizedBox(height: 12),
                  EventCalendarStrip(
                    events: events,
                    onDateSelected: _showEventsForDate,
                  ),
                ],
                const SizedBox(height: 18),
                if (events.isEmpty)
                  _AgendaState(
                    icon: Icons.event_busy_rounded,
                    title: 'Aucun événement trouvé',
                    message:
                        _query.isEmpty
                            ? 'Aucun temps fort ne correspond à ce filtre.'
                            : 'Essaie une recherche plus simple ou un autre filtre.',
                    onRetry: _refresh,
                    onExplore:
                        () => setState(() {
                          _selectedFilter = 'Tous';
                          _query = '';
                        }),
                    onCreate: _canCreateEvents ? _showCreateEventCta : null,
                  )
                else
                  _EventSections(
                    events: events,
                    onOpenEvent: _openEvent,
                    onReminder: _toggleReminder,
                    onCreateEvent: _showCreateEventCta,
                    canCreateEvent: _canCreateEvents,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _AgendaHero extends StatelessWidget {
  const _AgendaHero({
    required this.events,
    required this.onCreateEvent,
    required this.canCreateEvent,
  });

  final List<SalonEvent> events;
  final VoidCallback onCreateEvent;
  final bool canCreateEvent;

  @override
  Widget build(BuildContext context) {
    final featured = events.isEmpty ? null : events.first;
    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: ModernColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: ModernColors.shop,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featured == null ? 'Agenda mode' : 'Prochain temps fort',
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  featured == null
                      ? 'Défilés, ateliers, pop-up, castings et lives du Salon.'
                      : '${featured.title} • ${featured.dateLabel}',
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
          if (canCreateEvent) ...[
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onCreateEvent,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaContextPill extends StatelessWidget {
  const _AgendaContextPill({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevated: false,
      child: Row(
        children: [
          const Icon(AppIcons.search, size: 18, color: ModernColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ModernColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Effacer',
            visualDensity: VisualDensity.compact,
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AgendaModeBar extends StatelessWidget {
  const _AgendaModeBar({
    required this.showCalendar,
    required this.onToggleCalendar,
    required this.onCreateEvent,
    required this.canCreateEvent,
  });

  final bool showCalendar;
  final VoidCallback onToggleCalendar;
  final VoidCallback onCreateEvent;
  final bool canCreateEvent;

  @override
  Widget build(BuildContext context) {
    if (!canCreateEvent) {
      return _AgendaModeButton(
        icon:
            showCalendar
                ? Icons.view_agenda_rounded
                : Icons.calendar_month_rounded,
        label: showCalendar ? 'Timeline' : 'Calendrier',
        onTap: onToggleCalendar,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _AgendaModeButton(
            icon:
                showCalendar
                    ? Icons.view_agenda_rounded
                    : Icons.calendar_month_rounded,
            label: showCalendar ? 'Timeline' : 'Calendrier',
            onTap: onToggleCalendar,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AgendaModeButton(
            icon: Icons.add_rounded,
            label: 'Créer',
            filled: true,
            onTap: onCreateEvent,
          ),
        ),
      ],
    );
  }
}

class _AgendaModeButton extends StatelessWidget {
  const _AgendaModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onTap,
      icon: icon,
      variant: filled ? AppButtonVariant.primary : AppButtonVariant.outline,
      compact: true,
    );
  }
}

class _EventSections extends StatelessWidget {
  const _EventSections({
    required this.events,
    required this.onOpenEvent,
    required this.onReminder,
    required this.onCreateEvent,
    required this.canCreateEvent,
  });

  final List<SalonEvent> events;
  final ValueChanged<SalonEvent> onOpenEvent;
  final ValueChanged<SalonEvent> onReminder;
  final VoidCallback onCreateEvent;
  final bool canCreateEvent;

  @override
  Widget build(BuildContext context) {
    final plan = _dayPlan(events);
    final timeline = events.take(30).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlanOfDayCard(
          events: plan,
          onOpenEvent: onOpenEvent,
          onCreateEvent: onCreateEvent,
          canCreateEvent: canCreateEvent,
        ),
        const SizedBox(height: 18),
        _AgendaTimelineTabs(events: events),
        const SizedBox(height: 18),
        SectionHeader(padding: EdgeInsets.zero, title: 'Timeline'),
        const SizedBox(height: 12),
        for (final event in timeline) ...[
          EventCard(
            event: event,
            onTap: () => onOpenEvent(event),
            onReminder: () => onReminder(event),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<SalonEvent> _dayPlan(List<SalonEvent> events) {
    final picked = <SalonEvent>[];
    void addWhere(bool Function(SalonEvent event) test) {
      SalonEvent? event;
      for (final candidate in events) {
        if (test(candidate)) {
          event = candidate;
          break;
        }
      }
      final selected = event;
      if (selected != null && !picked.any((item) => item.id == selected.id)) {
        picked.add(selected);
      }
    }

    addWhere((event) => event.isToday);
    addWhere((event) => event.isShopping || event.targetsClients);
    addWhere((event) => event.isBeauty || event.targetsCreators);
    for (final event in events) {
      if (picked.length >= 3) break;
      if (!picked.any((item) => item.id == event.id)) picked.add(event);
    }
    return picked.take(3).toList();
  }
}

class _PlanOfDayCard extends StatelessWidget {
  const _PlanOfDayCard({
    required this.events,
    required this.onOpenEvent,
    required this.onCreateEvent,
    required this.canCreateEvent,
  });

  final List<SalonEvent> events;
  final ValueChanged<SalonEvent> onOpenEvent;
  final VoidCallback onCreateEvent;
  final bool canCreateEvent;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ModernColors.accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: ModernColors.shop,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Plan du jour prêt dès qu’un événement est publié.',
                style: TextStyle(
                  color: ModernColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      elevated: true,
      color: ModernColors.accent.withValues(alpha: .06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: ModernColors.shop),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Plan du jour',
                  style: TextStyle(
                    color: ModernColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (canCreateEvent)
                AppButton(
                  label: 'Créer',
                  onPressed: onCreateEvent,
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.tertiary,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < events.length; i++) ...[
            _PlanStep(
              index: i + 1,
              event: events[i],
              onTap: () => onOpenEvent(events[i]),
            ),
            if (i != events.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.index,
    required this.event,
    required this.onTap,
  });

  final int index;
  final SalonEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: ModernColors.shop,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ModernColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.dateLabel} · ${event.timeLabel} · ${event.formatLabel}',
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
              const Icon(
                Icons.chevron_right_rounded,
                color: ModernColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaTimelineTabs extends StatelessWidget {
  const _AgendaTimelineTabs({required this.events});

  final List<SalonEvent> events;

  @override
  Widget build(BuildContext context) {
    final today = events.where((event) => event.isToday).length;
    final week = events.where((event) => event.isThisWeek).length;
    final upcoming = events.where((event) => !event.isToday).length;
    return Row(
      children: [
        Expanded(
          child: _TimelineStat(
            label: 'Aujourd’hui',
            value: today,
            icon: Icons.today_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimelineStat(
            label: 'Semaine',
            value: week,
            icon: Icons.date_range_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimelineStat(
            label: 'À venir',
            value: upcoming,
            icon: Icons.event_available_rounded,
          ),
        ),
      ],
    );
  }
}

class _TimelineStat extends StatelessWidget {
  const _TimelineStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: ModernColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: ModernColors.primary, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: ModernColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ModernColors.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({
    required this.eventService,
    required this.access,
    required this.ownerId,
    required this.ownerName,
    required this.onCreated,
  });

  final SalonEventService eventService;
  final ProAccessState access;
  final String ownerId;
  final String ownerName;
  final VoidCallback onCreated;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _type = TextEditingController(text: 'Atelier');
  final _city = TextEditingController();
  final _venue = TextEditingController();
  final _onlineUrl = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _capacity = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  bool _isOnline = false;
  String _currency = CurrencyService.defaultCode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await CurrencyService().currentUserCurrency();
    if (mounted) setState(() => _currency = currency);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _type.dispose();
    _city.dispose();
    _venue.dispose();
    _onlineUrl.dispose();
    _price.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final startAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    setState(() => _saving = true);
    try {
      await widget.eventService.createProfessionalEvent(
        ownerId: widget.ownerId,
        plan:
            widget.access.isSignature
                ? 'signature'
                : widget.access.isPro
                ? 'pro'
                : 'free',
        title: _title.text,
        description: _description.text,
        type: _type.text,
        startAt: startAt,
        city: _city.text,
        venue: _venue.text,
        isOnline: _isOnline,
        onlineUrl: _onlineUrl.text,
        organizerName: widget.ownerName,
        price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
        currency: _currency,
        capacity: int.tryParse(_capacity.text),
      );
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Création impossible: $e'),
          backgroundColor: ModernColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter un événement',
              style: TextStyle(
                color: ModernColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.access.isSignature
                  ? 'Signature: votre événement est publié et mis en avant dans l’Agenda.'
                  : 'Pro: publiez un atelier, une vente privée ou un rendez-vous collectif.',
              style: TextStyle(
                color: ModernColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _EventField(controller: _title, label: 'Titre'),
            const SizedBox(height: 10),
            _EventField(
              controller: _description,
              label: 'Description',
              lines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _EventField(controller: _type, label: 'Type')),
                const SizedBox(width: 10),
                Expanded(child: _EventField(controller: _city, label: 'Ville')),
              ],
            ),
            const SizedBox(height: 10),
            _EventField(
              controller: _venue,
              label: _isOnline ? 'Lieu optionnel' : 'Lieu',
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              value: _isOnline,
              onChanged: (value) => setState(() => _isOnline = value),
              title: const Text('Événement en ligne'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isOnline) ...[
              const SizedBox(height: 10),
              _EventField(controller: _onlineUrl, label: 'Lien live / visio'),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '${_date.day}/${_date.month}/${_date.year}',
                    onPressed: _pickDate,
                    icon: Icons.calendar_month_rounded,
                    variant: AppButtonVariant.outline,
                    compact: true,
                    expand: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: _time.format(context),
                    onPressed: _pickTime,
                    icon: Icons.schedule_rounded,
                    variant: AppButtonVariant.outline,
                    compact: true,
                    expand: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _EventField(
                    controller: _price,
                    label:
                        'Prix ${CurrencyService.optionFor(_currency).symbol}',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EventField(
                    controller: _capacity,
                    label: 'Places',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppButton(
              label: _saving ? 'Publication...' : 'Publier l’événement',
              onPressed: _saving ? null : _submit,
              icon: Icons.send_rounded,
              loading: _saving,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventField extends StatelessWidget {
  const _EventField({
    required this.controller,
    required this.label,
    this.lines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final int lines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: ModernColors.surfaceRaised,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AgendaLoading extends StatelessWidget {
  const _AgendaLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ModernRadius.lg),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ModernRadius.lg),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ModernRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgendaState extends StatelessWidget {
  const _AgendaState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onExplore,
    this.onCreate,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback? onExplore;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, color: ModernColors.inkSoft, size: 34),
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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Réessayer',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                compact: true,
              ),
              if (onExplore != null)
                AppButton(
                  label: 'Voir tous',
                  onPressed: onExplore,
                  icon: Icons.grid_view_rounded,
                  variant: AppButtonVariant.outline,
                  compact: true,
                ),
              if (onCreate != null)
                AppButton(
                  label: 'Créer',
                  onPressed: onCreate,
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.secondary,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

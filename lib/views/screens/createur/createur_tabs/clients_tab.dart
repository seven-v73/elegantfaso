import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/account_roles.dart';
import '../../../../design/ecommerce_widgets.dart';
import '../../../../design/modern_design_system.dart';
import '../../../../models/createur/creator_customer.dart';
import '../../../../services/createur/creator_appointment_service.dart';
import '../../../../services/createur/creator_customer_service.dart';
import '../../../widgets/common/app_action_empty_state.dart';
import '../../messages/chat_screen.dart';
import '../../messages/messages_entry_screen.dart';
import '../../messages/user_model.dart';
import '../widgets/creator_customer_card.dart';

class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key, required this.user});

  final User user;

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  final CreatorAppointmentService _appointmentService =
      CreatorAppointmentService();
  final CreatorCustomerService _customerService = CreatorCustomerService();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _filter = 'Récents';

  static const _filters = ['Récents', 'À relancer', 'RDV', 'Mensurations'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CreatorCustomer> _applyFilters(List<CreatorCustomer> customers) {
    final query = _query.trim().toLowerCase();
    return customers.where((customer) {
      final matchesQuery =
          query.isEmpty ||
          '${customer.name} ${customer.email} ${customer.phone}'
              .toLowerCase()
              .contains(query);
      final matchesFilter = switch (_filter) {
        'À relancer' => customer.appointmentsCount == 0,
        'RDV' => customer.appointmentsCount > 0,
        'Mensurations' => customer.hasMeasurements,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.canvas,
      body: StreamBuilder(
        stream: _appointmentService.watchAppointments(widget.user.uid),
        builder: (context, appointmentSnapshot) {
          final appointments = appointmentSnapshot.data ?? const [];
          return FutureBuilder<List<CreatorCustomer>>(
            future: _customerService.loadCustomers(
              creatorId: widget.user.uid,
              appointments: appointments,
            ),
            builder: (context, snapshot) {
              final customers = _applyFilters(snapshot.data ?? const []);
              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _ClientsHeader(
                      controller: _searchController,
                      query: _query,
                      total: snapshot.data?.length ?? 0,
                      withAppointments:
                          snapshot.data
                              ?.where((client) => client.appointmentsCount > 0)
                              .length ??
                          0,
                      onQueryChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 12),
                    _FilterRail(
                      filters: _filters,
                      selected: _filter,
                      onSelected: (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        appointmentSnapshot.connectionState ==
                            ConnectionState.waiting)
                      const _LoadingClients()
                    else if (snapshot.hasError || appointmentSnapshot.hasError)
                      const _ClientState(
                        icon: Icons.error_outline_rounded,
                        title: 'Clients indisponibles',
                        message: 'Impossible de charger votre CRM.',
                      )
                    else if (customers.isEmpty)
                      _ClientState(
                        icon: Icons.people_outline_rounded,
                        title: 'Aucun client',
                        message:
                            _filter == 'Récents' && _query.trim().isEmpty
                                ? 'Les abonnés et clients avec rendez-vous apparaîtront ici.'
                                : 'Aucun client ne correspond à ce filtre.',
                        actionLabel:
                            _filter == 'Récents' && _query.trim().isEmpty
                                ? 'Ouvrir la messagerie'
                                : 'Voir tous',
                        onAction:
                            _filter == 'Récents' && _query.trim().isEmpty
                                ? _openMessages
                                : _clearFilters,
                      )
                    else
                      for (final customer in customers) ...[
                        CreatorCustomerCard(
                          customer: customer,
                          onMessage: () => _startChatWithCustomer(customer),
                          onAppointment: () => _createAppointment(customer),
                          onDetails: () => _showCustomerSheet(customer),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              );
            },
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

  Future<void> _startChatWithCustomer(CreatorCustomer customer) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docs = await Future.wait([
        firestore.collection('users').doc(widget.user.uid).get(),
        firestore.collection('users').doc(customer.id).get(),
      ]);
      if (!mounted) return;

      if (!docs.first.exists || !docs.last.exists) {
        _openMessages();
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                utilisateurCourant: UserModel.fromDocument(docs.first),
                autreUtilisateur: UserModel.fromDocument(docs.last),
                currentRole: AccountRoles.createur,
                otherRole: AccountRoles.client,
              ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation indisponible pour ce client.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _createAppointment(CreatorCustomer customer) async {
    final controller = TextEditingController(text: 'Rendez-vous style');
    var selectedDate = DateTime.now().add(const Duration(days: 1));
    var selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setSheetState) {
              final scheduledAt = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: ModernColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Objet',
                            prefixIcon: const Icon(Icons.checkroom_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 180),
                                    ),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.event_rounded),
                                label: Text(
                                  '${scheduledAt.day}/${scheduledAt.month}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setSheetState(() => selectedTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.schedule_rounded),
                                label: Text(selectedTime.format(context)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.event_available_rounded),
                          label: const Text('Créer le RDV'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );

    if (created != true) {
      controller.dispose();
      return;
    }

    final date = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final reason =
        controller.text.trim().isEmpty
            ? 'Rendez-vous style'
            : controller.text.trim();
    controller.dispose();

    try {
      await _appointmentService.createAppointment(
        creatorId: widget.user.uid,
        clientId: customer.id,
        clientName: customer.name,
        clientEmail: customer.email,
        date: date,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous créé.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de créer ce rendez-vous.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearFilters() {
    setState(() {
      _filter = 'Récents';
      _query = '';
      _searchController.clear();
    });
  }

  void _showCustomerSheet(CreatorCustomer customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _CustomerSheet(
            customer: customer,
            onMessage: () {
              Navigator.pop(context);
              _startChatWithCustomer(customer);
            },
            onAppointment: () {
              Navigator.pop(context);
              _createAppointment(customer);
            },
          ),
    );
  }
}

class _ClientsHeader extends StatelessWidget {
  const _ClientsHeader({
    required this.controller,
    required this.query,
    required this.total,
    required this.withAppointments,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final String query;
  final int total;
  final int withAppointments;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clients',
            style: TextStyle(
              color: ModernColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total contacts • $withAppointments avec rendez-vous',
            style: const TextStyle(color: ModernColors.inkSoft),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon:
                  query.isEmpty
                      ? null
                      : IconButton(
                        onPressed: () {
                          controller.clear();
                          onQueryChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              filled: true,
              fillColor: ModernColors.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return ChoiceChip(
            label: Text(filter),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _CustomerSheet extends StatelessWidget {
  const _CustomerSheet({
    required this.customer,
    required this.onMessage,
    required this.onAppointment,
  });

  final CreatorCustomer customer;
  final VoidCallback onMessage;
  final VoidCallback onAppointment;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.86,
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
                customer.name,
                style: const TextStyle(
                  color: ModernColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                customer.email.isEmpty ? customer.phone : customer.email,
                style: const TextStyle(color: ModernColors.inkSoft),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'Type', value: customer.typeLabel),
              _DetailRow(
                label: 'Rendez-vous',
                value: '${customer.appointmentsCount}',
              ),
              _DetailRow(label: 'Commandes', value: '${customer.ordersCount}'),
              _DetailRow(
                label: 'Mensurations',
                value: customer.hasMeasurements ? 'Partagées' : 'Non partagées',
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Message',
                onPressed: onMessage,
                icon: Icons.chat_bubble_outline_rounded,
                expand: true,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Créer RDV',
                onPressed: onAppointment,
                icon: Icons.event_available_rounded,
                variant: AppButtonVariant.outline,
                expand: true,
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
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingClients extends StatelessWidget {
  const _LoadingClients();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 104,
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

class _ClientState extends StatelessWidget {
  const _ClientState({
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

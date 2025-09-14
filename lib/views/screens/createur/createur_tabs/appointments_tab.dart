import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/empty_state.dart';
import '../widgets/shimmer_effects.dart';
import '../widgets/detail_row.dart';
import 'add_appointment_screen.dart';
import 'time_slot.dart';

class AppointmentsTab extends StatelessWidget {
  final User user;

  const AppointmentsTab({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Mes Rendez-vous'),
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'À venir'),
              Tab(text: 'Passés'),
              Tab(text: 'Disponibilité'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAppointmentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            UpcomingTab(userId: user.uid),
            PastTab(userId: user.uid),
            AvailabilityTab(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

class UpcomingTab extends StatefulWidget {
  final String userId;

  const UpcomingTab({Key? key, required this.userId}) : super(key: key);

  @override
  State<UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends State<UpcomingTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('creatorId', isEqualTo: widget.userId)
            .where('date', isGreaterThanOrEqualTo: DateTime.now())
            .where('status', whereIn: ['pending', 'confirmed'])
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList();
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error,
              message: 'Erreur: ${snapshot.error}',
            );
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return EmptyState(
              icon: Icons.event_available,
              message: 'Aucun RDV à venir',
              actionText: 'Prendre un RDV',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddAppointmentScreen()),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final appointment = snapshot.data!.docs[index];
              final data = appointment.data() as Map<String, dynamic>? ?? {};
              final date = data['date'] != null
                  ? (data['date'] as Timestamp).toDate()
                  : null;
              final status = data['status'] ?? 'pending';
              final isToday = date != null &&
                  date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;

              return _buildAppointmentCard(
                context,
                appointment,
                data,
                date,
                status,
                isToday,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context,
      DocumentSnapshot appointment,
      Map<String, dynamic> data,
      DateTime? date,
      String status,
      bool isToday,
      ) {
    final statusInfo = _getStatusInfo(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusInfo.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusInfo.icon,
            color: statusInfo.color,
            size: 28,
          ),
        ),
        title: Text(data['clientEmail'] ?? 'Client inconnu',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date != null) Text(DateFormat('EEE dd MMM yyyy, HH:mm').format(date)),
            Chip(
              label: Text(
                statusInfo.label,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: statusInfo.color,
              shape: StadiumBorder(),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text('Confirmer'),
              value: 'confirm',
            ),
            PopupMenuItem(
              child: Text('Annuler'),
              value: 'cancel',
            ),
          ],
          onSelected: (value) => _handleStatusChange(appointment, value),
        ),
        onTap: () => _showAppointmentDetails(context, appointment),
      ),
    );
  }

  void _handleStatusChange(DocumentSnapshot appointment, String action) {
    String newStatus = 'pending';

    switch (action) {
      case 'confirm':
        newStatus = 'confirmed';
        break;
      case 'cancel':
        newStatus = 'cancelled';
        break;
      default:
        return;
    }

    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointment.id)
        .update({'status': newStatus})
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut modifié: ${_getStatusInfo(newStatus).label}'),
          backgroundColor: _getStatusInfo(newStatus).color,
        ),
      );
    });
  }

  void _showAppointmentDetails(
      BuildContext context, DocumentSnapshot appointment) {
    final data = appointment.data() as Map<String, dynamic>? ?? {};
    final date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : null;
    final status = data['status'] ?? 'pending';
    final statusInfo = _getStatusInfo(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const Text('Détails du Rendez-vous',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusInfo.icon,
                      color: statusInfo.color,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    date != null
                        ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date)
                        : 'Date non spécifiée',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: date != null
                      ? Text(
                    'À ${DateFormat('HH:mm').format(date)}',
                    style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.color
                            ?.withOpacity(0.6),
                        fontSize: 16),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                DetailRow(
                    icon: Icons.person,
                    label: 'Client:',
                    value: data['clientEmail'] ?? 'Client inconnu'),
                DetailRow(
                    icon: Icons.email,
                    label: 'Email:',
                    value: data['clientEmail'] ?? 'Non renseigné'),
                DetailRow(
                    icon: Icons.description,
                    label: 'Raison:',
                    value: data['reason'] ?? 'Non spécifié'),
                if (data['notes'] != null && data['notes'].isNotEmpty)
                  DetailRow(
                      icon: Icons.note,
                      label: 'Notes:',
                      value: data['notes']),
                const SizedBox(height: 24),
                Text('Modifier le statut:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChip(appointment, 'pending', 'En attente'),
                    _buildStatusChip(appointment, 'confirmed', 'Confirmé'),
                    _buildStatusChip(appointment, 'cancelled', 'Annulé'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateAppointmentStatus(appointment, 'confirmed');
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirmer'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateAppointmentStatus(appointment, 'cancelled');
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(
      DocumentSnapshot appointment, String status, String label) {
    final currentStatus = appointment.get('status') ?? 'pending';
    final isSelected = currentStatus == status;
    final statusInfo = _getStatusInfo(status);

    return ChoiceChip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: statusInfo.color.withOpacity(0.3),
      selectedColor: statusInfo.color,
      selected: isSelected,
      onSelected: (selected) {
        _updateAppointmentStatus(appointment, status);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _updateAppointmentStatus(
      DocumentSnapshot appointment, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.id)
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut modifié: ${_getStatusInfo(status).label}'),
          backgroundColor: _getStatusInfo(status).color,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return StatusInfo(Icons.check_circle, Colors.green, 'Confirmé');
      case 'cancelled':
        return StatusInfo(Icons.cancel, Colors.red, 'Annulé');
      default:
        return StatusInfo(Icons.access_time, Colors.orange, 'En attente');
    }
  }
}

class PastTab extends StatelessWidget {
  final String userId;

  const PastTab({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('creatorId', isEqualTo: userId)
            .where('status', whereIn: ['completed', 'cancelled'])
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerList();
          }

          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error,
              message: 'Erreur: ${snapshot.error}',
            );
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              message: 'Aucun RDV passé',
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final appointment = snapshot.data!.docs[index];
              final data = appointment.data() as Map<String, dynamic>? ?? {};
              final date = data['date'] != null
                  ? (data['date'] as Timestamp).toDate()
                  : null;
              final status = data['status'] ?? 'completed';
              final statusInfo = _getStatusInfo(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusInfo.icon,
                      color: statusInfo.color,
                      size: 28,
                    ),
                  ),
                  title: Text(data['clientEmail'] ?? 'Client inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (date != null)
                        Text(DateFormat('EEE dd MMM yyyy, HH:mm').format(date)),
                      Chip(
                        label: Text(
                          statusInfo.label,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: statusInfo.color,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ],
                  ),
                  onTap: () => _showAppointmentDetails(context, appointment),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAppointmentDetails(
      BuildContext context, DocumentSnapshot appointment) {
    final data = appointment.data() as Map<String, dynamic>? ?? {};
    final date = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : null;
    final status = data['status'] ?? 'completed';
    final statusInfo = _getStatusInfo(status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du RDV passé'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(statusInfo.icon, color: statusInfo.color),
                title: Text('Statut: ${statusInfo.label}'),
              ),
              if (date != null)
                DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date:',
                  value: DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date),
                ),
              if (date != null)
                DetailRow(
                  icon: Icons.access_time,
                  label: 'Heure:',
                  value: DateFormat('HH:mm').format(date),
                ),
              DetailRow(
                icon: Icons.person,
                label: 'Client:',
                value: data['clientEmail'] ?? 'Client inconnu',
              ),
              DetailRow(
                icon: Icons.email,
                label: 'Email:',
                value: data['clientEmail'] ?? 'Non renseigné',
              ),
              DetailRow(
                icon: Icons.description,
                label: 'Raison:',
                value: data['reason'] ?? 'Non spécifié',
              ),
              if (data['notes'] != null && data['notes'].isNotEmpty)
                DetailRow(
                  icon: Icons.note,
                  label: 'Notes:',
                  value: data['notes'],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'cancelled':
        return StatusInfo(Icons.cancel, Colors.red, 'Annulé');
      case 'completed':
        return StatusInfo(Icons.done_all, Colors.blue, 'Terminé');
      default:
        return StatusInfo(Icons.history, Colors.grey, 'Passé');
    }
  }
}

class AvailabilityTab extends StatefulWidget {
  final String userId;

  const AvailabilityTab({Key? key, required this.userId}) : super(key: key);

  @override
  State<AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<AvailabilityTab> {
  late DateTime _selectedDay;
  late Map<DateTime, List<TimeSlot>> _availability;
  late Stream<DocumentSnapshot> _availabilityStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _availability = {};
    _availabilityStream = FirebaseFirestore.instance
        .collection('availability')
        .doc(widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _selectedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Disponibilité pour ${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDay)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _availabilityStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildDefaultTimeSlots();
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final dayKey = DateFormat('yyyy-MM-dd').format(_selectedDay);
                final slots = data[dayKey] as List<dynamic>? ?? [];

                return ListView.builder(
                  itemCount: 24, // De 00:00 à 23:30
                  itemBuilder: (context, index) {
                    final hour = index ~/ 2;
                    final minute = (index % 2) * 30;
                    final time = TimeOfDay(hour: hour, minute: minute);
                    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                    bool isAvailable = false;
                    if (slots.isNotEmpty) {
                      final slot = slots.firstWhere(
                            (s) => s['startTime'] == timeStr,
                        orElse: () => null,
                      );
                      isAvailable = slot?['available'] ?? false;
                    }

                    return _buildTimeSlotCard(time, isAvailable, dayKey);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultTimeSlots() {
    return ListView.builder(
      itemCount: 24, // De 00:00 à 23:30
      itemBuilder: (context, index) {
        final hour = index ~/ 2;
        final minute = (index % 2) * 30;
        final time = TimeOfDay(hour: hour, minute: minute);
        return _buildTimeSlotCard(time, false,
            DateFormat('yyyy-MM-dd').format(_selectedDay));
      },
    );
  }

  Widget _buildTimeSlotCard(TimeOfDay time, bool isAvailable, String dayKey) {
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text('${time.format(context)}'),
        trailing: Switch(
          value: isAvailable,
          activeColor: Colors.green,
          onChanged: (value) => _updateAvailability(dayKey, timeStr, value),
        ),
      ),
    );
  }

  void _updateAvailability(String dayKey, String time, bool available) {
    FirebaseFirestore.instance
        .collection('availability')
        .doc(widget.userId)
        .set({
      dayKey: FieldValue.arrayUnion([
        {'startTime': time, 'available': available}
      ])
    }, SetOptions(merge: true))
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disponibilité mise à jour'),
          backgroundColor: available ? Colors.green : Colors.orange,
        ),
      );
    });
  }
}

class StatusInfo {
  final IconData icon;
  final Color color;
  final String label;

  StatusInfo(this.icon, this.color, this.label);
}
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BoutiqueAppointmentsScreen extends StatefulWidget {
  const BoutiqueAppointmentsScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueAppointmentsScreenState createState() =>
      _BoutiqueAppointmentsScreenState();
}

class _BoutiqueAppointmentsScreenState
    extends State<BoutiqueAppointmentsScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _showAppointmentsList = false;
  String _selectedFilter = 'all'; // all, pending, confirmed, cancelled

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: _showAppointmentsList,
        title: Text(_showAppointmentsList
            ? 'Mes Rendez-vous'
            : 'Gestion des Rendez-vous'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2A2D3E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _showAppointmentsList
            ? [
          PopupMenuButton<String>(
            icon: const Icon(FeatherIcons.filter),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Tous'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('En attente'),
              ),
              const PopupMenuItem(
                value: 'confirmed',
                child: Text('Confirmés'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Annulés'),
              ),
            ],
          ),
        ]
            : null,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2A2D3E).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _showAppointmentsList
            ? _buildAppointmentsList()
            : _buildWelcomeScreen(),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D3E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              FeatherIcons.calendar,
              size: 60,
              color: Color(0xFF2A2D3E),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gestion des Rendez-vous',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Visualisez et gérez les rendez-vous de vos clients',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAppointmentsList = true;
              });
            },
            icon: const Icon(FeatherIcons.eye),
            label: const Text('Voir les rendez-vous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2D3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final appointments = snapshot.data!.docs;
        final filteredAppointments = _filterAppointments(appointments);

        if (filteredAppointments.isEmpty) {
          return _buildEmptyFilterState();
        }

        return Column(
          children: [
            _buildStatsHeader(appointments),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index].data()
                    as Map<String, dynamic>;
                    final appointmentId = filteredAppointments[index].id;
                    return _buildAppointmentCard(appointment, appointmentId);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('creatorId', isEqualTo: currentUserId)
        .orderBy('date', descending: false)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterAppointments(
      List<QueryDocumentSnapshot> appointments) {
    if (_selectedFilter == 'all') return appointments;

    return appointments.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      return status.toLowerCase() == _selectedFilter;
    }).toList();
  }

  Widget _buildStatsHeader(List<QueryDocumentSnapshot> appointments) {
    final stats = _calculateStats(appointments);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', stats['total']!, FeatherIcons.calendar,
              const Color(0xFF2A2D3E)),
          _buildStatItem('En attente', stats['pending']!, FeatherIcons.clock,
              Colors.orange),
          _buildStatItem('Confirmés', stats['confirmed']!,
              FeatherIcons.checkCircle, Colors.green),
          _buildStatItem('Annulés', stats['cancelled']!, FeatherIcons.xCircle,
              Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> appointments) {
    int total = appointments.length;
    int pending = 0;
    int confirmed = 0;
    int cancelled = 0;

    for (var doc in appointments) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';

      switch (status.toLowerCase()) {
        case 'pending':
          pending++;
          break;
        case 'confirmed':
          confirmed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return {
      'total': total,
      'pending': pending,
      'confirmed': confirmed,
      'cancelled': cancelled,
    };
  }

  Widget _buildAppointmentCard(
      Map<String, dynamic> appointment, String appointmentId) {
    final clientEmail = appointment['clientEmail'] as String? ?? 'Email non disponible';
    final reason = appointment['reason'] as String? ?? 'Raison non spécifiée';
    final status = appointment['status'] as String? ?? 'pending';
    final date = appointment['date'] as Timestamp?;
    final creatorName = appointment['creatorName'] as String? ?? 'Nom non disponible';

    final formattedDate = date != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(date.toDate())
        : 'Date non spécifiée';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = FeatherIcons.checkCircle;
        statusText = 'Confirmé';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = FeatherIcons.xCircle;
        statusText = 'Annulé';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = FeatherIcons.clock;
        statusText = 'En attente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creatorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A2D3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(FeatherIcons.mail, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clientEmail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(FeatherIcons.calendar, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(FeatherIcons.messageSquare, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                          appointmentId, 'confirmed'),
                      icon: const Icon(FeatherIcons.check, size: 16),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                          appointmentId, 'cancelled'),
                      icon: const Icon(FeatherIcons.x, size: 16),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Rendez-vous confirmé avec succès'
                : 'Rendez-vous rejeté',
          ),
          backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Erreur lors de la mise à jour du rendez-vous'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2A2D3E)),
          SizedBox(height: 16),
          Text(
            'Chargement des rendez-vous...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FeatherIcons.calendar,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun rendez-vous',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos rendez-vous apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FeatherIcons.filter,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun rendez-vous pour ce filtre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez un autre filtre',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2D3E),
            ),
            child: const Text('Voir tous'),
          ),
        ],
      ),
    );
  }
}
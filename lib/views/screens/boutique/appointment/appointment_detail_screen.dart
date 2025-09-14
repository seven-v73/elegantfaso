import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String serviceName;
  final DateTime dateTime;
  final String professionalName;
  final String status;
  final String? notes;
  final String professionalImage;

  const AppointmentDetailScreen({
    Key? key,
    required this.serviceName,
    required this.dateTime,
    required this.professionalName,
    required this.status,
    this.notes,
    required this.professionalImage,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmé':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Rendez-vous'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(professionalImage),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                professionalName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Professionnel',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailItem(
                          icon: Icons.calendar_today,
                          title: 'Date',
                          value: DateFormat('dd/MM/yyyy').format(dateTime),
                        ),
                        _DetailItem(
                          icon: Icons.access_time,
                          title: 'Heure',
                          value: DateFormat('HH:mm').format(dateTime),
                        ),
                        _DetailItem(
                          icon: Icons.accessibility,
                          title: 'Durée',
                          value: '1h 30min',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Service',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              serviceName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (notes != null) ...[
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notes!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black),
                      ),
                      child: const Text(
                        'MODIFIER',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'ANNULER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepOrange),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
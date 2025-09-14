import 'package:flutter/material.dart';
import 'package:elegantfaso/models/boutique/boutique_order.dart';
import 'package:intl/intl.dart';

class BoutiqueOrderCard extends StatelessWidget {
  final BoutiqueOrder order;
  final VoidCallback onTap;

  const BoutiqueOrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final total = order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Commande #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Date: ${dateFormat.format(order.createdAt)}'),
              const SizedBox(height: 8),
              Text('Client: ${order.clientName}'),
              const SizedBox(height: 8),
              Text('Total: ${total.toStringAsFixed(0)} FCFA'),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
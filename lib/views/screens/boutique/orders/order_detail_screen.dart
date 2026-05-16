import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elegantfaso/models/boutique/boutique_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegantfaso/services/preferences/currency_service.dart';
import 'package:elegantfaso/views/widgets/forms/app_select_field.dart';

class OrderDetailScreen extends StatelessWidget {
  final BoutiqueOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final total = order.items.fold(
      0.0,
      (totalAmount, item) => totalAmount + (item.price * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Détails Commande')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #${order.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Date: ${dateFormat.format(order.createdAt)}'),
            SizedBox(height: 8),
            Text(
              'Statut: ${_getStatusText(order.status)}',
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 32),
            Text('Client:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(order.clientName),
            Text(order.clientPhone),
            SizedBox(height: 16),
            Text('Livraison:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(order.deliveryAddress),
            Divider(height: 32),
            Text('Articles:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...order.items.map(
              (item) => ListTile(
                leading:
                    item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl, width: 40)
                        : Icon(Icons.shopping_bag),
                title: Text(item.name),
                subtitle: Text(
                  '${item.quantity} x ${CurrencyService.format(item.price, code: item.currency)}',
                ),
                trailing: Text(
                  CurrencyService.format(
                    item.price * item.quantity,
                    code: item.currency,
                  ),
                ),
              ),
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  CurrencyService.format(total, code: order.currency),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 24),
            if (order.status != 'Livrée' && order.status != 'Annulée')
              _buildStatusDropdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    final nextStatus = _getNextStatus(order.status);

    return AppSelectField<String>(
      value: nextStatus.isNotEmpty ? nextStatus[0] : null,
      items: nextStatus,
      label: 'Nouveau statut',
      icon: Icons.local_shipping_outlined,
      onChanged: (value) {
        if (value != null) {
          FirebaseFirestore.instance.collection('orders').doc(order.id).update({
            'status': value,
          });
          Navigator.pop(context);
        }
      },
    );
  }

  List<String> _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'En attente':
        return ['Confirmée', 'Annulée'];
      case 'Confirmée':
        return ['En cours', 'Annulée'];
      case 'En cours':
        return ['Livrée'];
      default:
        return [];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmée':
        return Colors.blue;
      case 'En cours':
        return Colors.orange;
      case 'Livrée':
        return Colors.green;
      case 'Annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'En attente':
        return 'En attente de confirmation';
      case 'Confirmée':
        return 'Confirmée par la boutique';
      case 'En cours':
        return 'En cours de livraison';
      case 'Livrée':
        return 'Livrée avec succès';
      case 'Annulée':
        return 'Commande annulée';
      default:
        return status;
    }
  }
}

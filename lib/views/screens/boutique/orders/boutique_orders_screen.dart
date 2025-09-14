import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elegantfaso/models/boutique/boutique_order.dart';
import 'package:elegantfaso/views/widgets/boutique/boutique_order_card.dart';
import 'package:elegantfaso/views/screens/boutique/orders/order_detail_screen.dart';


enum OrderStatus {
  all,
  pending,
  confirmed,
  inProgress,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.all:
        return 'Toutes les commandes';
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmées';
      case OrderStatus.inProgress:
        return 'En cours';
      case OrderStatus.delivered:
        return 'Livrées';
      case OrderStatus.cancelled:
        return 'Annulées';
    }
  }
}

class BoutiqueOrdersScreen extends StatefulWidget {
  final OrderStatus initialFilter;

  const BoutiqueOrdersScreen({
    Key? key,
    this.initialFilter = OrderStatus.all,
  }) : super(key: key);

  @override
  State<BoutiqueOrdersScreen> createState() => _BoutiqueOrdersScreenState();
}

class _BoutiqueOrdersScreenState extends State<BoutiqueOrdersScreen> {
  late String _boutiqueId;
  late OrderStatus _selectedFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Commandes'),
        actions: [_buildFilterMenu()],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_boutiqueId.isEmpty) {
      return _buildErrorState('Utilisateur non connecté');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Erreur de chargement des commandes');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return _buildOrderList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text('Réessayer'),
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
          Icon(Icons.shopping_cart, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune commande trouvée',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (_selectedFilter != OrderStatus.all)
            TextButton(
              onPressed: () => setState(() => _selectedFilter = OrderStatus.all),
              child: const Text('Voir toutes les commandes'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<QueryDocumentSnapshot> docs) {
    try {
      final orders = docs.map((doc) => BoutiqueOrder.fromFirestore(doc)).toList();

      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return BoutiqueOrderCard(
              order: orders[index],
              onTap: () => _navigateToOrderDetail(orders[index]),
            );
          },
        ),
      );
    } catch (e) {
      return _buildErrorState('Format des données invalide');
    }
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<OrderStatus>(
      onSelected: (filter) => setState(() => _selectedFilter = filter),
      icon: const Icon(Icons.filter_list),
      itemBuilder: (context) => OrderStatus.values.map((status) {
        return PopupMenuItem(
          value: status,
          child: Text(status.displayName),
        );
      }).toList(),
    );
  }

  Future<void> _refreshOrders() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _navigateToOrderDetail(BoutiqueOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('boutiqueId', isEqualTo: _boutiqueId)
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != OrderStatus.all) {
      query = query.where('status', isEqualTo: _selectedFilter.name);
    }

    return query.snapshots();
  }
}
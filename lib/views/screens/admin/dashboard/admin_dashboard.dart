import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'user_model.dart';


part 'admin_constants.dart';
part 'admin_data_source.dart';
part 'user_management.dart';
part 'stat_card.dart';
part 'custom_app_bar.dart';
part 'responsive_builder.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  int _currentIndex = 0;
  int _nbClients = 0;
  int _nbBoutiques = 0;
  int _nbCreators = 0;
  int _nbCommandes = 0;
  double _totalRevenus = 0.0;
  List<SalesData> _salesData = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _recentActivities = [];
  List<UserModel> _users = [];
  UserDataSource? _userDataSource;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      await Future.wait([
        _fetchUsersData(),
        _fetchOrdersData(),
        _fetchRecentActivities(),
      ]);
    } catch (e) {
      setState(() => _errorMessage = "Erreur de chargement: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsersData() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final users = usersSnapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();

    setState(() {
      _users = users;
      _nbClients = users.where((u) => u.role == 'client').length;
      _nbBoutiques = users.where((u) => u.role == 'boutique').length;
      _nbCreators = users.where((u) => u.role == 'createur').length;
      _userDataSource = UserDataSource(users, _showUserDetails, _editUser, _deleteUser);
    });
  }

  Future<void> _fetchOrdersData() async {
    final commandes = await _firestore.collection('orders').get();
    double revenus = 0;
    final monthlyTotals = <String, double>{};

    for (var doc in commandes.docs) {
      final amount = (doc.data()['totalAmount'] ?? 0).toDouble();
      revenus += amount;

      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final monthKey = DateFormat('MMM yyyy').format(createdAt);
        monthlyTotals.update(monthKey, (value) => value + amount, ifAbsent: () => amount);
      }
    }

    setState(() {
      _nbCommandes = commandes.size;
      _totalRevenus = revenus;
      _salesData = _processSalesData(monthlyTotals);
    });
  }

  List<SalesData> _processSalesData(Map<String, double> rawData) {
    return rawData.entries
        .map((e) => SalesData(e.key, e.value))
        .toList()
      ..sort((a, b) {
        final dateFormat = DateFormat('MMM yyyy');
        return dateFormat.parse(a.month).compareTo(dateFormat.parse(b.month));
      });
  }

  Future<void> _fetchRecentActivities() async {
    final activities = await _firestore.collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    setState(() {
      _recentActivities = activities.docs.map((doc) {
        final data = doc.data();
        return {
          'type': data['type'],
          'title': data['title'],
          'description': data['description'] ?? '',
          'subtitle': DateFormat('dd/MM/yyyy HH:mm').format(data['timestamp'].toDate()),
          'icon': _getActivityIcon(data['type']),
          'color': _getActivityColor(data['type']),
        };
      }).toList();
    });
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user': return Icons.person_add;
      case 'order': return Icons.shopping_cart;
      case 'shop': return Icons.store;
      case 'payment': return Icons.payment;
      default: return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'user': return AppColors.primary;
      case 'order': return Colors.green;
      case 'shop': return AppColors.secondary;
      case 'payment': return Colors.teal;
      default: return Colors.amber;
    }
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: UserDetailsSheet(user: user),
      ),
    );
  }

  void _editUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: EditUserDialog(
          user: user,
          onSave: (updatedUser) => _updateUser(updatedUser),
        ),
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer cet utilisateur ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(user.id).delete();
        await _fetchUsersData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUser(UserModel updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toMap());
      await _fetchUsersData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createNewUser() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: CreateUserDialog(
          onCreate: (newUser) => _saveNewUser(newUser),
        ),
      ),
    );
  }

  Future<void> _saveNewUser(UserModel newUser) async {
    try {
      await _firestore.collection('users').add(newUser.toMap());
      await _fetchUsersData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nouvel utilisateur créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Widget _buildMainContent() {
    return ResponsiveBuilder(
      mobile: _buildMobileView(),
      tablet: _buildTabletView(),
      desktop: _buildDesktopView(),
    );
  }

  Widget _buildMobileView() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildDashboardView(),
        _buildUsersView(),
        _buildOrdersView(),
        _buildStatsView(),
        _buildSettingsView(),
      ],
    );
  }

  Widget _buildTabletView() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          labelType: NavigationRailLabelType.all,
          destinations: [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: Text('Utilisateurs'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: Text('Commandes'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: Text('Statistiques'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Paramètres'),
            ),
          ],
        ),
        VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardView(),
              _buildUsersView(),
              _buildOrdersView(),
              _buildStatsView(),
              _buildSettingsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopView() {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Drawer(
            elevation: 0,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(Icons.person, size: 36, color: AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(Icons.dashboard, 'Tableau de Bord', 0),
                _buildDrawerItem(Icons.people, 'Gestion Utilisateurs', 1),
                _buildDrawerItem(Icons.shopping_bag, 'Commandes', 2),
                _buildDrawerItem(Icons.analytics, 'Statistiques', 3),
                _buildDrawerItem(Icons.settings, 'Paramètres', 4),
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  onTap: _signOut,
                ),
              ],
            ),
          ),
        ),
        VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboardView(),
              _buildUsersView(),
              _buildOrdersView(),
              _buildStatsView(),
              _buildSettingsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de Bord',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aperçu des activités et statistiques',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: _buildStatsSection(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24),
            sliver: SliverToBoxAdapter(
              child: _buildChartsSection(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
            sliver: SliverToBoxAdapter(
              child: _buildActivitySection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des Utilisateurs',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_users.length} utilisateurs au total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.add, size: 18),
                label: Text('Nouvel Utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                onPressed: _createNewUser,
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _userDataSource == null
                  ? Center(child: CircularProgressIndicator())
                  : SfDataGridTheme(
                data: SfDataGridThemeData(
                  headerColor: Colors.grey[50],
                  rowHoverColor: AppColors.primary.withOpacity(0.05),
                ),
                child: SfDataGrid(
                  source: _userDataSource!,
                  columns: [
                    GridColumn(
                      columnName: 'name',
                      width: 180,
                      label: Container(
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nom',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    GridColumn(
                      columnName: 'email',
                      width: 220,
                      label: Container(
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    GridColumn(
                      columnName: 'role',
                      width: 120,
                      label: Container(
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text(
                          'Rôle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    GridColumn(
                      columnName: 'status',
                      width: 100,
                      label: Container(
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text(
                          'Statut',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    GridColumn(
                      columnName: 'actions',
                      width: 120,
                      label: Container(
                        padding: EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                  gridLinesVisibility: GridLinesVisibility.horizontal,
                  headerGridLinesVisibility: GridLinesVisibility.both,
                  allowSorting: true,
                  selectionMode: SelectionMode.single,
                  rowHeight: 60,
                  headerRowHeight: 56,
                  columnWidthMode: ColumnWidthMode.fill,
                  onCellTap: (details) {
                    if (details.rowColumnIndex.rowIndex > 0) {
                      final user = _users[details.rowColumnIndex.rowIndex - 1];
                      _showUserDetails(user);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Gestion des Commandes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cette section sera bientôt disponible',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Statistiques Avancées',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cette section sera bientôt disponible',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'Paramètres Administrateur',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cette section sera bientôt disponible',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Chargement des données...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red),
            ),
            SizedBox(height: 24),
            Text(
              "Oups, une erreur est survenue",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Réessayer"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadData();
  }

  Widget _buildStatsSection() {
    return ResponsiveBuilder(
      mobile: _buildStatsGrid(crossAxisCount: 2, childAspectRatio: 1.4),
      tablet: _buildStatsGrid(crossAxisCount: 4, childAspectRatio: 1.2),
      desktop: _buildStatsGrid(crossAxisCount: 5, childAspectRatio: 1),
    );
  }

  Widget _buildStatsGrid({required int crossAxisCount, required double childAspectRatio}) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        StatCard(
          title: "Clients",
          value: _nbClients.toString(),
          icon: Icons.people,
          color: AppColors.primary,
          trend: _nbClients > 0 ? Trend.up : Trend.neutral,
          trendValue: "10%",
        ),
        StatCard(
          title: "Boutiques",
          value: _nbBoutiques.toString(),
          icon: Icons.store,
          color: AppColors.secondary,
          trend: _nbBoutiques > 0 ? Trend.up : Trend.neutral,
          trendValue: "5%",
        ),
        StatCard(
          title: "Créateurs",
          value: _nbCreators.toString(),
          icon: Icons.design_services,
          color: Colors.purple,
          trend: _nbCreators > 0 ? Trend.up : Trend.neutral,
          trendValue: "8%",
        ),
        StatCard(
          title: "Commandes",
          value: _nbCommandes.toString(),
          icon: Icons.shopping_bag,
          color: Colors.orange,
          trend: _nbCommandes > 0 ? Trend.up : Trend.neutral,
          trendValue: "15%",
        ),
        StatCard(
          title: "Revenus",
          value: "€${_totalRevenus.toStringAsFixed(2)}",
          icon: Icons.attach_money,
          color: Colors.green,
          trend: _totalRevenus > 0 ? Trend.up : Trend.neutral,
          trendValue: "20%",
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Évolution des Ventes",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Performance des ventes mensuelles",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          Container(
            height: 350,
            child: _salesData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    "Aucune donnée de vente disponible",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : SfCartesianChart(
              plotAreaBorderWidth: 0,
              title: ChartTitle(
                text: '',
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.top,
                textStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: Colors.white,
                borderColor: Colors.grey[300] ?? Colors.grey,
                borderWidth: 1,
                textStyle: TextStyle(color: Colors.grey[800]),
                builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.month}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '€${point.y.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              primaryXAxis: CategoryAxis(
                title: AxisTitle(text: 'Mois'),
                labelRotation: -45,
                majorGridLines: MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Montant (€)'),
                numberFormat: NumberFormat.currency(symbol: '€'),
                majorGridLines: MajorGridLines(color: Colors.grey[100]),
                axisLine: AxisLine(width: 0),
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
              series: <CartesianSeries<SalesData, String>>[
                ColumnSeries<SalesData, String>(
                  name: 'Ventes',
                  dataSource: _salesData,
                  xValueMapper: (SalesData sales, _) => sales.month,
                  yValueMapper: (SalesData sales, _) => sales.sales,
                  color: AppColors.primary,
                  width: 0.6,
                  spacing: 0.2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                      return Text('€${point.y.toStringAsFixed(0)}');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Activité Récente",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Voir tout',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    "Aucune activité récente",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ..._recentActivities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: activity['color'].withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            activity['icon'],
            color: activity['color'],
          ),
        ),
        title: Text(
          activity['title'],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity['description']),
            SizedBox(height: 4),
            Text(
              activity['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {},
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      elevation: 0,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 36, color: AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  _auth.currentUser?.displayName ?? 'Admin',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _auth.currentUser?.email ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Tableau de Bord', 0),
          _buildDrawerItem(Icons.people, 'Gestion Utilisateurs', 1),
          _buildDrawerItem(Icons.shopping_bag, 'Commandes', 2),
          _buildDrawerItem(Icons.analytics, 'Statistiques', 3),
          _buildDrawerItem(Icons.settings, 'Paramètres', 4),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(
        icon,
        color: _currentIndex == index ? AppColors.primary : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _currentIndex == index ? AppColors.primary : Colors.grey[700],
          fontWeight: _currentIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _currentIndex == index,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _currentIndex == 0 ? null : CustomAppBar(
        title: _getAppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Actualiser',
          ),
          if (_currentIndex == 1)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add, size: 18),
                label: Text('Nouvel Utilisateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _createNewUser,
              ),
            ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width > 800 ? null : _buildDrawer(),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : _buildMainContent(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Tableau de Bord';
      case 1: return 'Gestion des Utilisateurs';
      case 2: return 'Commandes';
      case 3: return 'Statistiques';
      case 4: return 'Paramètres';
      default: return 'Admin Dashboard';
    }
  }
}

class SalesData {
  final String month;
  final double sales;

  SalesData(this.month, this.sales);
}
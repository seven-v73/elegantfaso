import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


import '../../messages/chat_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/sheet_handle.dart';
import '../widgets/shimmer_effects.dart';
import '../widgets/detail_row.dart';
import '../../messages/user_model.dart';



class ClientsTab extends StatefulWidget {
  final User user;

  const ClientsTab({Key? key, required this.user}) : super(key: key);

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  String _searchQuery = '';
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentUserModel = UserModel.fromDocument(doc);
        });
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mes Clients',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                onPressed: () => _showClientFilterOptions(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search, color: Theme.of(context).hintColor),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildClientsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    if (_currentUserModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ShimmerList();
        }

        final createurData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final clientsIds = List<String>.from(createurData['followers'] ?? []);

        if (clientsIds.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            message: 'Aucun client pour le moment',
            actionText: 'Inviter des clients',
            onAction: () => _showInviteDialog(context),
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: clientsIds)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerList();
            }

            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return EmptyState(
                icon: Icons.error,
                message: 'Erreur de chargement des clients',
              );
            }

            final clients = userSnapshot.data!.docs
                .where((doc) => _matchesSearch(doc, _searchQuery))
                .toList();

            return RefreshIndicator(
              onRefresh: () async => _loadCurrentUser(),
              color: const Color(0xFF4A6FA5),
              child: ListView.separated(
                itemCount: clients.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) => _ClientTile(
                  client: clients[index],
                  currentUser: _currentUserModel!,
                  followedAt: createurData['followersDetails']?[clients[index].id]?['followedAt'] as Timestamp?,
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesSearch(DocumentSnapshot doc, String query) {
    if (query.isEmpty) return true;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name']?.toString().toLowerCase() ?? '';
    final email = data['email']?.toString().toLowerCase() ?? '';

    return name.contains(query) || email.contains(query);
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inviter des clients'),
          content: const Text('Partagez votre profil pour inviter plus de clients'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _shareProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A6FA5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Partager'),
            ),
          ],
        );
      },
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien de partage copié dans le presse-papier'),
        backgroundColor: Color(0xFF2A9D8F),
      ),
    );
  }

  void _showClientFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filtrer les clients', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _FilterOption(icon: Icons.people, label: 'Tous les clients', isSelected: true),
              const Divider(),
              _FilterOption(icon: Icons.access_time, label: 'Clients récents', isSelected: false),
              const Divider(),
              _FilterOption(icon: Icons.loyalty, label: 'Clients fidèles', isSelected: false),
              const Divider(),
              _FilterOption(icon: Icons.not_interested, label: 'Clients inactifs', isSelected: false),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6FA5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Appliquer les filtres'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientTile extends StatelessWidget {
  final DocumentSnapshot client;
  final UserModel currentUser;
  final Timestamp? followedAt;

  const _ClientTile({
    required this.client,
    required this.currentUser,
    this.followedAt,
  });

  @override
  Widget build(BuildContext context) {
    final clientData = client.data() as Map<String, dynamic>? ?? {};
    final name = clientData['name'] ?? 'Nom inconnu';
    final photoUrl = clientData['photoUrl'] ?? '';
    final lastInteraction = clientData.containsKey('lastInteraction')
        ? (clientData['lastInteraction'] as Timestamp?)?.toDate()
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF4A6FA5).withOpacity(0.1),
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(
              color: const Color(0xFF4A6FA5),
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (followedAt != null)
              Text(
                'Client depuis ${DateFormat('dd MMM yyyy').format(followedAt!.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            if (lastInteraction != null)
              Text(
                'Dernier contact: ${DateFormat('dd/MM/yy').format(lastInteraction)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A6FA5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'CLIENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A6FA5),
            ),
          ),
        ),
        onTap: () => _showClientDetails(context, clientData, name, photoUrl),
      ),
    );
  }

  void _showClientDetails(BuildContext context, Map<String, dynamic> clientData, String name, String photoUrl) async {
    final email = clientData['email'] ?? 'Email non renseigné';
    final phone = clientData['phone'] ?? 'Non renseigné';
    final city = clientData['city'] ?? 'Non renseignée';
    final joinedDate = clientData['createdAt'] != null
        ? (clientData['createdAt'] as Timestamp).toDate()
        : null;

    UserModel? clientUserModel;
    try {
      final clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(client.id)
          .get();

      if (clientDoc.exists) {
        clientUserModel = UserModel.fromDocument(clientDoc);
      }
    } catch (e) {
      debugPrint('Error loading client user: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF4A6FA5).withOpacity(0.1),
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: const Color(0xFF4A6FA5),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    email,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A6FA5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CLIENT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A6FA5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DetailRow(icon: Icons.phone, label: 'Téléphone:', value: phone),
                DetailRow(icon: Icons.location_on, label: 'Ville:', value: city),
                if (followedAt != null)
                  DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Client depuis:',
                    value: DateFormat('dd MMM yyyy').format(followedAt!.toDate()),
                  ),
                if (joinedDate != null)
                  DetailRow(
                    icon: Icons.person_add,
                    label: 'Inscrit le:',
                    value: DateFormat('dd/MM/yyyy').format(joinedDate),
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (clientUserModel != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  utilisateurCourant: currentUser,
                                  autreUtilisateur: clientUserModel!,
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.message, color: Theme.of(context).primaryColor),
                        label: Text(
                          'Message',
                          style: TextStyle(color: Theme.of(context).primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                              context,
                              '/add-appointment',
                              arguments: {
                                'clientId': client.id,
                                'clientName': name,
                                'clientPhoto': photoUrl,
                              }
                          );
                        },
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        label: const Text('RDV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE76F51),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).hintColor),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () {},
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boutiques Partenaires',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: const BoutiqueUsersScreen(),
    );
  }
}

class BoutiqueUsersScreen extends StatelessWidget {
  const BoutiqueUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutiques Partenaires'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'boutique')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs;

            if (users.isEmpty) {
              return const Center(child: Text('Aucune boutique trouvée'));
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                return BoutiqueCard(user: user);
              },
            );
          },
        ),
      ),
    );
  }
}

class BoutiqueCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const BoutiqueCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo de profil avec placeholder élégant
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 130,
              color: Colors.grey[100],
              child: _buildProfileImage(),
            ),
          ),
          // Informations
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Boutique',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (user['bio'] != null && user['bio'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      user['bio'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      user['rating']?.toStringAsFixed(1) ?? '4.5',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    if (user['isVIP'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (user['photoUrl'] == null || user['photoUrl'].isEmpty) {
      return const Center(
        child: Icon(Icons.store, size: 50, color: Colors.deepPurple),
      );
    }

    return CachedNetworkImage(
      imageUrl: user['photoUrl'],
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/user_models.dart';
import 'user_detail_screen.dart';
import '../utils/string_extension.dart';

class UserListScreen extends StatelessWidget {
  final String userType; // 'client', 'boutique', 'createur'

  const UserListScreen({required this.userType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestion ${userType.capitalize()}s")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: userType)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final user = UserModel.fromFirestore(snapshot.data!.docs[index]);
              return UserCard(user: user);
            },
          );
        },
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final UserModel user;

  const UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: ListTile(
    leading: CircleAvatar(backgroundImage: NetworkImage(user.photoUrl)),
    title: Text(user.name),
    subtitle: Text(user.email),
    trailing: Icon(Icons.chevron_right),
    onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    ),
    ),
    );
  }
}
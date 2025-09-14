import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BoutiqueMessagesScreen extends StatefulWidget {
  const BoutiqueMessagesScreen({Key? key}) : super(key: key);

  @override
  _BoutiqueMessagesScreenState createState() => _BoutiqueMessagesScreenState();
}

class _BoutiqueMessagesScreenState extends State<BoutiqueMessagesScreen> {
  final String boutiqueId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('boutiqueId', isEqualTo: boutiqueId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!.docs;

          if (conversations.isEmpty) {
            return const Center(child: Text('Aucune conversation'));
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index].data() as Map<String, dynamic>;
              return _buildConversationTile(conv);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(conv['customerAvatar']),
      ),
      title: Text(
        conv['customerName'],
        style: TextStyle(
          fontWeight: conv['unreadCount'] > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conv['lastMessage'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: conv['unreadCount'] > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('HH:mm').format((conv['lastMessageTime'] as Timestamp).toDate()),
            style: const TextStyle(fontSize: 12),
          ),
          if (conv['unreadCount'] > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                conv['unreadCount'].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: () => _openConversation(conv['customerId']),
    );
  }

  void _openConversation(String customerId) {
    // Open chat implementation
  }
}
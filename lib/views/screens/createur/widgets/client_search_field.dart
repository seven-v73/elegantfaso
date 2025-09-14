import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientSearchField extends StatefulWidget {
  final String? initialClientId;
  final String? initialClientName;
  final Function(String, String, String?) onClientSelected;

  const ClientSearchField({
    Key? key,
    this.initialClientId,
    this.initialClientName,
    required this.onClientSelected,
  }) : super(key: key);

  @override
  State<ClientSearchField> createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<ClientSearchField> {
  final TextEditingController _controller = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedClientPhoto;

  @override
  void initState() {
    super.initState();
    if (widget.initialClientId != null) {
      _selectedClientId = widget.initialClientId;
      _selectedClientName = widget.initialClientName;
      _controller.text = widget.initialClientName ?? '';
    }
  }

  Future<void> _searchClients(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('followers', arrayContains: user.uid)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(5)
          .get();

      setState(() {
        _searchResults = snapshot.docs;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _selectClient(QueryDocumentSnapshot client) {
    final data = client.data() as Map<String, dynamic>? ?? {};
    setState(() {
      _selectedClientId = client.id;
      _selectedClientName = data['name'] ?? 'Client inconnu';
      _selectedClientPhoto = data['photoUrl'];
      _controller.text = _selectedClientName!;
      _searchResults = [];
    });
    widget.onClientSelected(client.id, _selectedClientName!, _selectedClientPhoto);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Rechercher un client...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: _searchClients,
        ),
        if (_isSearching) const LinearProgressIndicator(),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: _searchResults.map((client) {
                final data = client.data() as Map<String, dynamic>? ?? {};
                final name = data['name'] ?? 'Client inconnu';
                final photoUrl = data['photoUrl'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name),
                  onTap: () => _selectClient(client),
                );
              }).toList(),
            ),
          ),
        if (_selectedClientId != null) ...[
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: _selectedClientPhoto != null
                  ? NetworkImage(_selectedClientPhoto!)
                  : null,
              child: _selectedClientPhoto == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              _selectedClientName!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedClientId = null;
                  _selectedClientName = null;
                  _selectedClientPhoto = null;
                  _controller.clear();
                });
                widget.onClientSelected('', '', null);
              },
            ),
          ),
        ],
      ],
    );
  }
}
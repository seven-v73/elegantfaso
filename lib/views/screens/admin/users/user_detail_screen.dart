import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import '../core/models/user_models.dart';
import '../core/services/auth_service.dart';
import '../utils/constants.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.user.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil ${widget.user.roleName()}'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, authService),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _buildUserInfoSection(),
            SizedBox(height: 24),
            _buildActivitySection(),
            SizedBox(height: 24),
            _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(widget.user.photoUrl),
            backgroundColor: AppColors.light,
            child: widget.user.photoUrl.isEmpty
                ? Icon(Icons.person, size: 50)
                : null,
          ),
          SizedBox(height: 16),
          Text(
            widget.user.name,
            style: AppTextStyles.headline1,
          ),
          SizedBox(height: 4),
          Chip(
            label: Text(
              widget.user.roleName(),
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _getRoleColor(widget.user.role),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.email, 'Email', widget.user.email),
            Divider(),
            _buildInfoRow(Icons.phone, 'Téléphone', widget.user.phone),
            Divider(),
            _buildInfoRow(
              Icons.calendar_today,
              'Date d\'inscription',
              widget.user.formattedDate(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité',
          style: AppTextStyles.headline1.copyWith(fontSize: 20),
        ),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatItem('Commandes', '24', Icons.shopping_bag),
                Divider(),
                _buildStatItem('Dernière connexion', 'Il y a 2h', Icons.access_time),
                Divider(),
                _buildStatItem('Statut', _isActive ? 'Actif' : 'Inactif',
                    _isActive ? Icons.check_circle : Icons.remove_circle,
                    color: _isActive ? Colors.green : Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 500;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildMessageButton()),
              SizedBox(width: 16),
              Expanded(child: _buildChangeRoleButton(context)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildMessageButton(),
              SizedBox(height: 12),
              _buildChangeRoleButton(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildMessageButton() {
    return OutlinedButton.icon(
      icon: Icon(Icons.message),
      label: Text('Message'),
      onPressed: _sendMessageToUser,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildChangeRoleButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.swap_horiz),
      label: Text('Changer rôle'),
      onPressed: () => _showRoleChangeDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: TextStyle(fontSize: 16),
      ),
    );
  }


  // Méthodes utilitaires
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12)),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.primary),
          SizedBox(width: 16),
          Text(label),
          Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.client: return Colors.blue;
      case UserRole.boutique: return Colors.green;
      case UserRole.createur: return Colors.purple;
      case UserRole.admin: return Colors.red;
    }
  }

  // Dialogues
  void _showEditDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Compte actif'),
              value: _isActive,
              onChanged: (value) async {
                setState(() => _isActive = value);
                await auth.updateUserStatus(widget.user.id, value);
                Navigator.pop(ctx);
              },
            ),
            // Ajouter d'autres champs éditables ici
          ],
        ),
      ),
    );
  }

  void _showRoleChangeDialog(BuildContext context) {
    // Implémentation similaire pour changer le rôle
  }

  void _sendMessageToUser() {
    // Implémentation de la messagerie
  }
}
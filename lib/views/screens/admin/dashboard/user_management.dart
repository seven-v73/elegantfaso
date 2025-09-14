part of 'admin_dashboard.dart';

class UserDetailsSheet extends StatelessWidget {
  final UserModel user;

  const UserDetailsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Détails Utilisateur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        SizedBox(height: 24),
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.person, size: 50, color: AppColors.primary),
        ),
        SizedBox(height: 16),
        Text(
          user.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.isActive ? 'COMPTE ACTIF' : 'COMPTE INACTIF',
            style: TextStyle(
              color: user.isActive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 32),
        Divider(),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Rôle', user.role.toUpperCase()),
              SizedBox(height: 12),
              _buildDetailRow('Date de création', DateFormat('dd/MM/yyyy').format(user.createdAt)),
              SizedBox(height: 12),
              _buildDetailRow('Dernière connexion', user.lastLogin != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!)
                  : 'Jamais'),
            ],
          ),
        ),
        Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Fermer'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Modifier'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onSave;

  const EditUserDialog({
    required this.user,
    required this.onSave,
  });

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedRole;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifier Utilisateur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Rôle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['client', 'boutique', 'createur', 'admin']
                  .map((role) => DropdownMenuItem(
                value: role,
                child: Text(role.toUpperCase()),
              ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Compte actif'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeColor: AppColors.primary,
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Annuler'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedUser = widget.user.copyWith(
                        name: _nameController.text,
                        email: _emailController.text,
                        role: _selectedRole,
                        isActive: _isActive,
                      );
                      widget.onSave(updatedUser);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreateUserDialog extends StatefulWidget {
  final Function(UserModel) onCreate;

  const CreateUserDialog({required this.onCreate});

  @override
  _CreateUserDialogState createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'client';
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvel Utilisateur',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Ce champ est obligatoire' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'Minimum 6 caractères'
                    : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['client', 'boutique', 'createur', 'admin']
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Compte actif'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: AppColors.primary,
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Annuler'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final newUser = UserModel(
                            id: '',
                            name: _nameController.text,
                            email: _emailController.text,
                            role: _selectedRole,
                            isActive: _isActive,
                            createdAt: DateTime.now(),
                            lastLogin: null,
                          );
                          widget.onCreate(newUser);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Créer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
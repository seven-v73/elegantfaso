part of 'admin_dashboard.dart';

class UserDetailsSheet extends StatelessWidget {
  const UserDetailsSheet({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: ModernColors.admin.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: ModernColors.admin,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fiche utilisateur',
                    style: TextStyle(
                      color: ModernColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Identité, rôle et état du compte.',
                    style: TextStyle(color: ModernColors.inkSoft),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 22),
        CircleAvatar(
          radius: 42,
          backgroundColor: ModernColors.primary.withValues(alpha: 0.1),
          child: Text(
            user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: ModernColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.name.isEmpty ? 'Utilisateur sans nom' : user.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ModernColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ModernColors.inkSoft),
        ),
        const SizedBox(height: 16),
        _UserStatusPill(active: user.isActive),
        const SizedBox(height: 24),
        AppFormSection(
          title: 'Informations',
          icon: Icons.info_outline_rounded,
          children: [
            _DetailRow(label: 'Rôle actif', value: user.role.toUpperCase()),
            _DetailRow(label: 'Source Firestore', value: user.source),
            _DetailRow(
              label: 'Créé le',
              value: DateFormat('dd/MM/yyyy').format(user.createdAt),
            ),
            _DetailRow(
              label: 'Dernière connexion',
              value:
                  user.lastLogin != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!)
                      : 'Jamais',
            ),
          ],
        ),
        const Spacer(),
        AppButton(
          label: 'Fermer',
          onPressed: () => Navigator.pop(context),
          variant: AppButtonVariant.outline,
          expand: true,
        ),
      ],
    );
  }
}

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({super.key, required this.user, required this.onSave});

  final UserModel user;
  final ValueChanged<UserModel> onSave;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _noteController;
  late String _selectedRole;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _noteController = TextEditingController();
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: 'Modifier utilisateur',
      subtitle: 'Ajustez le rôle actif et l’état du compte avec prudence.',
      primaryLabel: 'Enregistrer',
      onPrimary: _save,
      children: [
        AppTextField(
          controller: _nameController,
          label: 'Nom complet',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        AppSelectField<String>(
          value: _selectedRole,
          items: AccountRoles.all,
          label: 'Rôle actif',
          icon: Icons.manage_accounts_outlined,
          onChanged: (value) {
            if (value != null) setState(() => _selectedRole = value);
          },
        ),
        SwitchListTile.adaptive(
          value: _isActive,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: ModernColors.primary,
          title: const Text(
            'Compte actif',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _isActive
                ? 'L’utilisateur peut accéder aux espaces autorisés.'
                : 'L’accès sera bloqué côté logique applicative.',
          ),
          onChanged: (value) => setState(() => _isActive = value),
        ),
        AppTextField(
          controller: _noteController,
          label: 'Note admin',
          hint: 'Pourquoi ce changement est appliqué ?',
          icon: Icons.edit_note_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  void _save() {
    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
      isActive: _isActive,
    );
    widget.onSave(updatedUser);
  }
}

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key, required this.onCreate});

  final ValueChanged<UserModel> onCreate;

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = AccountRoles.client;
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _AdminFormDialog(
        title: 'Nouvel utilisateur',
        subtitle:
            'Crée un profil Firestore. Le compte Auth doit être créé par inscription ou par outil serveur.',
        primaryLabel: 'Créer',
        onPrimary: _create,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Nom complet',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Ajoutez un nom pour reconnaître ce compte.'
                        : null,
          ),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator:
                (value) =>
                    value == null || !value.contains('@')
                        ? 'Ajoutez un email valide.'
                        : null,
          ),
          AppSelectField<String>(
            value: _selectedRole,
            items: AccountRoles.all,
            label: 'Rôle actif',
            icon: Icons.manage_accounts_outlined,
            onChanged: (value) {
              if (value != null) setState(() => _selectedRole = value);
            },
          ),
          SwitchListTile.adaptive(
            value: _isActive,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: ModernColors.primary,
            title: const Text(
              'Compte actif',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text('Peut être suspendu avant invitation.'),
            onChanged: (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }

  void _create() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onCreate(
      UserModel(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _AdminSensitiveActionDialog extends StatefulWidget {
  const _AdminSensitiveActionDialog({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.dangerLabel,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String dangerLabel;

  @override
  State<_AdminSensitiveActionDialog> createState() =>
      _AdminSensitiveActionDialogState();
}

class _AdminSensitiveActionDialogState
    extends State<_AdminSensitiveActionDialog> {
  final _noteController = TextEditingController();
  String? _noteError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: widget.title,
      subtitle: widget.message,
      primaryLabel: widget.primaryLabel,
      secondaryLabel: widget.dangerLabel,
      dangerSecondary: true,
      onPrimary: () => _submit(deletePermanently: false),
      onSecondary: () => _submit(deletePermanently: true),
      children: [
        AppTextField(
          controller: _noteController,
          label: 'Motif admin',
          hint: 'Ex: demande utilisateur, fraude, doublon, test...',
          icon: Icons.gavel_rounded,
          maxLines: 3,
          errorText: _noteError,
        ),
      ],
    );
  }

  void _submit({required bool deletePermanently}) {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _noteError = 'Ajoutez un motif pour l’audit.');
      return;
    }
    Navigator.pop(
      context,
      _AdminUserDecision(note: note, deletePermanently: deletePermanently),
    );
  }
}

class _AdminNoteDialog extends StatefulWidget {
  const _AdminNoteDialog({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final bool danger;

  @override
  State<_AdminNoteDialog> createState() => _AdminNoteDialogState();
}

class _AdminNoteDialogState extends State<_AdminNoteDialog> {
  final _noteController = TextEditingController();
  String? _noteError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: widget.title,
      subtitle: widget.subtitle,
      primaryLabel: widget.primaryLabel,
      secondaryLabel: 'Annuler',
      onPrimary: _submit,
      dangerPrimary: widget.danger,
      children: [
        AppTextField(
          controller: _noteController,
          label: 'Note admin',
          hint: 'Ex: demande traitée, compte vérifié, suppression validée...',
          icon: Icons.edit_note_rounded,
          maxLines: 3,
          errorText: _noteError,
        ),
      ],
    );
  }

  void _submit() {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _noteError = 'Note obligatoire pour tracer la décision.');
      return;
    }
    Navigator.pop(context, note);
  }
}

class _CommunityAccessDialog extends StatefulWidget {
  const _CommunityAccessDialog({required this.data});

  final Map<String, dynamic>? data;

  @override
  State<_CommunityAccessDialog> createState() => _CommunityAccessDialogState();
}

class _CommunityAccessDialogState extends State<_CommunityAccessDialog> {
  late String _mode;
  String _duration = 'permanent';
  late final TextEditingController _reasonController;
  late final TextEditingController _allowedController;

  @override
  void initState() {
    super.initState();
    final data = widget.data ?? const {};
    _mode = data['mode']?.toString() ?? CommunityAccessModes.public;
    _reasonController = TextEditingController(
      text: data['reason']?.toString() ?? '',
    );
    final allowed =
        (data['allowedUserIds'] as Iterable?)
            ?.map((id) => id.toString())
            .join(', ') ??
        '';
    _allowedController = TextEditingController(text: allowed);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _allowedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: 'Accès communauté',
      subtitle:
          'Choisissez qui peut publier dans la communauté. La lecture reste ouverte sauf fermeture du groupe.',
      primaryLabel: 'Enregistrer',
      secondaryLabel: 'Annuler',
      onPrimary: () {
        Navigator.pop(context, {
          'mode': _mode,
          'reason': _reasonController.text.trim(),
          'lockedUntil': _lockedUntil(),
          'allowedUserIds':
              _allowedController.text
                  .split(',')
                  .map((id) => id.trim())
                  .where((id) => id.isNotEmpty)
                  .toList(),
        });
      },
      children: [
        AppSelectField<String>(
          label: 'Mode',
          value: _mode,
          icon: Icons.lock_open_rounded,
          items: const [
            CommunityAccessModes.public,
            CommunityAccessModes.membersOnly,
            CommunityAccessModes.restricted,
            CommunityAccessModes.closed,
          ],
          onChanged:
              (value) =>
                  setState(() => _mode = value ?? CommunityAccessModes.public),
        ),
        if (_mode == CommunityAccessModes.restricted) ...[
          const SizedBox(height: 12),
          AppTextField(
            controller: _allowedController,
            label: 'Utilisateurs autorisés',
            hint: 'UID séparés par virgule',
            icon: Icons.group_add_rounded,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 12),
        AppSelectField<String>(
          label: 'Durée',
          value: _duration,
          icon: Icons.timer_rounded,
          items: const ['1h', '24h', '7d', 'permanent'],
          onChanged:
              (value) => setState(() => _duration = value ?? 'permanent'),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _reasonController,
          label: 'Message affiché',
          hint: 'Ex: pause de modération, accès réservé à un groupe...',
          icon: Icons.edit_note_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  DateTime? _lockedUntil() {
    final now = DateTime.now();
    return switch (_duration) {
      '1h' => now.add(const Duration(hours: 1)),
      '24h' => now.add(const Duration(days: 1)),
      '7d' => now.add(const Duration(days: 7)),
      _ => null,
    };
  }
}

class _AdminUserDecision {
  const _AdminUserDecision({this.note = '', this.deletePermanently = false});

  final String note;
  final bool deletePermanently;
}

class _AdminFormDialog extends StatelessWidget {
  const _AdminFormDialog({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    required this.children,
    this.secondaryLabel = 'Annuler',
    this.onSecondary,
    this.dangerSecondary = false,
    this.dangerPrimary = false,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;
  final bool dangerSecondary;
  final bool dangerPrimary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ModernColors.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ModernColors.admin.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: ModernColors.admin,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ModernColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: ModernColors.inkSoft,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._spaced(children),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: secondaryLabel,
                      onPressed: onSecondary ?? () => Navigator.pop(context),
                      variant:
                          dangerSecondary
                              ? AppButtonVariant.danger
                              : AppButtonVariant.outline,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: primaryLabel,
                      onPressed: onPrimary,
                      variant:
                          dangerPrimary
                              ? AppButtonVariant.danger
                              : AppButtonVariant.primary,
                      expand: true,
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

  List<Widget> _spaced(List<Widget> widgets) {
    final spaced = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 14));
      spaced.add(widgets[i]);
    }
    return spaced;
  }
}

class _UserStatusPill extends StatelessWidget {
  const _UserStatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? ModernColors.success : ModernColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'COMPTE ACTIF' : 'COMPTE INACTIF',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(
            label,
            style: const TextStyle(
              color: ModernColors.inkSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: ModernColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

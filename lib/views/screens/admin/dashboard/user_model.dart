import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String source;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roles = const [],
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
    this.source = 'users',
  });

  factory UserModel.fromSnapshot(
    DocumentSnapshot doc, {
    String source = 'users',
    String fallbackRole = 'client',
    String? roleOverride,
    String? nameOverride,
  }) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    final shopProfile = _map(data['shopProfile']);
    final creatorProfile = _map(data['creatorProfile']);
    final overrideRole = _normalizeRole(roleOverride ?? '');
    final roles =
        overrideRole.isEmpty
            ? _rolesFromData(data, fallbackRole: fallbackRole)
            : <String>[overrideRole];
    final role = overrideRole.isEmpty ? _primaryRole(roles) : overrideRole;
    return UserModel(
      id: doc.id,
      name: _first([
        nameOverride,
        data['name'],
        data['displayName'],
        data['fullName'],
        data['clientName'],
        data['username'],
        shopProfile['name'],
        creatorProfile['name'],
        data['shopName'],
        data['creatorName'],
        data['ownerName'],
      ]),
      email: _first([
        data['email'],
        data['contactEmail'],
        data['ownerEmail'],
        data['phone'],
        data['telephone'],
      ]),
      role: role,
      roles: roles,
      isActive:
          data['isActive'] != false &&
          data['accountStatus']?.toString() != 'suspended' &&
          data['accountStatus']?.toString() != 'closed',
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      lastLogin: _date(data['lastLogin']),
      source: source,
    );
  }

  UserModel mergeWith(UserModel other) {
    final preferred = source == 'users' ? this : other;
    final secondary = identical(preferred, this) ? other : this;
    return UserModel(
      id: id,
      name: preferred.name.isNotEmpty ? preferred.name : secondary.name,
      email: preferred.email.isNotEmpty ? preferred.email : secondary.email,
      role: _primaryRole({...preferred.roles, ...secondary.roles}.toList()),
      roles: {...preferred.roles, ...secondary.roles}.toList(),
      isActive: preferred.isActive && secondary.isActive,
      createdAt:
          preferred.createdAt.isBefore(secondary.createdAt)
              ? preferred.createdAt
              : secondary.createdAt,
      lastLogin: preferred.lastLogin ?? secondary.lastLogin,
      source:
          source == other.source
              ? source
              : {...source.split(', '), ...other.source.split(', ')}.join(', '),
    );
  }

  bool hasRole(String role) => roles.contains(_normalizeRole(role));

  static String displayNameForRole(Map<String, dynamic> data, String role) {
    final shopProfile = _map(data['shopProfile']);
    final creatorProfile = _map(data['creatorProfile']);
    final normalized = _normalizeRole(role);
    if (normalized == 'boutique') {
      return _first([
        shopProfile['name'],
        data['shopName'],
        data['boutiqueName'],
        data['storeName'],
        data['businessName'],
        data['name'],
        data['displayName'],
      ]);
    }
    if (normalized == 'createur') {
      return _first([
        creatorProfile['name'],
        creatorProfile['atelierName'],
        data['creatorName'],
        data['createurName'],
        data['atelierName'],
        data['studioName'],
        data['businessName'],
        data['name'],
        data['displayName'],
      ]);
    }
    return _first([data['name'], data['displayName'], data['fullName']]);
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _first(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static List<String> _rolesFromData(
    Map<String, dynamic> data, {
    required String fallbackRole,
  }) {
    final roles = <String>{};
    void add(dynamic role) {
      final normalized = _normalizeRole(role?.toString() ?? '');
      if (normalized.isNotEmpty) roles.add(normalized);
    }

    add(data['activeRole']);
    add(data['role']);
    roles.addAll(_rolesFromFlags(data));
    roles.addAll(_rolesFromType(data));
    final rawRoles = data['roles'];
    if (rawRoles is Iterable) {
      for (final role in rawRoles) {
        add(role);
      }
    }
    if (rawRoles is Map) {
      if (rawRoles['admin'] == true || rawRoles['isAdmin'] == true) {
        roles.add('admin');
      }
      if (rawRoles['boutique'] == true ||
          rawRoles['shop'] == true ||
          rawRoles['isShop'] == true ||
          rawRoles['isBoutique'] == true) {
        roles.add('boutique');
      }
      if (rawRoles['createur'] == true ||
          rawRoles['creator'] == true ||
          rawRoles['isCreator'] == true ||
          rawRoles['isCreateur'] == true) {
        roles.add('createur');
      }
      if (rawRoles['client'] == true || rawRoles['isClient'] == true) {
        roles.add('client');
      }
    }
    final onboarding = data['onboarding'];
    if (onboarding is Map) {
      if (_businessRoleEnabled(onboarding['createur']) ||
          _businessRoleEnabled(onboarding['creator'])) {
        roles.add('createur');
      }
      if (_businessRoleEnabled(onboarding['boutique']) ||
          _businessRoleEnabled(onboarding['shop'])) {
        roles.add('boutique');
      }
    }
    final businessOnboarding = data['businessOnboarding'];
    if (businessOnboarding is Map) {
      if (_businessRoleEnabled(businessOnboarding['createur']) ||
          _businessRoleEnabled(businessOnboarding['creator'])) {
        roles.add('createur');
      }
      if (_businessRoleEnabled(businessOnboarding['boutique']) ||
          _businessRoleEnabled(businessOnboarding['shop'])) {
        roles.add('boutique');
      }
    }
    if (roles.isEmpty && _looksLikeCreatorProfile(data)) {
      roles.add('createur');
    }
    if (roles.isEmpty && _looksLikeShopProfile(data)) {
      roles.add('boutique');
    }
    if (roles.isEmpty) add(fallbackRole);
    if (!roles.contains('client')) roles.add('client');
    return roles.toList();
  }

  static List<String> _rolesFromFlags(Map<String, dynamic> data) {
    final roles = <String>[];
    final flags = data['roleFlags'];
    if (flags is Map) {
      if (flags['admin'] == true || flags['isAdmin'] == true) {
        roles.add('admin');
      }
      if (flags['boutique'] == true ||
          flags['shop'] == true ||
          flags['isShop'] == true ||
          flags['isBoutique'] == true) {
        roles.add('boutique');
      }
      if (flags['createur'] == true ||
          flags['creator'] == true ||
          flags['isCreator'] == true ||
          flags['isCreateur'] == true) {
        roles.add('createur');
      }
      if (flags['client'] == true || flags['isClient'] == true) {
        roles.add('client');
      }
    }
    return roles;
  }

  static List<String> _rolesFromType(Map<String, dynamic> data) {
    final value =
        _first([data['type'], data['kind'], data['profileType']]).toLowerCase();
    final roles = <String>[];
    if (value.contains('shop') || value.contains('boutique')) {
      roles.add('boutique');
    }
    if (value.contains('creator') || value.contains('createur')) {
      roles.add('createur');
    }
    return roles;
  }

  static bool _businessRoleEnabled(dynamic value) {
    if (value == true) return true;
    if (value is Map) {
      return value['enabled'] == true ||
          value['completed'] == true ||
          value['active'] == true ||
          value['status'] == 'active' ||
          value['status'] == 'completed' ||
          value['status'] == 'approved';
    }
    return false;
  }

  static bool _looksLikeCreatorProfile(Map<String, dynamic> data) {
    final text =
        _first([
          data['publicRole'],
          data['type'],
          data['kind'],
          data['profileType'],
          data['creatorName'],
          data['createurName'],
          data['speciality'],
          data['specialty'],
          data['profession'],
          data['category'],
          _map(data['creatorProfile'])['specialty'],
          _map(data['creatorProfile'])['category'],
        ]).toLowerCase();
    return text.contains('createur') ||
        text.contains('créateur') ||
        text.contains('creator') ||
        text.contains('atelier') ||
        text.contains('couture') ||
        text.contains('styliste') ||
        text.contains('tailleur') ||
        text.contains('mode');
  }

  static bool _looksLikeShopProfile(Map<String, dynamic> data) {
    final text =
        _first([
          data['publicRole'],
          data['type'],
          data['kind'],
          data['profileType'],
          data['shopName'],
          data['boutiqueName'],
          data['category'],
          _map(data['shopProfile'])['name'],
          _map(data['shopProfile'])['category'],
        ]).toLowerCase();
    return text.contains('boutique') ||
        text.contains('shop') ||
        text.contains('store');
  }

  static String _normalizeRole(String role) {
    return switch (role.trim().toLowerCase()) {
      'creator' || 'créateur' || 'creatrice' || 'créatrice' => 'createur',
      'shop' || 'store' || 'vendeur' => 'boutique',
      'administrator' || 'administrateur' => 'admin',
      'customer' || 'user' || 'utilisateur' => 'client',
      'createur' ||
      'boutique' ||
      'admin' ||
      'client' => role.trim().toLowerCase(),
      _ => '',
    };
  }

  static String _primaryRole(List<String> roles) {
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('boutique')) return 'boutique';
    if (roles.contains('createur')) return 'createur';
    return 'client';
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'roles': roles,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    List<String>? roles,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? source,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      source: source ?? this.source,
    );
  }
}

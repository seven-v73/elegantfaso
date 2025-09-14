import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../messages/user_model.dart';
import '../widgets/date_time_picker.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _appointmentType = 'Consultation';
  UserModel? _selectedClient;
  String _notes = '';
  bool _isLoading = false;
  List<UserModel> _followers = [];
  bool _loadingFollowers = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Récupérer les followers de la boutique
      final boutiqueDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!boutiqueDoc.exists) {
        setState(() => _loadingFollowers = false);
        return;
      }

      final followerIds = List<String>.from(boutiqueDoc['followers'] ?? []);

      if (followerIds.isEmpty) {
        setState(() => _loadingFollowers = false);
        return;
      }

      final followersSnapshot = await FirebaseFirestore.instance
          .collection('user_profiles')
          .where('userId', whereIn: followerIds)
          .get();

      setState(() {
        _followers = followersSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
            .toList();
        _loadingFollowers = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement followers: $e');
      setState(() => _loadingFollowers = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await FirebaseFirestore.instance.collection('appointments').add({
        'creatorId': user.uid,
        'clientId': _selectedClient!.id,
        'clientName': _selectedClient!.displayName,
        'clientPhoto': _selectedClient!.photoUrl,
        'clientEmail': _selectedClient!.email,
        'date': Timestamp.fromDate(appointmentDateTime),
        'type': _appointmentType,
        'notes': _notes,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildClientCard(UserModel client) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedClient?.id == client.id
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: client.photoUrl != null
              ? CachedNetworkImageProvider(client.photoUrl!)
              : null,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: client.photoUrl == null
              ? Text(
            client.shortName,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
        title: Text(
          client.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.email != null) Text(client.email!),
            if (client.phone != null) Text(client.phone!),
            if (client.location != null) Text(client.location!),
          ],
        ),
        trailing: _selectedClient?.id == client.id
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () {
          setState(() => _selectedClient = client);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Rendez-vous'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAppointment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sélectionnez un client qui vous suit:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              if (_loadingFollowers)
                const Center(child: CircularProgressIndicator())
              else if (_followers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.group_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun client ne vous suit actuellement',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Vos clients apparaîtront ici lorsqu\'ils vous suivront',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._followers.map(_buildClientCard).toList(),

              const SizedBox(height: 24),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 24),

              const Text(
                'Détails du rendez-vous',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: DateTimePicker(
                      label: 'Date',
                      value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DateTimePicker(
                      label: 'Heure',
                      value: _selectedTime.format(context),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _appointmentType,
                decoration: InputDecoration(
                  labelText: 'Type de rendez-vous',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'Consultation', child: Text('Consultation')),
                  DropdownMenuItem(value: 'Fitting', child: Text('Essayage')),
                  DropdownMenuItem(value: 'Livraison', child: Text('Livraison')),
                  DropdownMenuItem(value: 'Réunion', child: Text('Réunion')),
                  DropdownMenuItem(value: 'Retouche', child: Text('Retouche')),
                ],
                onChanged: (value) => setState(() => _appointmentType = value!),
              ),
              const SizedBox(height: 20),

              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                maxLines: 4,
                onChanged: (value) => _notes = value,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6FA5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.calendar_today, size: 20),
                  label: const Text(
                    'Enregistrer le Rendez-vous',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
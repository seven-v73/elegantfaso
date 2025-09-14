import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserModel>> getCreators() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'creator')
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching creators: $e');
      return [];
    }
  }
}
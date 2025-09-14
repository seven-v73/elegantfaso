import 'package:cloud_firestore/cloud_firestore.dart';

class CustomBatch {
  final WriteBatch _batch;
  int _operationCount;

  CustomBatch()
      : _batch = FirebaseFirestore.instance.batch(),
        _operationCount = 0;

  void set(
      DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data, {
        SetOptions? options,
      }) {
    _batch.set(ref, data, options);
    _operationCount++;
  }

  void update(
      DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data,
      ) {
    _batch.update(ref, data);
    _operationCount++;
  }

  void delete(DocumentReference<Map<String, dynamic>> ref) {
    _batch.delete(ref);
    _operationCount++;
  }

  Future<void> commit() async {
    if (_operationCount > 0) {
      await _batch.commit();
      _operationCount = 0;
    }
  }

  void reset() {
    _operationCount = 0;
  }

  int get operationCount => _operationCount;
  bool get hasPendingOperations => _operationCount > 0;
}
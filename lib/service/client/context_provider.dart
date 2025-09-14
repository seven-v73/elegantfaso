import 'package:flutter/material.dart';

class ContextProvider with ChangeNotifier {
  String? _gender;
  String? _budget;
  String _weather = 'Tempéré';
  String _culture = 'Mooré';

  String? get gender => _gender;
  String? get budget => _budget;
  String get weather => _weather;
  String get culture => _culture;

  set gender(String? value) {
    _gender = value;
    notifyListeners();
  }

  set budget(String? value) {
    _budget = value;
    notifyListeners();
  }

  set weather(String value) {
    _weather = value;
    notifyListeners();
  }

  set culture(String value) {
    _culture = value;
    notifyListeners();
  }
}
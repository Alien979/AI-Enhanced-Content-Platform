import 'package:flutter/foundation.dart';

class WritingModeProvider with ChangeNotifier {
  bool _isDistractionFree = false;

  bool get isDistractionFree => _isDistractionFree;

  void toggleDistractionFree() {
    _isDistractionFree = !_isDistractionFree;
    notifyListeners();
  }
}
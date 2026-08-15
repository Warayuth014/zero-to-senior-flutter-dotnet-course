import 'package:flutter/foundation.dart';

class RoutingSession extends ChangeNotifier {
  RoutingSession({bool authenticated = false}) : _authenticated = authenticated;

  bool _authenticated;
  bool get authenticated => _authenticated;

  void signIn() {
    if (_authenticated) return;
    _authenticated = true;
    notifyListeners();
  }

  void signOut() {
    if (!_authenticated) return;
    _authenticated = false;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

import '../models/session_model.dart';
import '../services/storage_service.dart';

class SessionsProvider extends ChangeNotifier {
  final StorageService _storage;
  SessionsProvider(this._storage);

  List<SessionModel> get today => _storage.getSessionsForDate(DateTime.now());
  int get totalScrollMinutesToday => _storage.getTotalScrollMinutesToday();

  void refresh() => notifyListeners();
}

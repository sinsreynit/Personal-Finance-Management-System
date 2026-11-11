import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  late final AuthRepository repo = AuthRepository(api);

  AppUser? user;
  bool loading = false;
  String? error;

  Future<bool> tryAutoLogin() async {
    final t = await api.token;
    if (t == null) return false;
    try {
      user = await repo.fetchProfile();
      notifyListeners();
      return true;
    } catch (_) {
      await api.clearToken();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String confirm,) => _run(() async {
        user = await repo.register(name, email, password, confirm);
});
  Future<bool> login(String email, String password) => _run(() async {
        user = await repo.login(email, password);
      });

  Future<void> logout() async {
    await repo.logout();
    user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? email, String? currency}) => _run(() async {
        user = await repo.updateProfile(name: name, email: email, currency: currency);
      });

  Future<bool> changePassword(String current, String next, String confirm) => _run(() async {
        await repo.changePassword(current, next, confirm);
      });

  Future<bool> _run(Future<void> Function() action) async {
  loading = true;
  error = null;
  notifyListeners();

  try {
    await action();
    loading = false;
    notifyListeners();
    return true;
  } on ApiException catch (e) {
    debugPrint('API ERROR: ${e.message}');
    error = e.message;
    loading = false;
    notifyListeners();
    return false;
  } catch (e, stackTrace) {
    debugPrint('UNEXPECTED ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);

    error = e.toString();
    loading = false;
    notifyListeners();
    return false;
  }
}
}

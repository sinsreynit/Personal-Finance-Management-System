import '../models/user.dart';
import 'api_service.dart';

class AuthRepository {
  final ApiService api;
  AuthRepository(this.api);

  // US-001 Register
  Future<AppUser> register(String name, String email, String password, String passwordConfirmation) async {
    final res = await api.post('/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    }, auth: false);
    await api.saveToken(res['token']);
    return AppUser.fromJson(res['user']);
  }

  // US-002 Login
  Future<AppUser> login(String email, String password) async {
    final res = await api.post('/login', {'email': email, 'password': password}, auth: false);
    await api.saveToken(res['token']);
    return AppUser.fromJson(res['user']);
  }

  // US-003 Logout
  Future<void> logout() async {
    try {
      await api.post('/logout', {});
    } finally {
      await api.clearToken();
    }
  }

  // US-004 Profile
  Future<AppUser> fetchProfile() async {
    final res = await api.get('/profile');
    return AppUser.fromJson(res);
  }

  Future<AppUser> updateProfile({String? name, String? email, String? currency}) async {
    final res = await api.put('/profile', {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (currency != null) 'currency': currency,
    });
    return AppUser.fromJson(res);
  }

  // US-005 Change Password
  Future<void> changePassword(String currentPassword, String newPassword, String newPasswordConfirmation) async {
    await api.put('/profile/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPasswordConfirmation,
    });
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database.dart';
import '../core/password_hash.dart';


class AppUser {
  final String mobile, name;
  AppUser(this.mobile, this.name);
}

class AuthProvider extends ChangeNotifier {
  final _db = AppDatabase.instance;
  AppUser? user;
  bool loading = true;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('mobile');
    if (mobile != null) {
      final u = await _db.getUser(mobile);
      if (u != null) user = AppUser(u['mobile'], u['name']);
    }
    loading = false;
    notifyListeners();
  }

  /// returns error message or null on success
  Future<String?> register(String name, String mobile, String password) async {
    if (await _db.getUser(mobile) != null) return 'Mobile already registered';
    final salt = PasswordHasher.generateSalt();
    await _db.insertUser(mobile, name, salt, PasswordHasher.hash(password, salt));
    return null;
  }

  Future<String?> login(String mobile, String password) async {
    final u = await _db.getUser(mobile);
    if (u == null || PasswordHasher.hash(password, u['salt']) != u['hash']) {
      return 'Invalid mobile number or password';
    }
    (await SharedPreferences.getInstance()).setString('mobile', mobile);
    user = AppUser(u['mobile'], u['name']);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    (await SharedPreferences.getInstance()).remove('mobile');
    user = null;
    notifyListeners();
  }
}
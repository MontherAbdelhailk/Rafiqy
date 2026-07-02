import 'package:shared_preferences/shared_preferences.dart';

/// SecureStorage — lightweight wrapper around SharedPreferences for token and user data.
/// Replace with flutter_secure_storage when you add that dependency.
class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _profileImageKey = 'profile_image';
  static const _ageKey = 'age';

  // ── Profile Image ──────────────────────────────────────────────────────────

  static Future<void> saveProfileImage(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, url);
  }

  static Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── User Role ──────────────────────────────────────────────────────────────

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == 'admin';
  }

  // ── User ID ────────────────────────────────────────────────────────────────

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // ── Username ───────────────────────────────────────────────────────────────

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // ── Clear All ──────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }



static Future<void> saveAge(int age) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_ageKey, age);
}

static Future<int?> getAge() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_ageKey);
}
}

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UsageService {
  static const int guestLimit = 1;
  static const int regularLimit = 3;

  Future<bool> canViewRecipe(UserModel? user) async {
    if (user?.isVIP ?? false) return true;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForUser(user);
    final today = _today();
    final storedDate = prefs.getString('${key}_date');
    var count = prefs.getInt('${key}_count') ?? 0;

    if (storedDate != today) {
      count = 0;
      await prefs.setString('${key}_date', today);
      await prefs.setInt('${key}_count', count);
    }

    final limit = user == null || user.isGuest ? guestLimit : regularLimit;
    return count < limit;
  }

  Future<void> recordRecipeView(UserModel? user) async {
    if (user?.isVIP ?? false) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForUser(user);
    final today = _today();
    final storedDate = prefs.getString('${key}_date');
    var count = prefs.getInt('${key}_count') ?? 0;

    if (storedDate != today) {
      count = 0;
      await prefs.setString('${key}_date', today);
    }

    await prefs.setString('${key}_date', today);
    await prefs.setInt('${key}_count', count + 1);
  }

  String _keyForUser(UserModel? user) {
    if (user == null || user.isGuest) return 'usage_guest';
    return 'usage_${user.uid}';
  }

  Future<int> getRemainingViews(UserModel? user) async {
    if (user?.isVIP ?? false) return -1; // -1 means unlimited
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForUser(user);
    final today = _today();
    final storedDate = prefs.getString('${key}_date');
    var count = prefs.getInt('${key}_count') ?? 0;

    if (storedDate != today) {
      count = 0;
    }

    final limit = user == null || user.isGuest ? guestLimit : regularLimit;
    return limit - count;
  }

  Future<int> getDailyLimit(UserModel? user) async {
    if (user?.isVIP ?? false) return -1; // -1 means unlimited
    return user == null || user.isGuest ? guestLimit : regularLimit;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}





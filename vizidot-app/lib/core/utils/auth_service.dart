import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  static const _keyLoggedIn = 'logged_in';
  final isLoggedIn = false.obs;

  Future<AuthService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool(_keyLoggedIn) ?? false;
    return this;
  }

  Future<void> signIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    isLoggedIn.value = true;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    isLoggedIn.value = false;
  }
}



import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPref {
  read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // print(prefs.getString(key) ?? "");
    // print(prefs.getString(key));
    if (prefs.getString(key) == null) {
      return null;
    } else {
      return json.decode(prefs.getString(key) ?? "");
    }
  }

  save(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // print(json.encode(value));
    } catch (error) {
      print(error);
    }
    prefs.setString(key, json.encode(value));
  }

  remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}

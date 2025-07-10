import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth extends GetxController {
  static final _auth = FirebaseAuth.instance;
  static void logout() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Restart.restartApp();
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
  }
}

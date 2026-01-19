import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vizidot_flutter/constants.dart';
import 'package:vizidot_flutter/main.dart';
import 'package:vizidot_flutter/home.dart';
import 'package:vizidot_flutter/LoginSignup/login_screen.dart';
import 'package:vizidot_flutter/LoginSignup/forgotpassword_screen.dart';
import 'package:vizidot_flutter/models/FirUser.dart';
import 'package:vizidot_flutter/utils/shared_prefrence.dart';
import '../../widgets/bottom_bar.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    changeScreen();
  }

  Future<void> changeScreen() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: kCurrentUserEmail, password: kCurrentUserPassword);
      print(credential.user);
      var json = await SharedPref().read(kCurrentUser);
      if (json == null) {
        _navigatotoLogin();
      } else {
        _navigatotohomeHome();
      }
    } on FirebaseAuthException catch (e) {
      _navigatotoLogin();
    }
  }

  _navigatotohomeHome() async {
    await Future.delayed(const Duration(milliseconds: 0), () {});
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Vizidot',
                  home: BottomBar(),
                )));
  }

  _navigatotoLogin() async {
    await Future.delayed(const Duration(milliseconds: 0), () {});
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Vizidot',
                  home: LoginScreen(),
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        color: kPrimaryColor,
        child: const Center(
          heightFactor: 200,
          child:
              Image(image: AssetImage("assets/splash-logo.png"), height: 300),
        ));
  }
}

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/Phone_Authentication/PhoneAuthentication.dart';
import 'package:taxi/Screens/bottom_Navbar/navbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
        splashIconSize: 500,
        splash: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: LottieBuilder.asset(
              "assets/animations/animtaxi.json",
            )),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 11.0),
                  child: Text(
                    "On Time.\nEvery Time.",
                    style: GoogleFonts.openSans(
                        color: taxiYellowColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 27),
                  ),
                ),
              ],
            )
          ],
        ),
        backgroundColor: splashGreenBGColor,
        nextScreen: getScreenId());
  }

  Widget getScreenId() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user != null) {
            return Navbar();
          } else {
            return const PhoneAuthenticationPage();
          }
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restart_app/restart_app.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Services/DatabaseServices.dart';
import 'package:taxi/Utils/texts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerification extends StatefulWidget {
  final String licensePlate;
  final String carBM;
  final String gender;
  final String name;
  final String phoneNo;
  final bool isRegistered;
  final String profilePictureUri;
  final dynamic isDriver;

  const OtpVerification({
    super.key,
    required this.licensePlate,
    required this.carBM,
    required this.gender,
    required this.name,
    required this.phoneNo,
    required this.isRegistered,
    required this.profilePictureUri,
    required this.isDriver,
  });

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  bool isLoading = false;
  bool sendingCode = false;

  Timer? _resendTimer;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    verifyPhoneNumber();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      }
    });
  }

  Future<void> verifyPhoneNumber() async {
    setState(() => sendingCode = true);
    final phoneNumber = widget.phoneNo.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Fluttertoast.showToast(msg: "Phone number automatically verified!");
          if (mounted) setState(() => sendingCode = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => sendingCode = false);
            Fluttertoast.showToast(msg: "Verification failed: ${e.message}");
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              sendingCode = false;
              _startResendTimer();
            });
            Fluttertoast.showToast(msg: "OTP code sent!");
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Error sending code: $e");
      if (mounted) setState(() => sendingCode = false);
    }
  }

  Future<void> verifyOTP() async {
    final otpCode = _otpController.text.trim();

    if (otpCode.isEmpty) {
      Fluttertoast.showToast(msg: "Enter the OTP");
      return;
    }

    if (_verificationId == null) {
      Fluttertoast.showToast(
          msg: "Verification ID missing. Try resending code.");
      return;
    }

    try {
      setState(() => isLoading = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        Fluttertoast.showToast(msg: "Authentication failed");
        return;
      }

      final uid = user.uid;

      // Handle user roles and registration
      if (widget.isDriver == "none") {
        Restart.restartApp();
      } else if (widget.isDriver == true) {
        await Databaseservices.createUser(
          uid,
          widget.name,
          widget.phoneNo.trim(),
          widget.profilePictureUri,
          '',
          'driver',
          context,
        );
        await Databaseservices.createtaxiInformation(
          uid,
          widget.name,
          widget.phoneNo.trim(),
          widget.licensePlate,
          widget.carBM,
          context,
        );
        Restart.restartApp();
      } else if (!widget.isRegistered) {
        await Databaseservices.createUser(
          uid,
          widget.name,
          widget.phoneNo.trim(),
          widget.profilePictureUri,
          '',
          'passenger',
          context,
        );
        Restart.restartApp();
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        backgroundColor: Colors.red,
        msg: e.message ?? "Invalid OTP",
      );
      _otpController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        iconTheme: IconThemeData(color: blackColor),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : verifyOTP,
        backgroundColor: splashGreenBGColor,
        child: isLoading
            ? CircularProgressIndicator(color: whiteColor)
            : Icon(CupertinoIcons.arrow_right, color: whiteColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: robotoText(
              "Enter Verification Code",
              blackColor,
              30,
              FontWeight.normal,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text.rich(
              TextSpan(
                text: "We sent a verification code to ",
                style: GoogleFonts.roboto(
                  color: blackColor.withOpacity(0.5),
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: widget.phoneNo,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: blackColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: PinCodeTextField(
              appContext: context,
              controller: _otpController,
              length: 6,
              keyboardType: TextInputType.number,
              onChanged: (_) {},
              onCompleted: (value) async {
                await verifyOTP();
              },
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 50,
                fieldWidth: 40,
                activeColor: splashGreenBGColor,
                selectedColor: taxiYellowColor,
                inactiveColor: Colors.grey[300]!,
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: (sendingCode || _resendCountdown > 0)
                  ? null
                  : verifyPhoneNumber,
              child: robotoText(
                _resendCountdown > 0
                    ? "Resend in $_resendCountdown sec"
                    : "Resend Code",
                splashGreenBGColor,
                16,
                FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

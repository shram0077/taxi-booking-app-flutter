import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/Phone_Authentication/OTP_Verification.dart';
import 'package:taxi/Screens/Phone_Authentication/selecte_role.dart';
import 'package:taxi/Services/DatabaseServices.dart';
import 'package:taxi/Utils/texts.dart';

class PhoneAuthenticationPage extends StatefulWidget {
  const PhoneAuthenticationPage({super.key});

  @override
  State<PhoneAuthenticationPage> createState() =>
      _PhoneAuthenticationPageState();
}

class _PhoneAuthenticationPageState extends State<PhoneAuthenticationPage> {
  final TextEditingController _phoneNoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false; // Added loading state

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Example Iraqi phone number pattern
    final regex = RegExp(r'^(750|751|770|771|780|781|782)\d{7}$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid phone number (750*******8)';
    }
    return null;
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true); // Start loading

      String phoneNo = "+964${_phoneNoController.text.trim()}";

      // Check if the phone number exists and whether it's a driver or a user
      bool isRegistered =
          await Databaseservices.checkIfPhoneNumberRegistered(phoneNo);
      setState(() => isLoading = false); // Stop loading

      if (isRegistered) {
        await Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.rightToLeft,
              child: OtpVerification(
                isDriver: "none",
                profilePictureUri: '',
                carBM: '',
                gender: '',
                isRegistered: isRegistered,
                licensePlate: "",
                name: '',
                phoneNo: phoneNo,
              )),
        );
      } else {
        // Navigate to role selection if not registered
        await Navigator.push(
          context,
          PageTransition(
              type: PageTransitionType.rightToLeft,
              child: SelectYourRole(
                phoneNo: phoneNo,
                isRegistered: isRegistered,
              )),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _onSubmit, // Disable button when loading
        backgroundColor: splashGreenBGColor,
        child: isLoading
            ? CircularProgressIndicator(
                color: whiteColor,
              )
            : Icon(
                CupertinoIcons.arrow_right,
                color: whiteColor,
              ),
      ),
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0.8,
        actions: [
          robotoText("English", blackColor, 16, FontWeight.normal),
          IconButton(
              onPressed: () {},
              icon: Icon(
                CupertinoIcons.globe,
                color: blackColor,
              )),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 12, bottom: 5),
              child: robotoText("Welcome!", blackColor, 32, FontWeight.normal)),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 15),
            child: robotoText(
                "Let's get started! Enter your phone number to book your first ride.",
                blackColor.withOpacity(0.5),
                16,
                FontWeight.normal),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _phoneNoController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g.750*******8',
                  hintStyle: GoogleFonts.roboto(
                      color: blackColor.withOpacity(0.3),
                      fontSize: 14,
                      fontWeight: FontWeight.normal),
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    borderSide:
                        BorderSide(color: splashGreenBGColor, width: 2.0),
                  ),
                ),
                validator: _validatePhoneNumber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

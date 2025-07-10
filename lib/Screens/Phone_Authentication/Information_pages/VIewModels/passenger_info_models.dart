import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi/Screens/Phone_Authentication/OTP_Verification.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Services/api_services.dart';

class PassengerInfoViewModel extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final String phoneNo;
  final FileLuApiService _apiService =
      FileLuApiService("33483if6tnlmefeenc68f"); // Your API Key

  File? _image;
  File? get image => _image;

  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  PassengerInfoViewModel({required this.phoneNo});

  void setGender(String? gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      // Handle image picking error, maybe show a snackbar
      print("Image pick error: $e");
    }
  }

  Future<void> submit(BuildContext context) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (_image == null) {
      _showSnackBar(context, "Please select a profile picture.");
      return;
    }

    _setLoading(true);

    try {
      final String downloadUrl = await _apiService.uploadImage(
        imageFile: _image!,
        fileName: "$phoneNo.jpg",
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      _navigateToOtpVerification(context, downloadUrl);
    } catch (e) {
      _showSnackBar(context, "An error occurred: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _uploadProgress = 0.0;
    notifyListeners();
  }

  void _navigateToOtpVerification(
      BuildContext context, String profilePictureUri) {
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: OtpVerification(
          isDriver: false,
          phoneNo: phoneNo,
          carBM: '',
          gender: _selectedGender!,
          isRegistered: false,
          licensePlate: '',
          name: nameController.text.trim(),
          profilePictureUri: profilePictureUri,
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}

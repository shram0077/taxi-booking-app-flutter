import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi/Constant/colors.dart';

import 'package:http/http.dart' as http;
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/UserModel.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentUserId;
  final UserModel userModel;

  const EditProfileScreen({
    super.key,
    required this.userModel,
    required this.currentUserId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // The phone controller is read-only as requested
  late final TextEditingController _phoneController;

  File? _image;
  bool _isLoading = false;
  String? _randomQuote;

  final List<String> _quotes = [
    "Your profile reflects your quality—make it shine.",
    "A complete profile builds credibility and trust.",
    "Every detail you add enhances your professional image.",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userModel.name);
    _emailController = TextEditingController(text: widget.userModel.email);
    _phoneController =
        TextEditingController(text: "0${widget.userModel.phone.substring(4)}");

    // Get a random quote once on initialization
    _randomQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  @override
  void dispose() {
    // IMPORTANT: Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // MARK: - Core Logic

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70, // Compress image for faster uploads
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile == null) return;

      setState(() {
        _image = File(croppedFile.path);
        _isLoading = true; // Start loading indicator on the avatar
      });

      // Show feedback
      _showSnackBar("Uploading new picture...", isError: false);

      // --- Start upload process ---
      final uploadUrl = await _uploadImageToHost(File(croppedFile.path));

      if (uploadUrl != null) {
        await usersRef
            .doc(widget.userModel.userid)
            .update({"profilePicture": uploadUrl});
        widget.userModel.profilePicture = uploadUrl; // Update local model
        _showSnackBar("Profile picture updated successfully!", isError: false);
      } else {
        throw Exception("Failed to get download URL.");
      }
    } catch (e) {
      _showSnackBar("Error updating picture: $e", isError: true);
    } finally {
      // IMPORTANT: Always stop loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImageToHost(File imageFile) async {
    // This function now encapsulates the entire upload flow to file.lu
    // 1. Get server
    final serverInfoResponse = await http.get(
        Uri.parse('https://filelu.com/api/upload/server?key=$fileluApiKey'));
    if (serverInfoResponse.statusCode != 200) {
      throw Exception('Failed to get upload server.');
    }
    final serverInfo = jsonDecode(serverInfoResponse.body);
    final uploadUrl = serverInfo['result'];
    final sessId = serverInfo['sess_id'];

    // 2. Upload image
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields['sess_id'] = sessId
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to upload file.');
    }

    final response = await http.Response.fromStream(streamedResponse);
    final uploadData = jsonDecode(response.body);
    final fileCode = uploadData[0]['file_code'];

    // 3. Get direct link
    final linkResponse = await http.get(Uri.parse(
        'https://filelu.com/api/file/direct_link?key=$fileluApiKey&file_code=$fileCode'));
    if (linkResponse.statusCode != 200) {
      throw Exception('Failed to get direct link.');
    }

    final linkData = jsonDecode(linkResponse.body);
    return linkData['result']['url'];
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors in the form.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> updatedData = {};
      if (_nameController.text.trim() != widget.userModel.name) {
        updatedData['name'] = _nameController.text.trim();
      }
      if (_emailController.text.trim() != widget.userModel.email) {
        updatedData['email'] = _emailController.text.trim();
      }

      if (updatedData.isNotEmpty) {
        await usersRef.doc(widget.userModel.userid).update(updatedData);
        _showSnackBar('Profile updated successfully!', isError: false);
        Navigator.pop(context); // Go back after saving
      } else {
        _showSnackBar('No changes to save.', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to update profile: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? errorColor : primaryColor,
    ));
  }

  // MARK: - Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: darkTextColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildQuote()),
              const SizedBox(height: 32),
              FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildFormFields()),
              const SizedBox(height: 40),
              FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildActionButtons()),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - UI Builder Widgets
  Widget _buildAvatar() {
    return Center(
      child: Hero(
        tag: 'profile_picture_hero_${widget.userModel.userid}',
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: secondaryColor,
              child: CircleAvatar(
                radius: 68,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : CachedNetworkImageProvider(
                        widget.userModel.profilePicture) as ImageProvider,
              ),
            ),
            // --- Loading Indicator Overlay ---
            if (_isLoading)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),
            // --- Edit Button ---
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isLoading ? null : _pickAndUploadImage,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor,
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _randomQuote ?? '',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: primaryColor.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextFormField(
          controller: _nameController,
          label: "Full Name",
          icon: Icons.person_outline,
          validator: (value) =>
              value == null || value.isEmpty ? 'Name cannot be empty' : null,
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _emailController,
          label: "Email Address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _phoneController,
          label: "Phone Number",
          icon: Icons.phone_outlined,
          enabled: false, // Phone number is not editable
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: lightTextColor),
        filled: true,
        fillColor: enabled ? secondaryColor : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: lightTextColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('CANCEL', style: TextStyle(color: darkTextColor)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ))
                : const Text('SAVE'),
          ),
        ),
      ],
    );
  }
}

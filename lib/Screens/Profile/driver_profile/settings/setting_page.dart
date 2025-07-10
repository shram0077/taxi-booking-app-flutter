import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/Screens/Profile/Edit_Profile/edit_profile.dart';
import 'package:taxi/Screens/Profile/passenger_profile.dart/Prefernces/map_style.dart';
import 'package:taxi/Services/Auth.dart';

// A more modern and user-friendly settings page for drivers.
class SettingsPage extends StatefulWidget {
  final String currentUserId;

  const SettingsPage({super.key, required this.currentUserId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Fetches the user's data from Firestore.
  Stream<UserModel> getUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return UserModel.fromDoc(docSnapshot);
      } else {
        throw Exception('User document does not exist or is null');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Driver Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("User not found."));
          }

          final user = snapshot.data!;

          return AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  const SizedBox(height: 20),
                  _buildSectionTitle("General"),
                  _buildSettingTile(
                    title: "Dark Mode",
                    icon: CupertinoIcons.moon_fill,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: MapStyleScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    title: "Ride History",
                    icon: CupertinoIcons.refresh_circled_solid,
                    onTap: () {
                      // TODO: Navigate to notification settings
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Account"),
                  _buildSettingTile(
                    title: "Edit Profile",
                    icon: CupertinoIcons.person_crop_circle,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: EditProfileScreen(
                            currentUserId: user.userid,
                            userModel: user,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSettingTile(
                    title: "Privacy Policy",
                    icon: CupertinoIcons.lock_shield,
                    onTap: () {
                      // TODO: Show privacy policy
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Support"),
                  _buildSettingTile(
                    title: "Support & Help",
                    icon: CupertinoIcons.info_circle,
                    onTap: () {
                      // TODO: Navigate to support page
                    },
                  ),
                  _buildSettingTile(
                    title: "Rate This App",
                    icon: CupertinoIcons.star_fill,
                    onTap: () {
                      // TODO: Open app store link
                    },
                  ),
                  const Divider(height: 40),
                  _buildSettingTile(
                    title: "Logout",
                    icon: CupertinoIcons.square_arrow_right,
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () {
                      Auth.logout();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // A simple title for each section of the settings.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // A custom tile for navigation and other actions.
  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.teal),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black87,
          ),
        ),
        trailing: const Icon(CupertinoIcons.forward, size: 18),
        onTap: onTap,
      ),
    );
  }
}

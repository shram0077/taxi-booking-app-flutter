import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/Profile/Edit_Profile/edit_profile.dart';
import 'package:taxi/Screens/Profile/passenger_profile.dart/Prefernces/map_style.dart';
import 'package:taxi/Screens/RideHistory/ride_history.dart';
import 'package:taxi/Services/Auth.dart';

class PassengerProfileScreen extends StatelessWidget {
  final UserModel userModel;

  const PassengerProfileScreen({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildProfileHeader(context, userModel),
              const SizedBox(height: 24),
              _buildSectionHeader("Ride Preferences"),
              _buildProfileMenuList(context, userModel),
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 800),
                child: const Center(
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Profile Header Widget
  Widget _buildProfileHeader(BuildContext context, UserModel userModel) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileAvatar(context, userModel),
          const SizedBox(width: 16),
          _buildUserInfo(context, userModel),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, UserModel userModel) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Hero widget for smooth transition
        Hero(
          tag: 'profile_picture_hero_${userModel.userid}',
          child: CircleAvatar(
            radius: 50,
            backgroundColor: secondaryColor,
            child: CachedNetworkImage(
              imageUrl: userModel.profilePicture,
              imageBuilder: (context, imageProvider) => CircleAvatar(
                radius: 48,
                backgroundImage: imageProvider,
              ),
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: 48,
                backgroundColor: secondaryColor,
                child: const Icon(CupertinoIcons.person_fill,
                    size: 50, color: Colors.grey),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeftWithFade,
                child: EditProfileScreen(
                  currentUserId: userModel.userid,
                  userModel: userModel,
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 16,
            backgroundColor: primaryColor,
            child: const Icon(EvaIcons.edit2Outline,
                size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context, UserModel userModel) {
    final theme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(userModel.name,
              style: theme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: darkTextColor)),
          const SizedBox(height: 8),
          _buildInfoRow(context, CupertinoIcons.phone,
              "0${userModel.phone.substring(4)}"),
          const SizedBox(height: 4),
          _buildInfoRow(context, CupertinoIcons.location, userModel.currentCity,
              isLocation: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text,
      {bool isLocation = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: lightTextColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: lightTextColor),
            overflow: TextOverflow.ellipsis,
            maxLines: isLocation ? 2 : 1,
          ),
        ),
      ],
    );
  }

  // MARK: - Menu List
  Widget _buildProfileMenuList(BuildContext context, UserModel userModel) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildMenuItem(context, icon: Icons.history, title: 'Ride History',
                onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeftWithFade,
                  duration: Duration(milliseconds: 400),
                  child: RideHistoryPage(userId: userModel.userid),
                ),
              );
            }),
            _buildMenuItem(context, icon: Icons.map_outlined, title: 'Map',
                onTap: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeftWithFade,
                  child: MapStyleScreen(),
                ),
              );
            }),
            _buildMenuItem(context,
                icon: Icons.language, title: 'Language', onTap: () {}),
            _buildMenuItem(context,
                icon: Icons.support_agent, title: 'Support', onTap: () {}),
            _buildMenuItem(context,
                icon: Icons.privacy_tip_outlined,
                title: 'Data Privacy',
                onTap: () {}),
            _buildMenuItem(context,
                icon: Icons.star_outline, title: 'Rate App', onTap: () {}),
            const SizedBox(height: 8),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Log Out',
              isDestructive: true,
              onTap: () {
                Auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? errorColor : darkTextColor;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
      ),
      trailing: isDestructive
          ? null
          : Icon(Icons.arrow_forward_ios, size: 16, color: lightTextColor),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/Phone_Authentication/Information_pages/driver_informations.dart';
import 'package:taxi/Screens/Phone_Authentication/Information_pages/passeners_informaion.dart';

class SelectYourRole extends StatefulWidget {
  const SelectYourRole({
    super.key,
    required this.phoneNo,
    required this.isRegistered,
  });

  final String phoneNo;
  final bool isRegistered;

  @override
  State<SelectYourRole> createState() => _SelectYourRoleState();
}

class _SelectYourRoleState extends State<SelectYourRole> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          "Select Role",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.language,
              color: Theme.of(context).iconTheme.color,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Title with animation
              Text(
                "Select Your Role!",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

              const SizedBox(height: 8),

              // Subtitle with animation
              Text(
                "Please tell us whether you're a taxi driver or a passenger",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),

              const SizedBox(height: 40),

              // Role cards with staggered animation
              Column(
                children: [
                  _buildRoleCard(
                    context,
                    title: "Taxi Driver",
                    iconPath: "assets/images/taxicap.png",
                    color: taxiYellowColor,
                    onTap: () => _navigateToDriverInfo(),
                  ).animate().fadeIn(delay: 300.ms).scale(),

                  const SizedBox(height: 24),

                  // Divider with animation
                  Divider(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    thickness: 1,
                    indent: 40,
                    endIndent: 40,
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 24),

                  _buildRoleCard(
                    context,
                    title: "Passenger",
                    iconPath: "assets/images/passenger.png",
                    color: primaryColor,
                    onTap: () => _navigateToPassengerInfo(),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String iconPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Image.asset(
                    iconPath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDriverInfo() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: 500.ms,
        curve: Curves.easeOutCubic,
        child: DriverInfoForm(phoneNo: widget.phoneNo),
      ),
    );
  }

  void _navigateToPassengerInfo() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: 500.ms,
        curve: Curves.easeOutCubic,
        child: PassenersInformaion(phoneNo: widget.phoneNo),
      ),
    );
  }
}

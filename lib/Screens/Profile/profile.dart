import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/Car_Model.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/Profile/driver_profile/profile.dart';
import 'package:taxi/Screens/Profile/driver_profile/settings/setting_page.dart';
import 'package:taxi/Screens/Profile/passenger_profile.dart/profile.dart';
import 'package:taxi/Utils/texts.dart';

class ProfilePage extends StatefulWidget {
  final String currentUserId;
  final String visitedUserId;

  const ProfilePage({
    super.key,
    required this.currentUserId,
    required this.visitedUserId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? userModel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: usersRef.doc(widget.visitedUserId).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (userSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error loading profile: ${userSnapshot.error}',
                style: GoogleFonts.alef(fontSize: 14, color: Colors.red),
              ),
            ),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Scaffold(body: Center(child: Text("User not found.")));
        }

        userModel = UserModel.fromDoc(userSnapshot.data!);

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  actions: [
                    userModel!.role == "driver"
                        ? IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SettingsPage(
                                      currentUserId: widget.currentUserId),
                                ),
                              );
                            },
                            icon: Icon(Icons.settings),
                          )
                        : SizedBox.shrink(), // <- Show nothing if not driver
                  ],
                  centerTitle: true,
                  pinned: true,
                  floating: false,
                  expandedHeight: 100.0,
                  backgroundColor: primaryColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                  ),
                  iconTheme: IconThemeData(color: whiteColor),
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        EdgeInsets.only(left: 16, bottom: 16, right: 16),
                    title: robotoText(
                        "Profile", whiteColor, 20, FontWeight.normal),
                  ),
                ),
              ];
            },
            body: userModel!.role != 'driver'
                ? PassengerProfileScreen(userModel: userModel!)
                : StreamBuilder<DocumentSnapshot>(
                    stream: taxisRef.doc(widget.visitedUserId).snapshots(),
                    builder: (context, carSnapshot) {
                      if (carSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (carSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading car info: ${carSnapshot.error}',
                            style: GoogleFonts.alef(
                                fontSize: 14, color: Colors.red),
                          ),
                        );
                      }

                      if (!carSnapshot.hasData || !carSnapshot.data!.exists) {
                        return Center(
                            child: Text("No car information available"));
                      }

                      CarModel carModel = CarModel.fromDoc(carSnapshot.data!);

                      return driverProfile(
                        userModel!,
                        carModel,
                        widget.currentUserId,
                        context,
                        mockRides,
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  List<Map<String, String>> mockRides = [
    {
      'pickupLocation': 'Sarchinar',
      'destination': 'Raparin',
      'date': '2025-03-01',
    },
    {
      'pickupLocation': 'Sarchinar',
      'destination': 'Family mall',
      'date': '2025-02-28',
    },
    {
      'pickupLocation': 'Sarchinar',
      'destination': 'Family mall',
      'date': '2025-02-27',
    },
  ];
}

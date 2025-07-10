import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/bookingRide/start_booking.dart';
import 'package:taxi/Utils/Loadings/AppBar_loading.dart';
import 'package:taxi/Utils/Loadings/Cardwallet_loading.dart';
import 'package:taxi/Utils/Loadings/bookRide_loading.dart';
import 'package:taxi/Screens/payments/contents/cardWallet.dart';
import 'package:taxi/Utils/homeAppBar.dart';
import 'package:taxi/Utils/texts.dart';

class HomePage extends StatefulWidget {
  final String currentUserId;

  const HomePage({super.key, required this.currentUserId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  bool _isLocationPermissionGranted = false;
  @override
  void initState() {
    super.initState();
    // I want only when the userModel.rules quals driver can listen for Ride Requests

    WidgetsBinding.instance.addObserver(this);

    _handleLocationPermission();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleLocationPermission();
    }
  }

  // --- NEW: A single, reusable, beautifully styled dialog ---
  Future<void> _showAppStyledDialog({
    required IconData icon,
    required String title,
    required String content,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) async {
    // Prevent dialogs from showing if the widget is not in the tree.
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: taxiYellowColor, size: 60),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: taxiDarkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: taxiDarkText.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: taxiYellowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onButtonPressed();
                },
                child:
                    robotoText(buttonText, taxiDarkText, 16, FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MODIFIED: Use the new styled dialog for GPS service
  Future<void> _showLocationServiceDialog() async {
    await _showAppStyledDialog(
      icon: Icons.location_on_outlined,
      title: 'Turn On Location',
      content:
          'To find rides near you, please turn on your device location (GPS).',
      buttonText: 'Open Settings',
      onButtonPressed: () => Geolocator.openLocationSettings(),
    );
  }

  // MODIFIED: Use the new styled dialog for app permissions
  Future<void> _showPermissionDialog() async {
    await _showAppStyledDialog(
      icon: Icons.settings_suggest_outlined,
      title: 'Permission Required',
      content:
          'This app needs location permission to function. Please grant it in your app settings.',
      buttonText: 'Open App Settings',
      onButtonPressed: () => openAppSettings(),
    );
  }

  // This core logic remains the same, ensuring reliability.
  Future<void> _handleLocationPermission() async {
    final serviceStatus = await Permission.location.serviceStatus;
    if (serviceStatus.isDisabled) {
      if (mounted) await _showLocationServiceDialog();
      return;
    }

    var permissionStatus = await Permission.location.status;
    if (permissionStatus.isDenied) {
      permissionStatus = await Permission.location.request();
      if (permissionStatus.isDenied) {
        if (mounted) setState(() => _isLocationPermissionGranted = false);
        return;
      }
    }

    if (permissionStatus.isPermanentlyDenied) {
      if (mounted) await _showPermissionDialog();
      return;
    }

    if (mounted && permissionStatus.isGranted != _isLocationPermissionGranted) {
      setState(() {
        _isLocationPermissionGranted = permissionStatus.isGranted;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  // ... (getUserModel, build, and buildHomeContent methods remain unchanged)

  Future<UserModel?> getUserModel(String userId) async {
    try {
      DocumentSnapshot userDoc = await usersRef.doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromDoc(userDoc);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _key,
        body: FutureBuilder<UserModel?>(
          future: getUserModel(widget.currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  loadingAppBarContainer(),
                  const SizedBox(height: 25),
                  buildLoadingCard(),
                  const Divider(indent: 30, endIndent: 30),
                  const Spacer(),
                  // i dont know what i put(create) in this space?
                  loadingBookRideButton(),
                ],
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text("Failed to load user data."));
            }
            final userModel = snapshot.data!;
            return buildHomeContent(userModel);
          },
        ));
  }

  Widget buildHomeContent(UserModel userModel) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeAppBar(currentUserId: widget.currentUserId),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: WalletCard(isLoading: false, userModel: userModel),
            ),
            const Divider(indent: 30, endIndent: 30),
            const Spacer(),
          ],
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Material(
                borderRadius: BorderRadius.circular(40),
                elevation: 12,
                shadowColor:
                    taxiYellowColor.withOpacity(_glowAnimation.value * 0.6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  splashColor: taxiYellowColor.withOpacity(0.3),
                  highlightColor: taxiYellowColor.withOpacity(0.1),
                  onTap: () async {
                    await _handleLocationPermission();
                    if (_isLocationPermissionGranted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StartBooking(
                            currentUserId: widget.currentUserId,
                            userModel: userModel,
                          ),
                        ),
                      );
                    } else {
                      return _showLocationServiceDialog();
                    }
                  },
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: taxiYellowColor,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: taxiYellowColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/images/taxicap.png",
                          width: 36,
                          height: 36,
                        ),
                        const SizedBox(width: 16),
                        robotoText(
                          userModel.role == 'driver'
                              ? "Start driving now"
                              : "Book a Ride",
                          taxiDarkText,
                          20,
                          FontWeight.bold,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.drive_eta_outlined,
                          color: taxiDarkText,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

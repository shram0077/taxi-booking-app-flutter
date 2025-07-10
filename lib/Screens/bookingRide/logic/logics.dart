import 'package:alert_info/alert_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Screens/bookingRide/DriverSide/Driver_RideTracking.dart';
import 'package:taxi/Screens/bookingRide/PassengerSide/RideTrackingPage.dart';
import 'package:taxi/Utils/alerts.dart';

void listenForRideRequests(
  String currentUserId,
  BuildContext context,
  double driverlat,
  double driverlng,
  void Function(String path) playSound,
) {
  rideRequests
      .where('driverId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snapshot) {
    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.added) {
        final data = docChange.doc.data();
        if (data != null) {
          data['requestId'] = docChange.doc.id;
          showRideRequestDialog(data, context, driverlat, driverlng);
          playSound('sounds/software-interface-start.mp3'); // 👈 Call it
        }
      }
    }
  });
}

void showRideRequestDialog(Map<String, dynamic> data, BuildContext context,
    double driverLat, double driverLng) {
  final fare = data['fare'] ?? 0.0;
  final distance = data['distance'] ?? 0.0;

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) {
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.fastOutSlowIn,
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          insetAnimationCurve: Curves.easeOutQuart,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Title with shimmer effect
                Text(
                  'New Ride Request!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 20),

                // Passenger Info with smooth appearance
                Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          NetworkImage(data['passengerImage'] ?? ''),
                      child: data['passengerImage'] == null
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ).animate().scale(delay: 100.ms),
                    const SizedBox(height: 12),
                    Text(
                      data['passengerName'] ?? 'Passenger',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),

                const SizedBox(height: 24),

                // Fare Information Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Fare',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Text(
                            '\$${fare.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      Column(
                        children: [
                          Text(
                            'Distance',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 20),

                // Location Cards with staggered animation
                Column(
                  children: [
                    _buildLocationCard(
                      context,
                      icon: Icons.location_pin,
                      iconColor: Colors.red,
                      title: "Pickup",
                      address: data['origin']['address'] ?? 'Not specified',
                    ).animate().slideX(
                          begin: -0.5,
                          duration: 300.ms,
                          delay: 300.ms,
                        ),
                    const SizedBox(height: 12),
                    _buildLocationCard(
                      context,
                      icon: Icons.flag,
                      iconColor: Colors.green,
                      title: "Destination",
                      address:
                          data['destination']['address'] ?? 'Not specified',
                    ).animate().slideX(
                          begin: 0.5,
                          duration: 300.ms,
                          delay: 400.ms,
                        ),
                  ],
                ),

                const SizedBox(height: 28),

                // Buttons with ripple animation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.check_circle,
                      label: "Accept",
                      color: Colors.green,
                      onTap: () =>
                          acceptRide(data, driverLat, driverLng, context),
                    ).animate().scale(delay: 500.ms),
                    _buildActionButton(
                      context,
                      icon: Icons.cancel,
                      label: "Decline",
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).pop();
                        rejectRide(data);
                      },
                    ).animate().scale(delay: 600.ms),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildLocationCard(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String address,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                address,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 22),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 2,
      shadowColor: color.withOpacity(0.3),
    ),
  );
}

Future<bool> canSendRideRequestToDriver(
    String driverId, String passengerId) async {
  final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

  final querySnapshot = await FirebaseFirestore.instance
      .collection('rideRequests')
      .where('passengerId', isEqualTo: passengerId)
      .where('driverId', isEqualTo: driverId)
      .where('requestedAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
      .get();

  // Allow max 3 requests per hour per driver
  return querySnapshot.docs.length < 3;
}

void acceptRide(
  Map<String, dynamic> data,
  double driverLat,
  double driverLng,
  BuildContext context,
) async {
  final String? requestId = data['requestId'];
  final String? driverId = data['driverId'];

  if (requestId == null || driverId == null) {
    debugPrint("[acceptRide] Missing requestId or driverId");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ride data is incomplete.")),
    );
    return;
  }

  try {
    // Update ride request in Firestore
    await rideRequests.doc(requestId).update({
      'status': 'accepted',
      'driverId': driverId,
      'driverLocation': {
        'lat': driverLat,
        'lng': driverLng,
      },
    });

    // Update driver's status
    await taxisRef.doc(driverId).update({'status': 'riding'});

    debugPrint("[acceptRide] Ride accepted successfully");

    // Delay for smoother UI transition
    await Future.delayed(const Duration(milliseconds: 300));

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: DriverRideManagementPage(
            rideRequestId: requestId,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint("[acceptRide] Error: $e");

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to accept ride: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

void rejectRide(Map<String, dynamic> data) async {
  await rideRequests
      .doc(data['requestId']) // ✅ This will now exist
      .update({'status': 'rejected'});
}

void monitorRideRequest(
  String requestId,
  String role,
  BuildContext context,
  void Function(String path) playSound,
  Map<String, dynamic> requestData, // Your request fields
) async {
  final requestDoc = rideRequests.doc(requestId);

  requestDoc.snapshots().listen((snapshot) async {
    final data = snapshot.data();
    if (data == null) return;

    final status = data['status'];

    if (status == 'accepted') {
      debugPrint("Ride accepted");

      try {
        playSound('sounds/confirmation.mp3');
      } catch (e) {
        debugPrint("Error playing sound: $e");
      }

      alertInfo(
        context,
        "Your ride has been accepted! The driver is on the way.",
        EvaIcons.checkmark,
        TypeInfo.success,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (role == 'passenger') {
          Navigator.pushReplacement(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              child: PassengerRideTrackingPage(
                driverId: data['driverId'],
                rideRequestId: requestId,
              ),
            ),
          );
        }
      });
    }

    // ✅ Save to ride_history when completed
    if (status == 'completed') {
      debugPrint("Ride completed – saving to history...");

      final existing = await rideHistory
          .where('rideId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        // 🟡 Fetch driver info from Firestore
        final driverDoc = await usersRef.doc(requestData['driverId']).get();
        final driverData = driverDoc.data();

        await rideHistory.add({
          'rideId': requestId,
          'userId': requestData['passengerId'],
          'driverId': requestData['driverId'],
          'driverName': driverData?['name'] ?? '',
          'driverImage': driverData?['profilePicture'] ?? '',
          'origin': requestData['origin'],
          'destination': requestData['destination'],
          'pickupAddress': requestData['origin']['address'],
          'dropOffAddress': requestData['destination']['address'],
          'requestedAt': DateTime.now().millisecondsSinceEpoch,
          'completedAt': DateTime.now().millisecondsSinceEpoch,
          'fare': data['fare'] ?? 0,
          'status': 'completed',
          'paymentMethod': data['paymentMethod'] ?? 'cash',
          'distance': data['distance'] ?? 0,
          'duration': data['duration'] ?? 0,
        });

        debugPrint("✅ Ride history saved for $requestId");
      }
    }
  });

  // Optional timeout
  Future.delayed(const Duration(seconds: 60), () async {
    final doc = await requestDoc.get();
    if (doc.exists && doc['status'] == 'pending') {
      await requestDoc.update({'status': 'timeout'});
    }
  });
}

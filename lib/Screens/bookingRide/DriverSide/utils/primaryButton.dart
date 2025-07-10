import 'package:alert_info/alert_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Utils/alerts.dart';

class PrimaryActionButton extends StatelessWidget {
  final String currentStatus;
  final String rideId;

  // Add these for distance check
  final LatLng? driverLocation;
  final LatLng? destinationLocation;

  const PrimaryActionButton({
    super.key,
    required this.currentStatus,
    required this.rideId,
    this.driverLocation,
    this.destinationLocation,
  });

  void _updateRideStatus(BuildContext context, String newStatus) {
    rideRequests.doc(rideId).update({'status': newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ride status updated to $newStatus')),
    );
  }

  String get _buttonText {
    switch (currentStatus) {
      case 'arrived':
        return 'Complete Ride';
      default:
        return '';
    }
  }

  IconData get _buttonIcon {
    switch (currentStatus) {
      case 'arrived':
        return Icons.check_circle_rounded;
      default:
        return Icons.error;
    }
  }

  bool get _canComplete {
    if (currentStatus != 'arrived' ||
        driverLocation == null ||
        destinationLocation == null) {
      return false;
    }

    final distanceMeters = Geolocator.distanceBetween(
      driverLocation!.latitude,
      driverLocation!.longitude,
      destinationLocation!.latitude,
      destinationLocation!.longitude,
    );

    // Threshold distance in meters to allow completion
    const threshold = 50;
    return distanceMeters <= threshold;
  }

  VoidCallback? _getOnPressed(BuildContext context) {
    return () async {
      if (driverLocation == null || destinationLocation == null) {
        alertInfo(context, 'Location data unavailable.', CupertinoIcons.info,
            TypeInfo.warning);
        return;
      }

      final distanceMeters = Geolocator.distanceBetween(
        driverLocation!.latitude,
        driverLocation!.longitude,
        destinationLocation!.latitude,
        destinationLocation!.longitude,
      );

      if (distanceMeters > 50) {
        alertInfo(
          context,
          'You are too far from the destination to complete the ride.\n(${distanceMeters.toStringAsFixed(1)} meters away)',
          CupertinoIcons.location,
          TypeInfo.warning,
        );
        return;
      }

      // ✅ Only complete if close enough
      _updateRideStatus(context, 'completed');
    };
  }

  Color get _buttonColor {
    if (currentStatus == 'arrived' &&
        driverLocation != null &&
        destinationLocation != null) {
      final distance = Geolocator.distanceBetween(
        driverLocation!.latitude,
        driverLocation!.longitude,
        destinationLocation!.latitude,
        destinationLocation!.longitude,
      );
      return distance <= 50 ? Colors.green : Colors.grey;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'completed' || currentStatus == 'cancelled') {
      return Center(
        child: Text(
          currentStatus == 'completed'
              ? "Trip is Complete!"
              : "Trip was Cancelled",
          style: GoogleFonts.lato(
            fontSize: 18,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // If not in 'arrived' status, no button shown
    if (currentStatus != 'arrived') return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _getOnPressed(context),
        icon: Icon(_buttonIcon, color: Colors.white),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            _buttonText,
            key: ValueKey<String>(_buttonText),
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

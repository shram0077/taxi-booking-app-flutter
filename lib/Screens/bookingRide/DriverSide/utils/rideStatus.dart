import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RideStatusIndicator extends StatelessWidget {
  final String status;
  const RideStatusIndicator({super.key, required this.status});

  Color _getStatusColor() {
    switch (status) {
      case 'accepted':
        return Colors.blueAccent;
      case 'en_route':
        return Colors.orangeAccent;
      case 'arrived':
        return Colors.greenAccent;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.black;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'accepted':
        return "Driver Accepted - Heading to Pick You Up";
      case 'en_route':
        return "En Route - Enjoy Your Ride";
      case 'arrived':
        return "Arrival - You've Reached Your Destination";
      case 'completed':
        return "Trip Completed - Thank You for Riding!";
      case 'cancelled':
        return "Trip Cancelled - We Hope to See You Again";
      default:
        return "Status: ${status.replaceAll('_', ' ').toUpperCase()}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          _getStatusText(),
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: _getStatusColor(),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

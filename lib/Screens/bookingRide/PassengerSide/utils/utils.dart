import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildEtaAndDistanceBadge(
    double estimatedMinutes, double estimatedDistance) {
  if (estimatedMinutes == null || estimatedDistance == null) {
    return const SizedBox.shrink();
  }
  return Positioned(
    top: 100,
    left: 20,
    right: 20,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.time_solid,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '${estimatedMinutes.toStringAsFixed(0)} min',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Text('  •  ',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            Text(
              '${estimatedDistance.toStringAsFixed(1)} km',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildDriverInfoSection(
    Map<String, dynamic>? driverData, Map<String, dynamic>? carData) {
  return Row(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[200],
        backgroundImage:
            driverData != null && driverData['profilePicture'] != null
                ? CachedNetworkImageProvider(driverData['profilePicture'])
                : null,
        child: driverData == null || driverData['profilePicture'] == null
            ? const Icon(Icons.person, size: 30, color: Colors.grey)
            : null,
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            driverData?['name'] ?? 'Loading driver...',
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.numbers, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                (carData?['taxiNumber']?.toString()) ?? 'N/A',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget buildActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
  Color color = Colors.blue,
}) {
  return Column(
    children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: color.withOpacity(0.1),
        child: IconButton(
          icon: Icon(icon, color: color, size: 26),
          onPressed: onPressed,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

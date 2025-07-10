import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';

class RideHistoryPage extends StatelessWidget {
  final String userId;

  const RideHistoryPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ride History",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: rideHistory
            .where('userId', isEqualTo: userId)
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          final rides = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: rides.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ride = rides[index].data() as Map<String, dynamic>;
              return RideHistoryCard(ride: ride);
            },
          );
        },
      ),
    );
  }
}

class RideHistoryCard extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideHistoryCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Safely handle timestamp
    final timestamp = ride['completedAt'] is Timestamp
        ? (ride['completedAt'] as Timestamp).toDate()
        : DateTime.now();

    final formattedDate = DateFormat('MMMM d, yyyy').format(timestamp);
    final formattedTime = DateFormat('h:mm a').format(timestamp);

    final pickupAddress = ride['pickupAddress'] ?? 'Unknown pickup location';
    final dropOffAddress = ride['dropOffAddress'] ?? 'Unknown destination';
    final driverName = ride['driverName'] ?? 'Unknown Driver';
    final driverImage = ride['driverImage'] ?? '';
    final distance = ride['distance']?.toStringAsFixed(1) ?? '--';
    final fare = ride['fare']?.toStringAsFixed(2) ?? '--';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date and Fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: darkTextColor,
                  ),
                ),
                Text(
                  "IQD $fare",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: theme.colorScheme.secondary,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),

            // Route Information
            _buildRouteInfo(context, pickupAddress, dropOffAddress),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),

            // Driver and Ride Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Driver Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: driverImage.isNotEmpty
                          ? CachedNetworkImageProvider(driverImage)
                          : null,
                      child: driverImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Driver",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Distance
                Row(
                  children: [
                    Icon(Icons.drive_eta, color: primaryColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "$distance km",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context, String from, String to) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical line with icons
        Column(
          children: [
            const Icon(Icons.trip_origin, color: Colors.blue, size: 20),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.shade300,
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 20),
          ],
        ),
        const SizedBox(width: 12),
        // Addresses
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              Text(
                to,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: theme.colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            "No Past Rides",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your completed trips will appear here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

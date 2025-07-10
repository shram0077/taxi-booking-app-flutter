import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/Car_Model.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Utils/plateCar.dart';

class TaxiInfoSheet extends StatelessWidget {
  final String taxiId;
  final ScrollController scrollController;
  final double distanceInKm;
  final bool fromNearest;
  final String destinationAddress;
  final VoidCallback onBookPressed;
  final bool isDark;
  const TaxiInfoSheet({
    super.key,
    required this.taxiId,
    required this.scrollController,
    required this.distanceInKm,
    required this.fromNearest,
    required this.destinationAddress,
    required this.onBookPressed,
    required this.isDark,
  });

  bool get hasDestination => destinationAddress.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: taxisRef.doc(taxiId).snapshots(),
          builder: (context, carSnapshot) {
            if (carSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!carSnapshot.hasData || !carSnapshot.data!.exists) {
              return Center(
                child: Text(
                  "Taxi information not found.",
                  style: GoogleFonts.poppins(),
                ),
              );
            }

            final car = CarModel.fromDoc(carSnapshot.data!);

            return StreamBuilder<DocumentSnapshot>(
              stream: usersRef.doc(car.driverId).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return Center(
                    child: Text(
                      "Driver profile not found.",
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }

                final user = UserModel.fromDoc(userSnapshot.data!);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.black,
                            backgroundImage: user.profilePicture.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    user.profilePicture)
                                : null,
                            child: user.profilePicture.isEmpty
                                ? const Icon(
                                    CupertinoIcons.person_fill,
                                    color: Colors.white,
                                    size: 36,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: car.status == 'available'
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        user.name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? secondaryColor : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => const Icon(
                                CupertinoIcons.star_fill,
                                color: Colors.amber,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDistance(distanceInKm),
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              if (fromNearest) ...[
                                Text(
                                  "•",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "from Nearest",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          )
                        ],
                      ),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(CupertinoIcons.phone,
                          color:
                              isDark ? secondaryColor.withOpacity(0.6) : null),
                      title: Text(
                        "Phone",
                        style: GoogleFonts.poppins(
                            color: isDark ? secondaryColor : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal),
                      ),
                      subtitle: Text(
                        user.phone.isNotEmpty
                            ? user.phone
                            : car.phone.isNotEmpty
                                ? car.phone
                                : 'Not available',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(CupertinoIcons.car_detailed,
                          color:
                              isDark ? secondaryColor.withOpacity(0.6) : null),
                      title: Text(
                        "Car Model",
                        style: GoogleFonts.poppins(
                            color: isDark ? secondaryColor : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal),
                      ),
                      subtitle: Text(
                        car.carModel,
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    customLicensePlateTile(car.licensePlate, isDark),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton.filled(
                            color: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: onBookPressed,
                            child: Text(
                              "Book",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.black,
                            child: Text(
                              "Close",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDistance(double distanceInKm) {
    final int km = distanceInKm.floor();
    final int meters = ((distanceInKm - km) * 1000).round();

    if (km == 0) {
      return "${meters}m";
    } else if (meters == 0) {
      return "${km}km";
    } else {
      return "${km}km ${meters}m";
    }
  }
}

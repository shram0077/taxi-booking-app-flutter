import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Models/Car_Model.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/Profile/Edit_Profile/edit_profile.dart';
import 'package:taxi/Screens/Profile/utils/plateCar.dart';
import 'package:taxi/Utils/texts.dart';

Widget driverProfile(
  UserModel userModel,
  CarModel? carModel,
  String currentUserId,
  BuildContext context,
  List<Map<String, String>> mockRides,
) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(userModel, context),
        const Divider(),
        _buildWalletSection(userModel),
        const Divider(),
        VehicleInfoCard(carModel: carModel),
        const Divider(),
        _buildRecentRides(mockRides),
      ],
    ),
  );
}

Widget _buildProfileHeader(UserModel userModel, BuildContext context) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 56.5,
            backgroundColor: greenColor2,
            child: CircleAvatar(
              radius: 55,
              backgroundImage: userModel.profilePicture.isNotEmpty
                  ? CachedNetworkImageProvider(userModel.profilePicture)
                  : const AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeftWithFade,
                child: EditProfileScreen(
                  currentUserId: userModel.userid,
                  userModel: userModel,
                ),
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: greenColor2,
              child: const Icon(EvaIcons.edit2Outline,
                  size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            robotoText(userModel.name.isNotEmpty ? userModel.name : 'N/A',
                Colors.black, 22, FontWeight.bold),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: robotoText(
                    userModel.phone.length > 4
                        ? "0${userModel.phone.substring(4)}"
                        : "N/A",
                    Colors.grey,
                    16,
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(CupertinoIcons.location,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: robotoText(
                    userModel.currentCity.isNotEmpty
                        ? userModel.currentCity
                        : 'N/A',
                    Colors.grey,
                    16,
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildRating(),
          ],
        ),
      ),
    ],
  );
}

Widget _buildWalletSection(UserModel userModel) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      robotoText("Wallet Balance", Colors.black, 18, FontWeight.bold),
      robotoText(
          "${userModel.walletBalance} IQD", greenColor2, 22, FontWeight.bold),
      robotoText(
          "Total Earnings: 15,500 IQD", Colors.black54, 16, FontWeight.normal),
    ],
  );
}

class VehicleInfoCard extends StatelessWidget {
  final CarModel? carModel;

  const VehicleInfoCard({super.key, this.carModel});

  @override
  Widget build(BuildContext context) {
    final carDetails = carModel?.carModel.split(',') ?? [];
    final carBrand = carDetails.isNotEmpty ? carDetails[0].trim() : 'Unknown';
    final carYear = carDetails.length > 1 ? carDetails[1].trim() : 'N/A';

    return Card(
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            robotoText(
                "Vehicle Information", Colors.black87, 18, FontWeight.bold),
            const SizedBox(height: 16),
            _buildInfoRow(
                icon: CupertinoIcons.car, label: "Brand", value: carBrand),
            const Divider(height: 24, thickness: 0.5),
            _buildInfoRow(
                icon: EvaIcons.calendarOutline, label: "Model", value: carYear),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(EvaIcons.fileTextOutline,
                        color: Colors.grey.shade600, size: 22),
                    const SizedBox(width: 12),
                    robotoText("License Plate", Colors.grey.shade700, 16,
                        FontWeight.w500),
                  ],
                ),
                plateCar(50, carModel?.licensePlate ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 12),
        robotoText(label, Colors.grey.shade700, 16, FontWeight.w500),
        const Spacer(),
        robotoText(value, Colors.black87, 16, FontWeight.w600),
      ],
    );
  }
}

Widget _buildRecentRides(List<Map<String, String>> mockRides) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      robotoText("Recent Rides", Colors.black, 18, FontWeight.bold),
      const SizedBox(height: 10),
      if (mockRides.isEmpty)
        Center(
          child:
              robotoText("No recent rides", Colors.grey, 16, FontWeight.normal),
        )
      else
        ...mockRides.map((ride) => _RideHistoryCard(ride: ride)),
    ],
  );
}

class _RideHistoryCard extends StatelessWidget {
  final Map<String, String> ride;
  const _RideHistoryCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Icon(Icons.arrow_circle_up_rounded, color: greenColor2, size: 28),
              Container(width: 2, height: 30, color: Colors.grey.shade300),
              Icon(Icons.arrow_circle_down_rounded,
                  color: Colors.grey.shade500, size: 28),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: greenColor2, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride['pickupLocation'] ?? 'N/A',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ride['destination'] ?? 'N/A',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "2,500 IQD",
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontSize: 16, color: greenColor2),
              ),
              const SizedBox(height: 20),
              Text(
                ride['date'] ?? 'N/A',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildRating() {
  return Row(
    children: List.generate(
      5,
      (index) => const Icon(EvaIcons.star, color: Colors.amber, size: 20),
    ),
  );
}

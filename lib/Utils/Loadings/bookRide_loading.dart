import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:taxi/Constant/colors.dart';

Widget loadingBookRideButton() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: primaryColor,
    child: Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle placeholder for image
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // Text placeholder bar
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi/Constant/colors.dart';

Widget loadingAppBarContainer() {
  return Shimmer.fromColors(
    baseColor: primaryColor,
    highlightColor: Colors.white.withOpacity(0.8),
    child: Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        color: splashGreenBGColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    ),
  );
}

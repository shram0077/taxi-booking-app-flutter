import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi/Constant/colors.dart';

Widget buildLoadingCard() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: primaryColor,
    child: Card(
      elevation: 8,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(8)),
                  width: 100,
                  height: 24,
                ),
                Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(8))),
              ],
            ),
            const SizedBox(height: 20),
            Container(
                width: 180,
                height: 30,
                decoration: BoxDecoration(
                    color: whiteColor, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                    width: 140,
                    height: 45,
                    decoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(8))),
                Row(
                  children: [
                    Container(
                        width: 55,
                        height: 70,
                        decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(8))),
                    const SizedBox(width: 10),
                    Container(
                        width: 55,
                        height: 70,
                        decoration: BoxDecoration(
                            color: whiteColor,
                            borderRadius: BorderRadius.circular(8))),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

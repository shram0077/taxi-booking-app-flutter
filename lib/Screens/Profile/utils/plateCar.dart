import 'package:flutter/material.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Utils/texts.dart';

Widget plateCar(double h, String plateString) {
  // Split the plateString into parts
  List<String> parts = plateString.split(" ");
  String provinceNumber = parts.isNotEmpty ? parts[0] : "";
  String letter = parts.length > 1 ? parts[1] : "";
  String plateNumber = parts.length > 2 ? parts[2] : "";

  // Calculate dynamic width based on text size
  double textWidth =
      _calculateTextWidth("$provinceNumber $letter $plateNumber");

  return Container(
    width: textWidth + 40, // Adding padding and red section width
    height: h,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(7),
      color: const Color.fromARGB(255, 244, 242, 242),
    ),
    child: Row(
      children: [
        /// **RED SECTION (IRQ + KR)**
        Container(
          width: 30, // Fixed width for the red section
          height: h,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 249, 30, 14),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _plateText("I"),
              _plateText("R"),
              _plateText("Q"),
              Container(
                  width: 30, color: blackColor.withOpacity(0.9), height: 0.3),
              _plateText("KR"),
            ],
          ),
        ),

        /// **WHITE SECTION (PLATE NUMBER)**
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _numberText(provinceNumber),
              const SizedBox(width: 4),
              _numberText(letter),
              const SizedBox(width: 4),
              _numberText(plateNumber),
            ],
          ),
        ),
      ],
    ),
  );
}

/// **Calculate dynamic text width**
double _calculateTextWidth(String text) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return textPainter.width;
}

/// **Helper function for red section text**
Widget _plateText(String text) {
  return FittedBox(
      fit: BoxFit.scaleDown,
      child: robotoText(text, whiteColor, 8, FontWeight.w900));
}

/// **Helper function for plate number text**
Widget _numberText(String text) {
  return robotoText(text, blackColor, 17, FontWeight.bold);
}

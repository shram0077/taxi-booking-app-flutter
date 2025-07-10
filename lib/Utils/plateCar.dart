import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi/Constant/colors.dart';

Widget customLicensePlateTile(String licensePlate, bool isDark) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 16, top: 4),
          child: Icon(CupertinoIcons.number,
              size: 24,
              color: isDark ? secondaryColor.withOpacity(0.6) : Colors.black54),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "License Plate",
                style: GoogleFonts.poppins(
                  color: isDark ? secondaryColor : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: buildPlateFromText(licensePlate),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildPlateFromText(String plateText) {
  final parts = plateText.trim().split(' ');
  if (parts.length >= 3) {
    return buildPlate(
      provinceNumber: parts[0],
      letter: parts[1],
      number: parts.sublist(2).join(' '),
    );
  } else {
    return Text(
      'Invalid Plate Format',
      style: GoogleFonts.poppins(color: Colors.red),
    );
  }
}

Widget buildPlate({
  required String provinceNumber,
  required String letter,
  required String number,
}) {
  double h = 45;

  return Container(
    constraints: const BoxConstraints(
      maxWidth: 200,
      minWidth: 120,
      minHeight: 45,
      maxHeight: 45,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black),
      borderRadius: BorderRadius.circular(6),
      color: const Color.fromARGB(255, 244, 242, 242),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: h,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 249, 30, 14),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("I", style: _plateSideTextStyle(smaller: true)),
              Text("R", style: _plateSideTextStyle(smaller: true)),
              Text("Q", style: _plateSideTextStyle(smaller: true)),
              Container(
                width: 20,
                color: Colors.black.withOpacity(0.9),
                height: 0.3,
              ),
              Text("KR", style: _plateSideTextStyle(smaller: true)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provinceNumber, style: _plateMainTextStyle(smaller: true)),
              Text(" $letter ", style: _plateMainTextStyle(smaller: true)),
              Text(number, style: _plateMainTextStyle(smaller: true)),
            ],
          ),
        ),
      ],
    ),
  );
}

TextStyle _plateMainTextStyle({bool smaller = false}) => GoogleFonts.poppins(
      fontSize: smaller ? 18 : 25,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _plateSideTextStyle({bool smaller = false}) => GoogleFonts.poppins(
      fontSize: smaller ? 7 : 9.5,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

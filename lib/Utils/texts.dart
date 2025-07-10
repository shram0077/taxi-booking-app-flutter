import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget robotoText(
  String text,
  Color color,
  double size,
  FontWeight fontWeight,
) {
  return Text(
    text,
    style: GoogleFonts.poppins(
        color: color, fontWeight: fontWeight, fontSize: size),
  );
}

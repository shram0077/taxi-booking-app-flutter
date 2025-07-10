import 'package:flutter/material.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Utils/texts.dart';

class CoustomTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool islogoutTile;
  final VoidCallback? onTap;

  const CoustomTile({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = Colors.white,
    this.onTap,
    required this.islogoutTile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1), // Soft shadow color
                blurRadius: 10, // Smooth blur effect
                spreadRadius: 3, // Spread effect for a realistic look
                offset: Offset(0, 5), // Shadow position (slightly below)
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: islogoutTile ? Colors.red : greenColor2,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                width: 70,
                height: 70,
                child: Icon(icon, color: iconColor),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    robotoText(title, Colors.black, 17, FontWeight.w500),
                  ],
                ),
              ),
              islogoutTile
                  ? SizedBox()
                  : Icon(Icons.arrow_forward_ios, color: greenColor2),
              SizedBox(width: 10), // Added spacing for better alignment
            ],
          ),
        ),
      ),
    );
  }
}

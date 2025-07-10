import 'package:flutter/material.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Utils/texts.dart';
import 'package:page_transition/page_transition.dart';

Widget buildCardSelection(
    BuildContext context, // Add BuildContext
    String imgPath,
    String sloganText,
    Widget destinationScreen,
    Color color // Pass the screen to navigate to
    ) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.bottomToTop, // Animation type
          child: destinationScreen, // Navigate to this screen
        ),
      );
    },
    child: Card(
      child: Container(
        width: 155,
        height: 150,
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 5),
            SizedBox(height: 100, child: Image.asset(imgPath)),
            const Spacer(),
            Container(
              width: 155,
              height: 40,
              decoration: ShapeDecoration(
                color: whiteColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              child: Center(
                child: robotoText(sloganText, blackColor, 17, FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LoadingCardSelection extends StatefulWidget {
  final String imgPath;
  final String sloganText;
  final Color color;

  const LoadingCardSelection({
    super.key,
    required this.imgPath,
    required this.sloganText,
    required this.color,
  });

  @override
  _LoadingCardSelectionState createState() => _LoadingCardSelectionState();
}

class _LoadingCardSelectionState extends State<LoadingCardSelection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(); // Loop the rotation animation

    // Set up the rotation animation
    _rotationAnimation = Tween<double>(begin: 0, end: 3 * 3.1416).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // Set up the fade animation for the slogan text
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 155,
        height: 150,
        decoration: ShapeDecoration(
          color: widget.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 5),
            // Spinning Image using RotationTransition
            RotationTransition(
              turns: _rotationAnimation,
              child: SizedBox(height: 100, child: Image.asset(widget.imgPath)),
            ),
            const Spacer(),
            // Fading Slogan Text using FadeTransition
            Container(
              width: 155,
              height: 40,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.sloganText,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

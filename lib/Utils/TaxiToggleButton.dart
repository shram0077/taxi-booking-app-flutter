import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Utils/texts.dart';

class TaxiToggleButton extends StatefulWidget {
  final String currentUserId;

  const TaxiToggleButton({super.key, required this.currentUserId});

  @override
  _TaxiToggleButtonState createState() => _TaxiToggleButtonState();
}

class _TaxiToggleButtonState extends State<TaxiToggleButton>
    with WidgetsBindingObserver {
  bool isTaxiOn = false; // Initial state

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setTaxiStatus(true); // Mark driver as active when app opens
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setTaxiStatus(false); // Set to false when app is closed or backgrounded
    } else if (state == AppLifecycleState.resumed) {
      _setTaxiStatus(true); // Set to true when app comes back to foreground
    }
  }

  Future<void> _setTaxiStatus(bool status) async {
    try {
      await taxisRef.doc(widget.currentUserId).update({"isActive": status});
      setState(() {
        isTaxiOn = status;
      });
      try {
        // Update Firestore
        await taxisRef.doc(widget.currentUserId).update({"isActive": isTaxiOn});

        // If the taxi is going online, update its location
        if (isTaxiOn) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          await taxisRef.doc(widget.currentUserId).update({
            "location": {
              "latitude": position.latitude,
              "longitude": position.longitude
            }
          });
        }
      } catch (e) {
        print("Error updating Firestore: $e");
      }
    } catch (e) {
      print("Error updating Firestore: $e");
    }
  }

  void _toggleTaxiMode() {
    String confirmationMessage = isTaxiOn
        ? "Are you sure you want to turn off Taxi Mode?"
        : "Are you sure you want to turn on Taxi Mode?";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: greenColor2,
        title: robotoText("Confirm", taxiYellowColor, 25, FontWeight.bold),
        content:
            robotoText(confirmationMessage, whiteColor, 18, FontWeight.w500),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: robotoText("Cancel", Colors.white70, 14, FontWeight.bold),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _setTaxiStatus(!isTaxiOn);
            },
            child: robotoText("Yes", whiteColor, 14, FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTaxiMode,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(2),
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: isTaxiOn ? Colors.green.withOpacity(0.9) : taxiYellowColor,
            borderRadius: BorderRadius.circular(27.5),
            boxShadow: [
              BoxShadow(
                color: isTaxiOn
                    ? Colors.green.withOpacity(0.6) // Active glow effect
                    : Colors.black.withOpacity(0.1), // Normal shadow
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27.5),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Image.asset(
                isTaxiOn
                    ? "assets/images/taxicap.png" // Taxi mode ON image
                    : "assets/images/turn-off.png", // Normal mode image
                key: ValueKey<bool>(isTaxiOn), // Key to trigger animation
                fit: BoxFit.cover,
                width: 55,
                height: 55,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

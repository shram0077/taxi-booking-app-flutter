import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:url_launcher/url_launcher.dart';

class PassengerInfoCard extends StatefulWidget {
  final String passengerId;
  const PassengerInfoCard({super.key, required this.passengerId});

  @override
  State<PassengerInfoCard> createState() => _PassengerInfoCardState();
}

class _PassengerInfoCardState extends State<PassengerInfoCard> {
  Map<String, dynamic>? passengerData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPassengerData();
  }

  Future<void> _loadPassengerData() async {
    final doc = await usersRef.doc(widget.passengerId).get();
    if (doc.exists) {
      setState(() {
        passengerData = doc.data();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || passengerData == null) {
      return const SizedBox.shrink();
    }
    final phone = passengerData!['phone'] as String?;

    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: passengerData!['profilePicture'] != null
              ? CachedNetworkImageProvider(passengerData!['profilePicture'])
              : null,
          child: passengerData!['profilePicture'] == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(passengerData!['name'] ?? 'Passenger',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        subtitle: Text(phone ?? "No phone number", style: GoogleFonts.lato()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(CupertinoIcons.phone, color: Colors.green),
              onPressed: phone == null
                  ? null
                  : () => launchUrl(Uri(scheme: 'tel', path: phone)),
            ),
            IconButton(
              icon: Icon(CupertinoIcons.chat_bubble_text, color: Colors.blue),
              onPressed: phone == null
                  ? null
                  : () => launchUrl(Uri(scheme: 'sms', path: phone)),
            ),
          ],
        ),
      ),
    );
  }
}

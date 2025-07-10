import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:page_transition/page_transition.dart';
import 'package:restart_app/restart_app.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Screens/Home/home.dart';

class Databaseservices {
  static final _firestore = FirebaseFirestore.instance;

// Generate a unique taxi number based on Firestore data
  static Future<int> _generateUniqueTaxiNumber() async {
    QuerySnapshot snapshot = await _firestore
        .collection('drivers')
        .orderBy('taxiNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      int highestTaxiNumber = snapshot.docs.first['taxiNumber'];
      return highestTaxiNumber + 1;
    } else {
      return 101; // Start from 1001 if no drivers exist
    }
  }
  // Set users data to firstore

  static Future<void> createUser(
    String userId,
    String name,
    String phone,
    String profilePictureUri,
    String email,
    String role,
    context,
  ) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      try {
        await usersRef.doc(userId).set({
          "userId": userId,
          "name": name,
          "phone": phone,
          "email": email,
          "profilePicture": profilePictureUri,
          "currentLocation": GeoPoint(0.0, 0.0),
          "currentCity": '',
          "destination": null, // Update this dynamically during rides
          "walletBalance": 0.0,
          "rideHistory": [],
          "joinedAt": Timestamp.now(),
          'role': role,
          'status': ''
        });
        print("user Acoount created successfully. name is: $name");

        if (role == 'user') {
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.rightToLeft,
              child: HomePage(currentUserId: userId),
            ),
          );
        }

        Restart.restartApp();
      } catch (e) {
        print("Error creating User: $e");
      }
    } else {
      print("User already exists!");
    }
  }

// Set drivers data to firestore
  static Future<void> createtaxiInformation(
    String driverId,
    String name,
    String phone,
    String licensePlate,
    String carModel,
    context,
  ) async {
    DocumentSnapshot userDoc = await taxisRef.doc(driverId).get();

    if (!userDoc.exists) {
      try {
        int taxiNumber = await _generateUniqueTaxiNumber();

        await taxisRef.doc(driverId).set({
          "taxiNumber": taxiNumber,
          "driverId": driverId,
          'phone': phone,
          'licensePlate': licensePlate,
          'carModel': carModel,
          'location': GeoPoint(0.0, 0.0),
          'status': "available",
          'rideHistory': [],
          "isActive": false,
          "joinedAt": Timestamp.now(),
        });

        print("Taxi created successfully with Taxi Number: $taxiNumber");

        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            child: HomePage(currentUserId: driverId),
          ),
        );

        Restart.restartApp();
      } catch (e) {
        print("Error creating driver: $e");
      }
    } else {
      print("Driver already exists!");
    }
  }

  static Future<bool> checkIfPhoneNumberRegistered(String phoneNo) async {
    try {
      // Reference to the Firestore collection
      var usersCollection = FirebaseFirestore.instance.collection('users');

      // Query Firestore to see if the phone number exists
      var querySnapshot =
          await usersCollection.where('phone', isEqualTo: phoneNo).get();

      // If the query snapshot is not empty, the phone number exists
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle error
      print('Error checking phone number: $e');
      return false;
    }
  }

  static Future<String?> getUserTypeByPhone(String phoneNo) async {
    try {
      var driverQuery = await taxisRef.where('phone', isEqualTo: phoneNo).get();

      if (driverQuery.docs.isNotEmpty) {
        return "driver";
      }

      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNo)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return "user";
      }

      return null; // Not found in either collection
    } catch (e) {
      print('Error checking phone number: $e');
      return null;
    }
  }

  static Future updateCurrentAddress(String address, String userId) async {
    await usersRef.doc(userId).update({'currentCity': address});
  }

  static Future updatePosition(
      String userId, String role, double latitude, double longitude) async {
    if (role == "passenger") {
      await usersRef.doc(userId).update({
        'currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    } else if (role == "driver") {
      await usersRef.doc(userId).update({
        'currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
      await taxisRef.doc(userId).update({
        'currentLocation': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'status': 'available'
      });
    }
  }
}

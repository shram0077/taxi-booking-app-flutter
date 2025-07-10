import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/encryption_decryption/encryption.dart';

class UserModel {
  String userid;
  String name;
  String phone;
  String profilePicture;
  String email;
  Timestamp joinedAt;
  String status; // "available", "on-trip", "offline"
  GeoPoint currentLocation;
  String currentCity;
  double walletBalance;
  List rideHistory;
  String role;

  UserModel({
    required this.userid,
    required this.name,
    required this.phone,
    required this.email,
    required this.joinedAt,
    required this.status,
    required this.currentLocation,
    required this.walletBalance,
    required this.rideHistory,
    required this.profilePicture,
    required this.role,
    required this.currentCity,
  });

  // Helper to safely convert dynamic Firestore field to String
  static String _toString(dynamic value) {
    if (value == null) return "";
    if (value is String) return value;
    return value.toString();
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    var locationData = doc["currentLocation"];
    GeoPoint location;

    if (locationData is GeoPoint) {
      location = locationData;
    } else if (locationData is Map<String, dynamic>) {
      location = GeoPoint(
          locationData["latitude"] ?? 0, locationData["longitude"] ?? 0);
    } else {
      location = GeoPoint(0, 0); // Default value
    }

    // Convert and decrypt fields safely:
    String encryptedEmail = _toString(doc["email"]);
    String decryptedEmail =
        MyEncriptionDecription.decryptWithAESKey(encryptedEmail);

    String encryptedWalletBalance = _toString(doc['walletBalance']);
    String decryptedWalletBalance =
        MyEncriptionDecription.decryptWithAESKey(encryptedWalletBalance);
    double walletBalance = _getDoubleFromField(decryptedWalletBalance);

    return UserModel(
      userid: _toString(doc["userId"]),
      name: _toString(doc['name']),
      phone: _toString(doc['phone']),
      email: decryptedEmail,
      profilePicture: _toString(doc["profilePicture"]),
      joinedAt: doc["joinedAt"] as Timestamp,
      status: _toString(doc['status']),
      currentCity: _toString(doc['currentCity']),
      currentLocation: location,
      role: _toString(doc["role"]),
      walletBalance: walletBalance,
      rideHistory: List.from(doc['rideHistory'] ?? []),
    );
  }

  static double _getDoubleFromField(String field) {
    return double.tryParse(field) ?? 0.0;
  }
}

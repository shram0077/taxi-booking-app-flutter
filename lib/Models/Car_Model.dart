import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  String driverId;
  int taxiNumber;
  String phone;
  bool isActive;
  String licensePlate;
  String carModel;
  Timestamp joinedAt;
  String status; // "available", "on-trip", "offline"
  GeoPoint location;
  List rideHistory;
  CarModel({
    required this.driverId,
    required this.taxiNumber,
    required this.phone,
    required this.isActive,
    required this.licensePlate,
    required this.carModel,
    required this.joinedAt,
    required this.status,
    required this.location,
    required this.rideHistory,
  });

  factory CarModel.fromDoc(DocumentSnapshot doc) {
    var locationData = doc["location"];
    GeoPoint location;

    if (locationData is GeoPoint) {
      location = locationData;
    } else if (locationData is Map<String, dynamic>) {
      location = GeoPoint(
          locationData["latitude"] ?? 0, locationData["longitude"] ?? 0);
    } else {
      location = GeoPoint(0, 0); // Default value
    }

    return CarModel(
      driverId: doc['driverId'],
      taxiNumber: doc['taxiNumber'],
      phone: doc['phone'],
      licensePlate: doc['licensePlate'],
      carModel: doc['carModel'],
      joinedAt: doc['joinedAt'],
      status: doc['status'],
      isActive: doc['isActive'],
      location: location,
      rideHistory: doc['rideHistory'] ?? [],
    );
  }
}

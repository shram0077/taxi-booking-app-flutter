import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
// Firestore refs
final usersRef = _firestore.collection('users');
final taxisRef = _firestore.collection('taxis');
final addressRef = _firestore.collection("saved address's");
final spinHistory = _firestore.collection('spinHistory');
final rideRequests = _firestore.collection("rideRequests");
final rideHistory = _firestore.collection("rideHistory");
//Keys

final fileluApiKey = "YOUR API KEY";

final String googleApiKey = 'YOUR GOOGLE API KEY';

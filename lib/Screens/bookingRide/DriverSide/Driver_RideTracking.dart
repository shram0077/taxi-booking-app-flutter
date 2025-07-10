import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Screens/bookingRide/DriverSide/utils/passengerInfo.dart';
import 'package:taxi/Screens/bookingRide/DriverSide/utils/primaryButton.dart';
import 'package:taxi/Screens/bookingRide/DriverSide/utils/rideStatus.dart';

class DriverRideManagementPage extends StatefulWidget {
  final String rideRequestId;

  const DriverRideManagementPage({super.key, required this.rideRequestId});

  @override
  State<DriverRideManagementPage> createState() =>
      _DriverRideManagementPageState();
}

class _DriverRideManagementPageState extends State<DriverRideManagementPage> {
  late final RideController _rideController;
  GoogleMapController? _mapController;
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _rideController = RideController(rideRequestId: widget.rideRequestId);
    _loadCarIcon();
    _rideController.initialize();
  }

  @override
  void dispose() {
    _rideController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCarIcon() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/taxi.png',
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: StreamBuilder<RideState>(
        stream: _rideController.stateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;

          if (state is RideErrorState) {
            return Center(child: Text(state.message));
          }

          if (state is RideLoadedState) {
            return Stack(
              children: [
                _buildRideManagementUI(state),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: _buildBackButton(state),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildBackButton(RideLoadedState? state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.5),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (state?.rideData['status'] == 'cancelled') {
              Navigator.pop(context);
            } else {
              _showExitConfirmationDialog();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRideManagementUI(RideLoadedState state) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(
            target: state.origin,
            zoom: 14.5,
          ),
          markers: _buildMarkers(state),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [state.origin, state.destination],
              color: Colors.blue.withOpacity(0.5),
              width: 5,
            ),
          },
        ),
        Positioned(
          top: 85,
          left: 16,
          right: 16,
          child: _buildETACard(state),
        ),
        RideControlSheet(
          rideData: state.rideData,
          rideId: widget.rideRequestId,
          driverLocation: state.driverLocation,
          destinationLocation: state.destination,
          onComplete: () => Navigator.of(context).pop(),
          controller: _rideController,
        ),
      ],
    );
  }

  Widget _buildETACard(RideLoadedState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "ETA: ${state.eta} min | ${state.distance} km",
        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Set<Marker> _buildMarkers(RideLoadedState state) {
    final markers = <Marker>{};

    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: state.origin,
      infoWindow: const InfoWindow(title: 'Pickup'),
    ));

    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: state.destination,
      infoWindow: const InfoWindow(title: 'Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));

    if (state.driverLocation != null && _carIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: state.driverLocation!,
        icon: _carIcon!,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(state.driverLocation!),
      );
    }

    return markers;
  }

  Future<void> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.exit_to_app, size: 32, color: Colors.orange),
        title: const Text(
          "Leave Current Ride?",
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "You'll need to start a new ride if you exit now. All current ride data will be saved.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Continue Riding",
                style: TextStyle(color: Colors.blue)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("End Ride"),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _rideController.cancelRide();
      if (mounted) Navigator.pop(context);
    }
  }
}

// State Management Classes
abstract class RideState {}

class RideLoadingState extends RideState {}

class RideLoadedState extends RideState {
  final Map<String, dynamic> rideData;
  final LatLng origin;
  final LatLng destination;
  final LatLng? driverLocation;
  final String eta;
  final String distance;

  RideLoadedState({
    required this.rideData,
    required this.origin,
    required this.destination,
    this.driverLocation,
    required this.eta,
    required this.distance,
  });
}

class RideErrorState extends RideState {
  final String message;
  RideErrorState(this.message);
}

class RideController {
  final String rideRequestId;
  final _stateController = StreamController<RideState>.broadcast();
  StreamSubscription<DocumentSnapshot>? _rideSub;
  StreamSubscription<Position>? _locationSub;
  LatLng? _previousDriverLocation;

  RideController({required this.rideRequestId});

  Stream<RideState> get stateStream => _stateController.stream;

  void initialize() {
    _stateController.add(RideLoadingState());
    _listenToRideUpdates();
    _listenToDriverLocation();
  }

  void _listenToRideUpdates() {
    _rideSub = rideRequests.doc(rideRequestId).snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        _stateController.add(RideErrorState("Ride not found"));
        return;
      }

      final data = snapshot.data()!;
      try {
        final origin = LatLng(data['origin']['lat'], data['origin']['lng']);
        final destination =
            LatLng(data['destination']['lat'], data['destination']['lng']);
        final driverLocData = data['driverLocation'];
        final driverLocation = driverLocData != null
            ? LatLng(driverLocData['lat'], driverLocData['lng'])
            : null;

        final distance = driverLocation != null
            ? Geolocator.distanceBetween(
                driverLocation.latitude,
                driverLocation.longitude,
                destination.latitude,
                destination.longitude)
            : 0;

        final eta = (distance / 500).round().clamp(1, 60).toString();
        final distanceKm = (distance / 1000).toStringAsFixed(1);

        _stateController.add(RideLoadedState(
          rideData: data,
          origin: origin,
          destination: destination,
          driverLocation: driverLocation,
          eta: eta,
          distance: distanceKm,
        ));
      } catch (e) {
        _stateController.add(RideErrorState("Error parsing ride data"));
      }
    });
  }

  Future<void> _listenToDriverLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _stateController.add(RideErrorState("Location services disabled"));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _stateController.add(RideErrorState("Location permission denied"));
        return;
      }
    }

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final newLoc = LatLng(position.latitude, position.longitude);
      _previousDriverLocation = newLoc;
      _updateDriverLocation(newLoc);
    });
  }

  Future<void> _updateDriverLocation(LatLng location) async {
    try {
      await rideRequests.doc(rideRequestId).update({
        'driverLocation': GeoPoint(location.latitude, location.longitude),
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> cancelRide() async {
    try {
      await rideRequests.doc(rideRequestId).update({
        'status': 'cancelled',
        'canceled_by': 'driver',
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> completeRide() async {
    try {
      await rideRequests.doc(rideRequestId).update({
        'status': 'completed',
        'completed_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error
    }
  }

  void dispose() {
    _rideSub?.cancel();
    _locationSub?.cancel();
    _stateController.close();
  }
}

class RideControlSheet extends StatelessWidget {
  final Map<String, dynamic> rideData;
  final String rideId;
  final LatLng? driverLocation;
  final LatLng destinationLocation;
  final VoidCallback onComplete;
  final RideController controller;

  const RideControlSheet({
    super.key,
    required this.rideData,
    required this.rideId,
    required this.driverLocation,
    required this.destinationLocation,
    required this.onComplete,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final status = rideData['status'] as String? ?? 'unknown';

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildDragHandle(),
              RideStatusIndicator(status: status),
              const SizedBox(height: 16),
              PassengerInfoCard(passengerId: rideData['passengerId']),
              const SizedBox(height: 24),
              PrimaryActionButton(
                currentStatus: status,
                rideId: rideId,
                driverLocation: driverLocation,
                destinationLocation: destinationLocation,
              ),
              if (status == 'en_route' ||
                  status == 'arrived' ||
                  status == 'accepted')
                _buildCompleteTripButton(),
            ].animate(interval: 100.ms).fadeIn(duration: 400.ms),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCompleteTripButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton(
        onPressed: () async {
          await controller.completeRide();
          onComplete();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Complete Trip",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

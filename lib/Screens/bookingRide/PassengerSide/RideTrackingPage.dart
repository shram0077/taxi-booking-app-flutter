import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:alert_info/alert_info.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/bookingRide/PassengerSide/passengerRatingSheet.dart';
import 'package:taxi/Utils/alerts.dart';
import 'package:taxi/Utils/plateCar.dart';
import 'package:url_launcher/url_launcher.dart';

class PassengerRideTrackingPage extends StatefulWidget {
  final String rideRequestId;
  final String driverId;

  const PassengerRideTrackingPage({
    super.key,
    required this.rideRequestId,
    required this.driverId,
  });

  @override
  State<PassengerRideTrackingPage> createState() =>
      _PassengerRideTrackingPageState();
}

class _PassengerRideTrackingPageState extends State<PassengerRideTrackingPage>
    with SingleTickerProviderStateMixin {
  late final RideTrackingController _controller;
  GoogleMapController? _mapController;
  BitmapDescriptor? _driverIcon;
  late AnimationController _animationController;
  late Animation<double> _bottomSheetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = RideTrackingController(
      rideRequestId: widget.rideRequestId,
      driverId: widget.driverId,
      _handleRideCompleted,
      _handleRideCancelled,
    );
    _initAnimations();
    _loadCustomMarker();
    _controller.initialize();
  }

  void _handleRideCompleted() {
    alertInfo(context, "Your Ride completed", Icons.check, TypeInfo.success);

    Future.delayed(const Duration(milliseconds: 1500), () async {
      // Show rating sheet bottom sheet without popping current page yet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => PassengerRatingSheet(
          driverId: widget.driverId,
          onSubmit: () {
            Navigator.pop(context);
          },
        ),
      );
    });
  }

  void _handleRideCancelled() {
    Navigator.of(context).pop();
    alertInfo(
      context,
      "Your ride was cancelled by you",
      EvaIcons.alertCircle,
      TypeInfo.warning,
    );
  }

  void onSubmit(double rating) {
    debugPrint('Rating submitted: \$rating');
  }

  @override
  void dispose() {
    _controller.dispose();
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bottomSheetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadCustomMarker() async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/icons/taxi.png', 100);
    _driverIcon = BitmapDescriptor.fromBytes(markerIcon);
    setState(() {});
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(),
      ),
      body: StreamBuilder<RideTrackingState>(
        stream: _controller.stateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;
          if (state is RideTrackingErrorState) {
            return Center(child: Text(state.message));
          } else if (state is RideTrackingLoadedState) {
            if (!_animationController.isAnimating &&
                _animationController.status != AnimationStatus.completed) {
              _animationController.forward();
            }
            return _buildTrackingUI(state);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.5),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _showExitConfirmationDialog(),
        ),
      ),
    );
  }

  Widget _buildTrackingUI(RideTrackingLoadedState state) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.originLocation,
            zoom: 14.5,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: _buildMarkers(state),
          polylines: _buildPolylines(state),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        if (state.estimatedMinutes != null && state.estimatedDistance != null)
          _buildETABadge(state),
        _buildDriverBottomSheet(state),
      ],
    );
  }

  Widget _buildETABadge(RideTrackingLoadedState state) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "ETA: ${state.estimatedMinutes!.toStringAsFixed(0)} min | "
          "${state.estimatedDistance!.toStringAsFixed(1)} km",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(RideTrackingLoadedState state) {
    final markers = <Marker>{};

    if (state.driverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: state.driverLocation!,
        icon: _driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    }

    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: state.originLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Pickup Location'),
    ));

    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: state.destinationLocation,
      infoWindow: const InfoWindow(title: 'Destination'),
    ));

    return markers;
  }

  Set<Polyline> _buildPolylines(RideTrackingLoadedState state) {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          state.driverLocation ?? state.originLocation,
          state.originLocation
        ],
        color: Colors.blue.withOpacity(0.8),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Widget _buildDriverBottomSheet(RideTrackingLoadedState state) {
    return FadeTransition(
      opacity: _bottomSheetAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_bottomSheetAnimation),
        child: DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.35,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15), blurRadius: 20)
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDragHandle(),
                  _buildStatusHeader(state),
                  const SizedBox(height: 16),
                  _buildDriverInfo(state),
                  const Divider(height: 32),
                  _buildCarInfo(state),
                  const SizedBox(height: 24),
                  _buildActionButtons(state),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(RideTrackingLoadedState state) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _getStatusColor(state.rideStatus),
      ),
      child: Text(
        state.rideStatus[0].toUpperCase() + state.rideStatus.substring(1),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'paused':
        return Colors.orange;
      case 'traffic':
        return Colors.amber;
      case 'long_way':
        return Colors.deepOrange;
      default:
        return Colors.black;
    }
  }

  Widget _buildDriverInfo(RideTrackingLoadedState state) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(state.driverData['photoUrl'] ?? ''),
        radius: 28,
      ),
      title: Text(
        state.driverData['name'] ?? 'Driver',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        state.driverData['rating'] != null
            ? '⭐ ${state.driverData['rating'].toStringAsFixed(1)}'
            : 'N/A',
        style: GoogleFonts.poppins(),
      ),
    );
  }

  Widget _buildCarInfo(RideTrackingLoadedState state) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.directions_car, size: 28),
          title: Text("Car", style: GoogleFonts.poppins(fontSize: 16)),
          subtitle: Text(
            state.carData["carModel"] ?? "Car information not available",
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone, size: 28),
          title: Text("Driver Phone", style: GoogleFonts.poppins(fontSize: 16)),
          subtitle: Text(
            state.driverData['phone']?.toString() ?? 'Not available',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        if (state.carData['licensePlate'] != null)
          customLicensePlateTile(state.carData['licensePlate'], false)
      ],
    );
  }

  Widget _buildActionButtons(RideTrackingLoadedState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.call,
          label: 'Call',
          color: Colors.blue,
          onPressed: () => _controller.callDriver(),
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'Message',
          onPressed: () => _controller.messageDriver(),
        ),
        _buildActionButton(
          icon: Icons.cancel,
          label: 'Cancel',
          color: Colors.red,
          onPressed: () => _controller.cancelRide(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          color: color,
          onPressed: onPressed,
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      ],
    );
  }

  Future<void> _showExitConfirmationDialog() async {
    final shouldExit = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            title: Column(
              children: [
                const Icon(Icons.exit_to_app, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  "Leave Ride Tracking?",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Text(
              "You're currently tracking your ride. Are you sure you want to leave?",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              // Stay Button
              TextButton(
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: primaryColor),
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "STAY",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              // Leave Button
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "LEAVE",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldExit == true) {
      // Add a little delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        await _controller.cancelRide();
        Navigator.of(context).pop();
      }
    }
  }
}

// State Management Classes
abstract class RideTrackingState {}

class RideTrackingLoadingState extends RideTrackingState {}

class RideTrackingLoadedState extends RideTrackingState {
  final Map<String, dynamic> rideData;
  final Map<String, dynamic> driverData;
  final Map<String, dynamic> carData;
  final LatLng originLocation;
  final LatLng destinationLocation;
  final LatLng? driverLocation;
  final String rideStatus;
  final double? estimatedMinutes;
  final double? estimatedDistance;

  RideTrackingLoadedState({
    required this.rideData,
    required this.driverData,
    required this.carData,
    required this.originLocation,
    required this.destinationLocation,
    this.driverLocation,
    required this.rideStatus,
    this.estimatedMinutes,
    this.estimatedDistance,
  });
}

class RideTrackingErrorState extends RideTrackingState {
  final String message;
  RideTrackingErrorState(this.message);
}

class RideTrackingController {
  final String rideRequestId;
  final String driverId;
  final VoidCallback? onRideCompleted;
  final VoidCallback? onRideCancelled;
  final _stateController = StreamController<RideTrackingState>.broadcast();

  // Store the latest snapshots
  DocumentSnapshot? _latestRideSnapshot;
  DocumentSnapshot? _latestDriverSnapshot;
  DocumentSnapshot? _latestCarSnapshot;

  StreamSubscription<DocumentSnapshot>? _rideSubscription;
  StreamSubscription<DocumentSnapshot>? _driverSubscription;
  StreamSubscription<DocumentSnapshot>? _carSubscription;

  bool _hasShownRating = false;

  RideTrackingController(
    this.onRideCompleted,
    this.onRideCancelled, {
    required this.rideRequestId,
    required this.driverId,
  });

  Stream<RideTrackingState> get stateStream => _stateController.stream;

  void initialize() {
    _stateController.add(RideTrackingLoadingState());
    _listenToRideUpdates();
    _listenToDriverUpdates();
    _listenToCarUpdates();
  }

  void _listenToRideUpdates() {
    _rideSubscription = FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(rideRequestId)
        .snapshots()
        .listen((snapshot) {
      _latestRideSnapshot = snapshot; // Store the latest snapshot
      if (!snapshot.exists) {
        _stateController.add(RideTrackingErrorState("Ride not found"));
        return;
      }
      _processRideUpdate();
    }, onError: (error) {
      _stateController.add(RideTrackingErrorState("Error loading ride data"));
    });
  }

  void _listenToDriverUpdates() {
    _driverSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      _latestDriverSnapshot = snapshot;
      _processRideUpdate();
    }, onError: (error) {
      _stateController.add(RideTrackingErrorState("Error loading driver info"));
    });
  }

  void _listenToCarUpdates() {
    _carSubscription = FirebaseFirestore.instance
        .collection('taxis')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      _latestCarSnapshot = snapshot;
      _processRideUpdate();
    }, onError: (error) {
      _stateController.add(RideTrackingErrorState("Error loading car info"));
    });
  }

  void _processRideUpdate() {
    // Only process if we have all required data
    if (_latestRideSnapshot == null ||
        _latestDriverSnapshot == null ||
        _latestCarSnapshot == null) {
      return;
    }

    try {
      final rideData = _latestRideSnapshot!.data() as Map<String, dynamic>?;
      final driverData = _latestDriverSnapshot!.data() as Map<String, dynamic>?;
      final carData = _latestCarSnapshot!.data() as Map<String, dynamic>?;

      if (rideData == null || driverData == null || carData == null) {
        _stateController.add(RideTrackingErrorState("Data format error"));
        return;
      }

      final origin = LatLng(
        rideData['origin']['lat'],
        rideData['origin']['lng'],
      );
      final destination = LatLng(
        rideData['destination']['lat'],
        rideData['destination']['lng'],
      );
      final driverLoc = rideData['driverLocation'] != null
          ? LatLng(
              rideData['driverLocation']['lat'],
              rideData['driverLocation']['lng'],
            )
          : null;

      final status = rideData['status'] as String? ?? 'unknown';

      // Calculate ETA and distance
      double? distance;
      double? minutes;
      if (driverLoc != null) {
        distance = _calculateDistance(
          driverLoc.latitude,
          driverLoc.longitude,
          origin.latitude,
          origin.longitude,
        );
        const averageSpeed = 400; // meters per minute
        minutes = distance / averageSpeed;
      }

      _stateController.add(RideTrackingLoadedState(
        rideData: rideData,
        driverData: driverData,
        carData: carData,
        originLocation: origin,
        destinationLocation: destination,
        driverLocation: driverLoc,
        rideStatus: status,
        estimatedMinutes: minutes,
        estimatedDistance: distance != null ? distance / 1000 : null,
      ));

      // Handle ride completion
      if (status == 'completed' && !_hasShownRating) {
        _hasShownRating = true;
        if (onRideCompleted != null) {
          onRideCompleted!();
        }
      }

      // Handle cancellation
      if (status == 'cancelled') {
        if (onRideCancelled != null) {
          onRideCancelled!();
        }
      }
    } catch (e) {
      _stateController
          .add(RideTrackingErrorState("Error processing ride data: $e"));
    }
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * 1000 * asin(sqrt(a));
  }

  Future<void> callDriver() async {
    if (_latestDriverSnapshot == null) return;

    final phone = _latestDriverSnapshot!.get('phone');
    if (phone == null) return;

    final Uri launchUri = Uri(scheme: 'tel', path: phone.toString());
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> messageDriver() async {
    // Implement messaging functionality
    // Could use _latestDriverSnapshot to get contact info
  }

  Future<void> cancelRide() async {
    try {
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(rideRequestId)
          .update({
        'status': 'cancelled',
        'canceled_by': 'passenger',
      });
    } catch (e) {
      _stateController.add(RideTrackingErrorState("Failed to cancel ride"));
    }
  }

  void dispose() {
    _rideSubscription?.cancel();
    _driverSubscription?.cancel();
    _carSubscription?.cancel();
    _stateController.close();
  }
}

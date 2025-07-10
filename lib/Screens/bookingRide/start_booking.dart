import 'dart:async';
import 'dart:math';
import 'dart:ui'; // ✅ Needed for ImageFilter

import 'package:alert_info/alert_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/bookingRide/logic/logics.dart';
import 'package:taxi/Screens/bookingRide/utils/booking_sheet.dart/booking_sheet.dart'
    hide greenColor;
import 'package:taxi/Screens/bookingRide/utils/taxi_sheet.dart';
import 'package:taxi/Services/DatabaseServices.dart';
import 'package:taxi/Utils/TaxiToggleButton.dart';
import 'package:taxi/Utils/alerts.dart';
import 'package:taxi/Utils/Loadings/locationLoading.dart';
import 'package:taxi/Utils/texts.dart';
import 'package:audioplayers/audioplayers.dart';

// Enum to manage booking panel state
enum BookingStage {
  search,
  confirmDestination,
  rideBooked,
}

class StartBooking extends StatefulWidget {
  final String currentUserId;
  final UserModel userModel;
  const StartBooking(
      {super.key, required this.currentUserId, required this.userModel});

  @override
  State<StartBooking> createState() => _StartBookingState();
}

class _StartBookingState extends State<StartBooking> {
  double _calculateDistanceInKm(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _calculateSuggestedFare(double distanceInKm) {
    // Base fare + (distance rate * distance) with 30% increase
    const double baseFare = 1.95; // 1.50 + 30% (1.50 * 1.3)
    const double perKmRate = 0.26; // 0.20 + 30% (0.20 * 1.3)
    const double minFare = 2.60; // 2.00 + 30% (2.00 * 1.3)

    // Get current time for peak hour calculation
    final now = DateTime.now();
    final isPeakHours =
        (now.hour >= 7 && now.hour <= 9) || (now.hour >= 16 && now.hour <= 19);
    const double peakMultiplier =
        1.2; // Reduced from 1.5 to compensate for base increase

    // Calculate base fare
    double fare = baseFare + (perKmRate * distanceInKm);

    // Apply peak hour multiplier if needed
    fare = isPeakHours ? fare * peakMultiplier : fare;

    // Ensure minimum fare
    return max(fare, minFare);
  }

  double _degToRad(double deg) => deg * (pi / 180);
  GoogleMapController? _mapController;
  StreamSubscription<QuerySnapshot>? _taxiStreamSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;

  // State Variables
  LatLng? _currentPosition;
  String? _currentAddress;
  LatLng? _destinationPosition;
  String? _destinationAddress;
  final Set<Marker> _markers = {};
  BitmapDescriptor _userLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _taxiIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _destinationIcon = BitmapDescriptor.defaultMarker;
  BookingStage _currentStage = BookingStage.search;
  final TextEditingController _destinationController = TextEditingController();
  bool _isDisposed = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AudioCache _audioCache; // For pre-caching sounds

  @override
  void initState() {
    super.initState();
    _audioCache = AudioCache(prefix: 'assets/sounds/');
    _initializeAsync();
    _loadInitialData(); // Other data loads

    if (widget.userModel.role == 'driver') {
      _setDriverActiveStatus(true);
    }
  }

  void _initDriverLocationAndStartListening() async {
    try {
      // Convert to LatLng

      listenForRideRequests(
        widget.currentUserId,
        context,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _playSound,
      );
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e, s) {
      print("Error playing sound '$assetPath': $e\n$s");
    }
  }

  Future<void> _initializeAsync() async {
    try {
      await _audioCache.loadAll(
          ['confirmation.mp3', 'software-interface-start.mp3', 'reject.mp3']);
    } catch (e) {
      print("Error preloading sounds: $e");
    }
  }

  @override
  void dispose() {
    _taxiStreamSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    _mapController = null;
    _destinationController.dispose();
    _isDisposed = true;
    _audioPlayer.dispose();

    _setDriverActiveStatus(false); // Mark driver as inactive on exit

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _setCustomMarkerIcons(),
      ]);

      await _fetchInitialPosition();

      _startLiveUserLocationTracking();
      _fetchTaxiLocations();
    } catch (e) {
      debugPrint('[_loadInitialData] $e');
    }
  }

  bool isDark = false;
  Future<void> loadMapStyle(GoogleMapController controller) async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('mapTheme') ?? 'light';

    final path =
        theme == 'dark' ? 'mapstyle/dark_map.json' : 'mapstyle/light_map.json';
    if (theme == 'dark') {
      setState(() {
        isDark = true;
      });
    } else if (theme == 'light') {
      setState(() {
        isDark = false;
      });
    }
    try {
      print('Loading map style from asset: $path');
      final styleJson = await rootBundle.loadString(path);
      await controller.setMapStyle(styleJson);
    } catch (e) {
      print('Failed to load map style: $e');
      await controller.setMapStyle(null); // fallback to default style
    }
  }

  Future<void> _fetchInitialPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
      if (_isDisposed) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateMarkers();
        _initDriverLocationAndStartListening();
      });

      _animateCameraToPosition(_currentPosition!);

      _currentAddress = await _getAddressFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);
      if (_isDisposed) return;

      setState(() {});
    } catch (e) {
      alertInfo(context, 'Failed to get current location', Icons.location_city,
          TypeInfo.error);
    }
  }

  void _startLiveUserLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (_isDisposed || position == null) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateMarkers();
      });

      // Update user's location in Firestore
      Databaseservices.updatePosition(widget.currentUserId,
          widget.userModel.role, position.latitude, position.longitude);
    });
  }

  void _fetchTaxiLocations() {
    // 🚫 If the user is a driver, don't show other users or taxis
    if (widget.userModel.role == "driver") return;

    _taxiStreamSubscription = taxisRef
        .where("isActive", isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (_isDisposed || _currentPosition == null) return;

      // Remove existing taxi markers
      _markers
          .removeWhere((marker) => marker.markerId.value.startsWith('taxi_'));

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('currentLocation')) {
          double lat = data['currentLocation']['latitude'];
          double lng = data['currentLocation']['longitude'];

          double distanceInKm = _calculateDistanceInKm(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );

          // Only show taxis within 5 km
          if (distanceInKm <= 5) {
            _markers.add(
              Marker(
                markerId: MarkerId("taxi_${doc.id}"),
                position: LatLng(lat, lng),
                icon: _taxiIcon,
                anchor: const Offset(0.5, 0.5),
                onTap: () => _showTaxiInfoSheet(doc.id),
              ),
            );
          }
        }
      }

      setState(() {});
    }, onError: (e) {
      print('Taxi stream error: $e');
    });
  }

  // --- UI State Management & Animations ---

  void _selectDestinationOnMap(LatLng tappedPosition) async {
    _destinationPosition = tappedPosition;
    _destinationAddress = await _getAddressFromCoordinates(
        tappedPosition.latitude, tappedPosition.longitude);
    _destinationController.text = _destinationAddress ?? "Selected Location";

    if (_isDisposed) return;

    setState(() {
      _currentStage = BookingStage.confirmDestination;
      _updateMarkers();
    });

    _animateCameraToPosition(_destinationPosition!, zoom: 16);
  }

  void _resetBooking() {
    if (_isDisposed) return;

    setState(() {
      _destinationPosition = null;
      _destinationAddress = null;
      _destinationController.clear();
      _currentStage = BookingStage.search;
      _updateMarkers();
    });
  }

  Future<void> _setDriverActiveStatus(bool status) async {
    try {
      await taxisRef.doc(widget.userModel.userid).update({"isActive": status});

      if (status) {
// Optionally update the driver's location when active
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await taxisRef.doc(widget.userModel.userid).update({
          "location": {
            "latitude": position.latitude,
            "longitude": position.longitude,
          }
        });
      }
    } catch (e) {
      print("Error updating driver active status: $e");
    }
  }

  // --- UI Widgets ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDark ? Color(0xFF013220) : whiteColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: isDark ? darkGreen : whiteColor,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new,
                    color: isDark ? whiteColor : taxiDarkText, size: 20),
              ),
            ),
          ),
        ),
        body: _currentPosition == null
            ? LocationLoading(title: "Finding you on the map...")
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 15,
                      tilt: widget.userModel.role == 'driver' ? 60 : 0,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      loadMapStyle(controller);
                    },
                    onTap: widget.userModel.role == 'driver'
                        ? null
                        : _selectDestinationOnMap,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                  ),
                  if (widget.userModel.role == 'driver')
                    Positioned(
                      top: 80,
                      right: 16, // Positioning to bottom-right
                      child: TaxiToggleButton(
                        currentUserId: widget.userModel.userid,
                      ),
                    ),
                  widget.userModel.role == 'driver'
                      ? Positioned(
                          bottom: 80,
                          right: 16,
                          child: FloatingActionButton(
                            onPressed: () =>
                                _animateCameraToPosition(_currentPosition!),
                            backgroundColor: whiteColor,
                            child: Icon(Icons.my_location, color: taxiDarkText),
                          ),
                        )
                      : Positioned(
                          top: 80,
                          right: 16,
                          child: FloatingActionButton(
                            onPressed: () =>
                                _animateCameraToPosition(_currentPosition!),
                            backgroundColor: isDark ? darkGreen : whiteColor,
                            child: Icon(Icons.my_location,
                                color: isDark ? whiteColor : taxiDarkText),
                          ),
                        ),
                  if (widget.userModel.role != 'driver') _buildBookingPanel(),
                ],
              ));
  }

  Widget _buildBookingPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        height: _currentStage == BookingStage.search ? 160 : 220,
        decoration: BoxDecoration(
          color: isDark ? darkGreen : whiteColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentStage == BookingStage.search
              ? _buildSearchInputView()
              : _buildRideConfirmationView(),
        ),
      ),
    );
  }

  Widget _buildSearchInputView() {
    return Column(
      key: const ValueKey('searchView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        robotoText("Hello, ${widget.userModel.name}!",
            isDark ? Colors.grey : blackColor, 18, FontWeight.bold),
        const SizedBox(height: 12),
        _buildLocationField(
            icon: Icons.circle_outlined,
            text: _currentAddress ?? "Your current location",
            color: Colors.blue),
        const Divider(),
        _buildLocationField(
            icon: CupertinoIcons.map_pin_ellipse,
            isDestination: true,
            hint: "Where to?",
            controller: _destinationController,
            color: taxiYellowColor),
      ],
    );
  }

  Widget _buildRideConfirmationView() {
    return Column(
      key: const ValueKey('confirmView'),
      children: [
        _buildLocationField(
            icon: Icons.circle_outlined,
            text: _currentAddress ?? "Your current location",
            color: Colors.blue),
        const Divider(),
        _buildLocationField(
            icon: CupertinoIcons.map_pin_ellipse,
            text: _destinationAddress ?? "Selected destination",
            color: taxiYellowColor),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetBooking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: robotoText(
                    "Cancel", Colors.red.shade700, 16, FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_destinationPosition == null) {
                    alertInfo(context, "Please select a destination first.",
                        Icons.pin, TypeInfo.warning);

                    return;
                  }

                  final nearestTaxiDoc = await _findNearestTaxi();

                  if (nearestTaxiDoc == null) {
                    alertInfo(context, "No taxis available nearby.",
                        Icons.taxi_alert, TypeInfo.info);

                    return;
                  }

                  _showTaxiInfoSheet(nearestTaxiDoc.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.lightGreen : greenColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: robotoText("Find Taxi", whiteColor, 16, FontWeight.bold),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildLocationField({
    required IconData icon,
    required Color color,
    String? text,
    String? hint,
    bool isDestination = false,
    TextEditingController? controller,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: isDestination
              ? TextField(
                  controller: controller,
                  onSubmitted: _searchDestinationByName,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                        fontSize: 16),
                  ),
                  style: TextStyle(
                      color: isDark ? whiteColor : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                )
              : Text(
                  text ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isDark ? Colors.grey : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
        ),
      ],
    );
  }

  void _updateMarkers() {
    // Remove only currentLocation and destination markers, keep taxis untouched here to avoid flicker
    _markers.removeWhere((m) =>
        m.markerId.value == 'currentLocation' ||
        m.markerId.value == 'destination');

    if (_currentPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: _currentPosition!,
        icon: _userLocationIcon,
      ));
    }
    if (_destinationPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId("destination"),
        position: _destinationPosition!,
        icon: _destinationIcon,
      ));
    }
  }

  void _animateCameraToPosition(LatLng position, {double zoom = 15.5}) {
    if (mounted && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: zoom,
            tilt: widget.userModel.role == 'driver' ? 60 : 0,
          ),
        ),
      );
    }
  }

  Future<void> _searchDestinationByName(String placeName) async {
    if (placeName.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _selectDestinationOnMap(LatLng(location.latitude, location.longitude));
      } else {
        alertInfo(context, "Location not found.", Icons.location_city,
            TypeInfo.warning);
      }
    } catch (e) {
      print("Could'nt finding location: $e");
      alertInfo(context, "Could not finding location", Icons.location_city,
          TypeInfo.error);
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street ?? ''}, ${place.locality ?? place.name ?? ''}"
            .trim();
      }
      return 'Unknown Location';
    } catch (e) {
      print('Error getting address: $e');
      return 'Could not get address';
    }
  }

  Future<void> _setCustomMarkerIcons() async {
    try {
      _userLocationIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, "assets/icons/placeholder.png");
      _destinationIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, "assets/icons/pin.png");
      _taxiIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration.empty, "assets/icons/taxi.png");
      if (!_isDisposed) setState(() {});
    } catch (e) {
      print('Error loading custom marker icons: $e');
    }
  }

  void _showTaxiInfoSheet(String taxiId) async {
    if (_isDisposed || _currentPosition == null) return;

    try {
      final doc = await taxisRef.doc(taxiId).get();
      final data = doc.data();

      if (data == null || !data.containsKey('currentLocation')) {
        alertInfo(context, "Taxi location unavailable.", Icons.directions,
            TypeInfo.error);

        return;
      }

      final taxiLat = data['currentLocation']['latitude'];
      final taxiLng = data['currentLocation']['longitude'];

      final distance = _calculateDistanceInKm(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        taxiLat,
        taxiLng,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        barrierColor: Colors.black.withOpacity(0.3),
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? darkGreen : whiteColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: TaxiInfoSheet(
                  isDark: isDark,
                  onBookPressed: () async {
                    Navigator.pop(context);

                    if (_destinationPosition == null) {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BookingSheet(
                          isDark: isDark,
                          userModel: widget.userModel,
                          taxiId: taxiId,
                          driverName: data['name'] ?? 'Driver',
                          carModel: data['carModel'] ?? 'Car',
                          onBookingConfirmed: (address, position) {
                            setState(() {
                              _destinationAddress = address;
                              _destinationPosition = position;
                              _destinationController.text = address;
                              _currentStage = BookingStage.confirmDestination;
                              _updateMarkers();
                            });
                          },
                        ),
                      );
                    } else {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          backgroundColor: isDark ? darkGreen : whiteColor,
                          title: Text(
                            "Confirm Ride Booking",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? secondaryColor : darkTextColor,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "You're about to book a ride to:",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[350]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: isDark
                                            ? Colors.lightGreen
                                            : primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _destinationAddress!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red[600],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                "CANCEL",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark ? Colors.lightGreen : primaryColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                "CONFIRM BOOKING",
                                style: GoogleFonts.poppins(
                                  color: whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await _sendRideRequest();

                        if (!mounted) return;

                        setState(() => _currentStage = BookingStage.rideBooked);
                      }
                    }
                  },
                  destinationAddress: _destinationAddress ?? '',
                  taxiId: taxiId,
                  fromNearest: false,
                  scrollController: scrollController,
                  distanceInKm: distance,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      alertInfo(
          context, "Failed to load taxi info.", Icons.error, TypeInfo.error);
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _findNearestTaxi() async {
    try {
      final querySnapshot = await taxisRef
          .where("isActive", isEqualTo: true)
          .where("status", isEqualTo: "available")
          .limit(10)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("[_findNearestTaxi] No active/available taxis found.");
        return null;
      }

      if (_currentPosition == null) {
        debugPrint(
            "[_findNearestTaxi] Current user location is not available.");
        return null;
      }

      DocumentSnapshot<Map<String, dynamic>>? nearestTaxi;
      double shortestDistance = double.infinity;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data == null || !data.containsKey("currentLocation")) continue;

        final location = data["currentLocation"];
        final double? lat = location["latitude"];
        final double? lng = location["longitude"];
        if (lat == null || lng == null) continue;

        final distance = _calculateDistanceInKm(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        // ✅ Skip taxis farther than 10 km
        if (distance > 10.0) continue;

        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestTaxi = doc;
        }
      }

      if (nearestTaxi != null) {
        debugPrint(
            "[_findNearestTaxi] Nearest taxi found: ${nearestTaxi.id}, distance: ${shortestDistance.toStringAsFixed(2)} km");
      } else {
        debugPrint("[_findNearestTaxi] No nearby taxi found within 10 km.");
      }

      return nearestTaxi;
    } catch (e, stack) {
      debugPrint("[_findNearestTaxi] Error: $e\n$stack");
      return null;
    }
  }

  Future<void> _sendRideRequest() async {
    if (_currentPosition == null || _destinationPosition == null) return;

    // Calculate distance and suggested fare
    final distance = _calculateDistanceInKm(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );

    final suggestedFare = _calculateSuggestedFare(distance);

    // Show fare dialog before sending request
    if (!mounted) return;

    showFareInputDialog(context, suggestedFare, (finalFare) async {
      final nearestTaxiDoc = await _findNearestTaxi();

      if (nearestTaxiDoc == null) {
        alertInfo(context, "No taxis available nearby.", CupertinoIcons.car,
            TypeInfo.warning);
        return;
      }

      final taxiId = nearestTaxiDoc.id;

      // Check if passenger can send request to this driver
      final canSend =
          await canSendRideRequestToDriver(taxiId, widget.currentUserId);
      if (!canSend) {
        alertInfo(
            context,
            "You have reached the maximum number of ride requests to this driver in the last hour.",
            CupertinoIcons.time,
            TypeInfo.warning);
        return;
      }

      final requestRef = rideRequests.doc();
      final requestId = requestRef.id;
      final requestData = {
        'requestId': requestId,
        'passengerId': widget.currentUserId,
        'passengerName': widget.userModel.name,
        'passengerImage': widget.userModel.profilePicture,
        'origin': {
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
          'address': _currentAddress ?? '',
        },
        'destination': {
          'lat': _destinationPosition!.latitude,
          'lng': _destinationPosition!.longitude,
          'address': _destinationAddress ?? '',
        },
        'driverLocation': {
          'lat': 0.0,
          'lng': 0.0,
        },
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'driverId': taxiId,
        'canceled_by': '',
        'fare': finalFare, // Add the fare to the request
        'distance': distance, // Add distance for reference
      };

      try {
        await requestRef.set(requestData);
        monitorRideRequest(
            requestId, widget.userModel.role, context, _playSound, requestData);
        alertInfo(
          context,
          "Ride request sent. Waiting for a driver to accept your booking.",
          CupertinoIcons.person_crop_circle_badge_checkmark,
          TypeInfo.success,
        );
      } catch (e) {
        print("Error sending ride request: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to send ride request.")),
          );
        }
      }
    });
  }

  void showFareInputDialog(BuildContext context, double suggestedFare,
      Function(double) onFareConfirmed) {
    final TextEditingController fareController = TextEditingController(
        text: suggestedFare.toStringAsFixed(0)); // No decimals for IQD

    // Suggested fare options (in IQD)
    final suggestedFares = [
      suggestedFare * 0.9, // 20% less than suggested
      suggestedFare, // Exactly suggested
      suggestedFare * 0.8, // 20% more than suggested
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetAnimationCurve: Curves.fastOutSlowIn,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated icon
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.price_change,
                        size: 48,
                        color: Colors.amber,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title with smooth fade
                  FadeTransition(
                    opacity: animation,
                    child: Text(
                      'Set Trip Fare',
                      style: GoogleFonts.tajawal(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fare input with Iraqi dinar symbol
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'IQD',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: taxiDarkText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: fareController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.tajawal(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter amount',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Suggested fares chips
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: suggestedFares.map((fare) {
                        return InputChip(
                          label: Text(
                            'IQD ${fare.toStringAsFixed(0)}',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          selectedColor: primaryColor,
                          onSelected: (selected) {
                            fareController.text = fare.toStringAsFixed(0);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Help text
                  FadeTransition(
                    opacity: animation,
                    child: Text(
                      "This is the amount you're willing to pay.\nNearby drivers will see it before accepting.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons with ripple effect
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final entered =
                                double.tryParse(fareController.text);
                            if (entered != null && entered > 0) {
                              Navigator.pop(context);
                              onFareConfirmed(entered);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter a valid amount',
                                    style: GoogleFonts.tajawal(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:alert_info/alert_info.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Constant/firesbase.dart';
import 'package:taxi/Models/UserModel.dart';
import 'package:taxi/Screens/bookingRide/logic/logics.dart';
import 'package:taxi/Utils/alerts.dart';

const Color greenColor = Color(0xFF27AE60);

class BookingSheet extends StatefulWidget {
  final String taxiId;
  final String driverName;
  final String carModel;
  final UserModel userModel;
  final bool isDark;
  final Function(String address, LatLng position) onBookingConfirmed;

  const BookingSheet({
    super.key,
    required this.taxiId,
    required this.driverName,
    required this.carModel,
    required this.onBookingConfirmed,
    required this.userModel,
    required this.isDark,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();

  bool _isSubmitting = false;
  LatLng? _destinationPosition;
  GoogleMapController? _mapController;

  bool _isSearching = false;
  bool _showClearButton = false;
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];

  Position? _currentPosition;
  bool _isReverseGeocoding = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AudioCache _audioCache; // For pre-caching sounds
  StreamSubscription<DocumentSnapshot>? _rideRequestSubscription;

  double _calculatedFare = 0.0;
  double _distanceInKm = 0.0;
  bool _showFareEstimate = false;
  // Fare calculation algorithm
  double _calculateFare(double distanceInKm) {
    // Base fare + (distance rate * distance)
    const double baseFare = 2.50; // Minimum fare
    const double perKmRate = 1.20; // Rate per kilometer
    const double minFare = 5.00; // Minimum fare regardless of distance

    // Get current time for peak hour calculation
    final now = DateTime.now();
    final isPeakHours =
        (now.hour >= 7 && now.hour <= 9) || (now.hour >= 16 && now.hour <= 19);
    const double peakMultiplier = 1.5;

    // Calculate base fare
    double fare = baseFare + (perKmRate * distanceInKm);

    // Apply peak hour multiplier if needed
    fare = isPeakHours ? fare * peakMultiplier : fare;

    // Ensure minimum fare
    return max(fare, minFare);
  }

  void _updateFareEstimate() {
    if (_currentPosition == null || _destinationPosition == null) {
      setState(() => _showFareEstimate = false);
      return;
    }

    // Calculate distance in kilometers
    _distanceInKm = _calculateDistanceInKm(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );

    // Calculate fare
    _calculatedFare = _calculateFare(_distanceInKm);

    setState(() => _showFareEstimate = true);
  }

  // Helper method to calculate distance between two points
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

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  void initState() {
    super.initState();
    _audioCache = AudioCache(prefix: 'assets/sounds/');
    _initializeAsync();
    _destinationController.addListener(() {
      final hasText = _destinationController.text.isNotEmpty;
      if (_showClearButton != hasText) {
        setState(() {
          _showClearButton = hasText;
        });
      }
    });
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // MODIFICATION: Added a print statement for debugging location.
      print('Current location obtained: $_currentPosition');
    } catch (e) {
      _showErrorSnackBar(
          'Failed to get your current location. Please enable location services.');
      print('Error getting current location: $e');
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

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e, s) {
      print("Error playing sound '$assetPath': $e\n$s");
    }
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
    _rideRequestSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchDestination(query);
      }
    });
  }

  Future<void> _searchDestination(String query) async {
    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    final searchQuery = '$query Kurdistan';
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$searchQuery&format=json&limit=20&countrycodes=iq',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'TaxiApp/1.0 (contact@yourapp.com)',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        // Filter results to be within a reasonable distance (e.g., 100km)
        const maxDistanceMeters = 100000;
        _searchResults = data.map<Map<String, dynamic>>((e) {
          double lat = e['lat'] is String ? double.parse(e['lat']) : e['lat'];
          double lon = e['lon'] is String ? double.parse(e['lon']) : e['lon'];
          return {
            'display_name': e['display_name'],
            'lat': lat,
            'lon': lon,
          };
        }).where((place) {
          if (_currentPosition == null) return true; // Show all if no location
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            place['lat'],
            place['lon'],
          );
          return distance <= maxDistanceMeters;
        }).toList();
      } else {
        _showErrorSnackBar(
            'Failed to load search results (code ${response.statusCode}).');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load search results.');
      print('Exception in _searchDestination: $e');
    }

    setState(() => _isSearching = false);
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isReverseGeocoding = true);
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [place.street, place.locality, place.administrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
    } finally {
      setState(() => _isReverseGeocoding = false);
    }
    return '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
  }

  void _clearDestination() {
    _destinationController.clear();
    setState(() {
      _destinationPosition = null;
      _searchResults.clear();
      _showFareEstimate = false;
    });
  }

  // Update the submit booking method to include fare
  Future<void> _submitBooking() async {
    FocusScope.of(context).unfocus();

    if (_currentPosition == null) {
      _showErrorSnackBar(
          "Could not determine your location. Please try again.");
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Please select a valid destination before booking.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final oneHourAgo =
          Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1)));
      final recentRequests = await rideRequests
          .where('passengerId', isEqualTo: widget.userModel.userid)
          .where('driverId', isEqualTo: widget.taxiId)
          .where('requestedAt', isGreaterThan: oneHourAgo)
          .get();

      if (recentRequests.docs.length >= 3) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar(
            "You've reached the 3-request limit to this driver within the past hour.");
        return;
      }

      final requestData = {
        'passengerId': widget.userModel.userid,
        'passengerName': widget.userModel.name,
        'passengerImage': widget.userModel.profilePicture,
        'origin': {
          'lat': _currentPosition?.latitude,
          'lng': _currentPosition?.longitude,
          'address': await _getAddressFromLatLng(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude)),
        },
        'destination': {
          'lat': _destinationPosition?.latitude,
          'lng': _destinationPosition?.longitude,
          'address': _destinationController.text,
        },
        'driverLocation': {
          'lat': 0.0,
          'lng': 0.0,
        },
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'driverId': widget.taxiId,
        'canceled_by': '',
        'fare': _calculatedFare, // Add fare to request
        'distance': _distanceInKm, // Add distance to request
      };

      final requestRef =
          FirebaseFirestore.instance.collection('rideRequests').doc();
      await requestRef.set(requestData);

      final requestId = requestRef.id;
      monitorRideRequest(
          requestId, widget.userModel.role, context, _playSound, requestData);
      _waitForDriverResponse(requestRef.id);
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showErrorSnackBar("Error submitting booking: ${e.toString()}");
    }
  }

  // MODIFICATION: Rewrote the entire driver response logic for simplicity and reliability.
  void _waitForDriverResponse(String requestId) {
    _rideRequestSubscription?.cancel(); // Cancel any previous subscription.

    const responseTimeout =
        Duration(seconds: 45); // Total time to wait for a response.

    final stream = rideRequests.doc(requestId).snapshots();

    _rideRequestSubscription =
        stream.timeout(responseTimeout, onTimeout: (sink) {
      // This is called if 45 seconds pass with no 'accepted' or 'rejected' status.
      sink.addError(TimeoutException('Driver did not respond in time.'));
    }).listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          print('Request document $requestId no longer exists.');
          return;
        }

        final status = snapshot.data()!['status'];
        print('Received request status update: $status'); // DEBUGGING

        if (status == 'accepted') {
          _rideRequestSubscription?.cancel();
          setState(() => _isSubmitting = false);

          widget.onBookingConfirmed(
            _destinationController.text,
            _destinationPosition!,
          );

          if (mounted) {
            try {
              _playSound('sounds/confirmation.mp3');
              print("Sound played.");
            } catch (e) {
              print("Error playing sound: $e");
            }
            alertInfo(
              context,
              "Your ride has been accepted! The driver is on the way.",
              EvaIcons.checkmark,
              TypeInfo.success,
            );
            Future.delayed(const Duration(milliseconds: 2), () {
              Navigator.pop(context);
              // Navigate to ride tracking screen
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => RideTrackingPage()),
              // );
            });
          }
        } else if (status == 'rejected') {
          _rideRequestSubscription?.cancel();
          setState(() => _isSubmitting = false);
          try {
            _playSound('sounds/reject.mp3');
            print("Sound played.");
          } catch (e) {
            print("Error playing sound: $e");
          }
          alertInfo(
            context,
            "The driver rejected the request.",
            Icons.cancel,
            TypeInfo.error,
          );
        }
        // If status is 'pending', we just keep listening.
      },
      onError: (error) {
        // This will catch the TimeoutException or any other stream errors.
        _rideRequestSubscription?.cancel();
        setState(() => _isSubmitting = false);

        if (error is TimeoutException) {
          _showErrorSnackBar(
              'No response from the driver. Please try again later.');
          // Optionally, update the request status to 'timeout' in Firestore
          rideRequests.doc(requestId).update({'status': 'timeout'});
        } else {
          _showErrorSnackBar('An error occurred while waiting for the driver.');
          print('Listener error: $error'); // DEBUGGING
        }
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isDark ? darkGreen : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 24),
                _buildDestinationInput(),
                _buildSuggestionsList(),
                const SizedBox(height: 16),
                _buildMapView(),
                if (_showFareEstimate) _buildFareEstimate(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFareEstimate() => Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:
              widget.isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Fare',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: widget.isDark ? Colors.grey[350] : Colors.grey[600],
                  ),
                ),
                Text(
                  '\$${_calculatedFare.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.greenAccent : greenColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Distance',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: widget.isDark ? Colors.grey[350] : Colors.grey[600],
                  ),
                ),
                Text(
                  '${_distanceInKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildDragHandle() => Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  Widget _buildHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book a Ride',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: widget.isDark ? secondaryColor : null,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('With ${widget.driverName} in a ${widget.carModel}',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: widget.isDark ? Colors.grey[350] : Colors.grey[600])),
        ],
      );

  Widget _buildDestinationInput() => TextFormField(
        controller: _destinationController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a destination.';
          }
          if (_destinationPosition == null) {
            return 'Please select a valid location from the list or map.';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Where are you going?',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          prefixIcon: const Icon(CupertinoIcons.search, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSearching || _isReverseGeocoding)
                Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: greenColor),
                  ),
                ),
              if (_showClearButton && !_isSearching && !_isReverseGeocoding)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearDestination,
                ),
            ],
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: greenColor, width: 1.5),
          ),
        ),
      );
  Widget _buildSuggestionsList() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final suggestion = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.green),
            title: Text(
              suggestion['display_name'],
              style: GoogleFonts.poppins(
                  fontSize: 14, color: widget.isDark ? secondaryColor : null),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              setState(() {
                _destinationController.text = suggestion['display_name'];
                _destinationPosition = LatLng(
                  suggestion['lat'],
                  suggestion['lon'],
                );
                _searchResults.clear();
                _updateFareEstimate(); // Add this line
                _formKey.currentState?.validate();
              });
              FocusScope.of(context).unfocus();
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_destinationPosition!, 15),
              );
            },
          );
        },
      ),
    );
  }

  // Update the onTap handler in _buildMapView
  Widget _buildMapView() => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _destinationPosition == null
            ? const SizedBox.shrink()
            : SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _destinationPosition!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: _destinationPosition!,
                      ),
                    },
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (LatLng tappedPosition) async {
                      final address =
                          await _getAddressFromLatLng(tappedPosition);
                      setState(() {
                        _destinationPosition = tappedPosition;
                        _destinationController.text = address;
                        _searchResults.clear();
                        _updateFareEstimate(); // Add this line
                        _formKey.currentState?.validate();
                      });
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(tappedPosition, 15),
                      );
                    },
                  ),
                ),
              ),
      );

  Widget _buildActionButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: (_isSearching ||
                    _isReverseGeocoding ||
                    _destinationPosition == null ||
                    _isSubmitting)
                ? null
                : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Confirm Booking',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
}

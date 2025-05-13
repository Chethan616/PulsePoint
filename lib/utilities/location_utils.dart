import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
      1000; // in kilometers
}

class LocationUtils {
  // Request location permission and get current location
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      _showLocationServicesDialog(context);
      return null;
    }

    // Check for permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location permissions are permanently denied, cannot request permissions.'),
        ),
      );
      return null;
    }

    // Get the current position
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return null;
    }
  }

  // Show dialog to enable location services
  static void _showLocationServicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services to share your location.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Save location in Firestore
  static Future<Map<String, dynamic>?> shareLocation(
      BuildContext context) async {
    Position? position = await getCurrentLocation(context);
    if (position == null) return null;

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Open location in Google Maps
  static Future<void> openLocationInMaps(
      double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  // Save user's current location to their profile
  static Future<bool> saveUserLocation(BuildContext context) async {
    try {
      Position? position = await getCurrentLocation(context);
      if (position == null) return false;

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });

      return true;
    } catch (e) {
      print('Error saving user location: $e');
      return false;
    }
  }

  // Format location into a readable string (e.g., "23.1234°N, 45.6789°E")
  static String formatLocation(double latitude, double longitude) {
    final String latDirection = latitude >= 0 ? 'N' : 'S';
    final String longDirection = longitude >= 0 ? 'E' : 'W';

    return '${latitude.abs().toStringAsFixed(4)}°$latDirection, ${longitude.abs().toStringAsFixed(4)}°$longDirection';
  }
}

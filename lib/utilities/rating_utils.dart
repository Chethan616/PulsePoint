import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RatingUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save a rating from one user to another
  static Future<bool> rateUser({
    required String recipientUserId,
    required double rating,
    String? comment,
    String? interactionType, // 'chat', 'donation', 'thread', etc.
    String? interactionId,
  }) async {
    try {
      // Validate inputs
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Error: Current user is not authenticated');
        return false;
      }

      if (recipientUserId.isEmpty) {
        print('Error: recipient user ID is empty');
        return false;
      }

      // Ensure we're not rating ourselves
      if (currentUser.uid == recipientUserId) {
        print('Error: Cannot rate yourself');
        return false;
      }

      // Validate rating value
      if (rating <= 0 || rating > 5) {
        print('Error: Invalid rating value: $rating');
        return false;
      }

      // Check if recipient user exists
      try {
        DocumentSnapshot recipientDoc =
            await _firestore.collection('users').doc(recipientUserId).get();

        if (!recipientDoc.exists) {
          print('Error: Recipient user does not exist in database');
          return false;
        }
      } catch (e) {
        print('Error checking recipient user: $e');
        return false;
      }

      // Get current user data for the reference
      DocumentSnapshot userDoc;
      try {
        userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (!userDoc.exists) {
          print('Error: current user document does not exist');
          return false;
        }
      } catch (e) {
        print('Error getting current user data: $e');
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Create the rating document with proper error handling
      try {
        await _firestore
            .collection('users')
            .doc(recipientUserId)
            .collection('ratings')
            .add({
          'rating': rating,
          'comment': comment ?? '',
          'raterId': currentUser.uid,
          'raterName': userData['name'] ?? 'Anonymous',
          'raterProfileImage': userData['profileImageUrl'],
          'timestamp': FieldValue.serverTimestamp(),
          'interactionType': interactionType ?? 'profile',
          'interactionId': interactionId ?? '',
        });
      } catch (e) {
        print('Error adding rating document: $e');
        return false;
      }

      // Also update the user's average rating
      try {
        await _updateUserAverageRating(recipientUserId);
      } catch (e) {
        print('Error updating average rating: $e');
        // We still return true since the rating was saved
      }

      return true;
    } catch (e) {
      print('Error rating user: $e');
      return false;
    }
  }

  // Get all ratings for a user
  static Stream<QuerySnapshot> getUserRatings(String userId) {
    if (userId.isEmpty) {
      // Return empty stream if userId is invalid
      return Stream<QuerySnapshot>.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Calculate and update the user's average rating
  static Future<void> _updateUserAverageRating(String userId) async {
    if (userId.isEmpty) {
      print('Error: User ID is empty in updateUserAverageRating');
      return;
    }

    try {
      // Get all ratings
      QuerySnapshot ratingsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        // No ratings found, set defaults
        await _firestore.collection('users').doc(userId).update({
          'averageRating': 0.0,
          'totalRatings': 0,
        });
        return;
      }

      // Calculate average
      double sum = 0;
      int count = 0;

      for (var doc in ratingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['rating'] != null) {
          // Ensure we have a valid number
          double ratingValue = (data['rating'] as num).toDouble();
          if (ratingValue > 0 && ratingValue <= 5) {
            sum += ratingValue;
            count++;
          }
        }
      }

      double averageRating = count > 0 ? sum / count : 0;
      int totalRatings = count;

      // Update user document with average rating
      await _firestore.collection('users').doc(userId).update({
        'averageRating': averageRating,
        'totalRatings': totalRatings,
      });
    } catch (e) {
      print('Error updating average rating: $e');
      throw e; // Rethrow to handle in the calling function
    }
  }

  // Check if current user has already rated another user
  static Future<bool> hasUserRated(String recipientUserId) async {
    try {
      if (recipientUserId.isEmpty) {
        print('Error: recipient user ID is empty in hasUserRated');
        return false;
      }

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Error: Current user is not authenticated in hasUserRated');
        return false;
      }

      // Check if we're trying to rate ourselves
      if (currentUser.uid == recipientUserId) {
        print('Error: Cannot rate yourself in hasUserRated');
        return true; // Prevent rating yourself
      }

      QuerySnapshot existingRatings = await _firestore
          .collection('users')
          .doc(recipientUserId)
          .collection('ratings')
          .where('raterId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      return existingRatings.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user has rated: $e');
      return false;
    }
  }
}

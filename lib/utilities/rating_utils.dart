import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get current user data for the reference
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Create the rating document
      await _firestore
          .collection('users')
          .doc(recipientUserId)
          .collection('ratings')
          .add({
        'rating': rating,
        'comment': comment,
        'raterId': currentUser.uid,
        'raterName': userData['name'] ?? 'Anonymous',
        'raterProfileImage': userData['profileImageUrl'],
        'timestamp': FieldValue.serverTimestamp(),
        'interactionType': interactionType,
        'interactionId': interactionId,
      });

      // Also update the user's average rating
      await _updateUserAverageRating(recipientUserId);

      return true;
    } catch (e) {
      print('Error rating user: $e');
      return false;
    }
  }

  // Get all ratings for a user
  static Stream<QuerySnapshot> getUserRatings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ratings')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Calculate and update the user's average rating
  static Future<void> _updateUserAverageRating(String userId) async {
    try {
      // Get all ratings
      QuerySnapshot ratingsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate average
      double sum = 0;
      int count = 0;

      for (var doc in ratingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['rating'] != null) {
          sum += (data['rating'] as num).toDouble();
          count++;
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
    }
  }

  // Check if current user has already rated another user
  static Future<bool> hasUserRated(String recipientUserId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

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

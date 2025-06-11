// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Copyright (C) 2025  Author Name

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulsepoint/models/activity_record.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> recordActivity({
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_userId.isEmpty) return;

    try {
      await _firestore.collection('activities').add(
            ActivityRecord(
              id: '',
              userId: _userId,
              type: type,
              timestamp: DateTime.now(),
              title: title,
              description: description,
              additionalData: additionalData,
            ).toFirestore(),
          );
    } catch (e) {
      print('Error recording activity: $e');
    }
  }

  Future<void> recordActivityForUser({
    required String userId,
    required ActivityType type,
    required String title,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    if (userId.isEmpty) return;

    try {
      await _firestore.collection('activities').add(
            ActivityRecord(
              id: '',
              userId: userId,
              type: type,
              timestamp: DateTime.now(),
              title: title,
              description: description,
              additionalData: additionalData,
            ).toFirestore(),
          );
    } catch (e) {
      print('Error recording activity for user $userId: $e');
    }
  }

  Stream<List<ActivityRecord>> getUserActivities() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: _userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityRecord.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteActivity(String activityId) async {
    if (_userId.isEmpty) return;

    try {
      await _firestore.collection('activities').doc(activityId).delete();
    } catch (e) {
      print('Error deleting activity: $e');
    }
  }

  Future<void> clearAllActivities() async {
    if (_userId.isEmpty) return;

    try {
      final activities = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: _userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in activities.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing activities: $e');
    }
  }
}


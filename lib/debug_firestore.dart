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

class FirestoreDebugger {
  static Future<void> checkCollections() async {
    print('========= FIRESTORE DEBUGGER =========');

    try {
      // List all collections
      final collections =
          await FirebaseFirestore.instance.collectionGroup('').get();
      print('Collections found: ${collections.docs.length}');

      // Check for 'blood_donations' specifically
      final bloodDonations = await FirebaseFirestore.instance
          .collection('blood_donations')
          .limit(5)
          .get();
      print(
          'blood_donations collection exists: ${bloodDonations.docs.isNotEmpty}');
      print('blood_donations count: ${bloodDonations.docs.length}');

      // If documents exist, print details of the first document
      if (bloodDonations.docs.isNotEmpty) {
        final doc = bloodDonations.docs.first;
        print('Sample document ID: ${doc.id}');
        print('Sample document data:');
        final data = doc.data();
        data.forEach((key, value) {
          print('  $key: $value');
        });
      }

      print('===================================');
    } catch (e, stackTrace) {
      print('Error checking Firestore: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Helper to identify if the collection name might be different
  static Future<void> findSimilarCollections() async {
    print('===== SEARCHING SIMILAR COLLECTIONS =====');
    try {
      // Try to list all top-level collections (this is a workaround as Firestore
      // doesn't have a direct "list collections" API in the client)
      final batch = FirebaseFirestore.instance.batch();
      final batchRef = batch.toString();

      // Extract hints about collection names from the batch reference
      final possibleCollections = [
        'blood_donations',
        'blood_donation',
        'blooddonations',
        'blooddonation',
        'donations',
        'donation',
        'blood',
      ];

      print('Checking for similar collection names...');
      for (final collName in possibleCollections) {
        try {
          final result = await FirebaseFirestore.instance
              .collection(collName)
              .limit(1)
              .get();
          print(
              'Collection "$collName" exists: ${result.docs.isNotEmpty} (${result.docs.length} docs)');
        } catch (e) {
          print('Error checking collection "$collName": $e');
        }
      }

      print('===========================================');
    } catch (e) {
      print('Error finding collections: $e');
    }
  }
}


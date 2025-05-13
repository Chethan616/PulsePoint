import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulsepoint_v2/models/blood_donation_record.dart';
import 'package:pulsepoint_v2/models/activity_record.dart';
import 'package:pulsepoint_v2/providers/activity_service.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();

  String get _userId => _auth.currentUser?.uid ?? '';

  // Create a new donation request
  Future<String?> createDonationRequest({
    required String donorId,
    required String donorName,
    required String recipientName,
    required String donorPhone,
    required String recipientPhone,
    required String bloodType,
    required String location,
    required String hospitalName,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_userId.isEmpty) return null;

    try {
      // Create the donation record
      final docRef = await _firestore.collection('blood_donations').add(
            BloodDonationRecord(
              id: '',
              donorId: donorId,
              recipientId: _userId,
              donorName: donorName,
              recipientName: recipientName,
              donorPhone: donorPhone,
              recipientPhone: recipientPhone,
              bloodType: bloodType,
              requestDate: DateTime.now(),
              location: location,
              hospitalName: hospitalName,
              status: DonationStatus.requested,
              notes: notes,
              additionalData: additionalData,
            ).toFirestore(),
          );

      // Record activity for both donor and recipient
      await _activityService.recordActivity(
        type: ActivityType.bloodRequest,
        title: "Blood Request",
        description: "Requested $bloodType blood from $donorName",
        additionalData: {
          'donationId': docRef.id,
          'bloodType': bloodType,
          'donorName': donorName,
        },
      );

      return docRef.id;
    } catch (e) {
      print('Error creating donation request: $e');
      return null;
    }
  }

  // Accept a donation request
  Future<bool> acceptDonationRequest(String donationId) async {
    if (_userId.isEmpty) return false;

    try {
      final donationDoc =
          await _firestore.collection('blood_donations').doc(donationId).get();

      if (!donationDoc.exists) return false;

      final donation = BloodDonationRecord.fromFirestore(donationDoc);

      // Verify that the current user is the donor
      if (donation.donorId != _userId) return false;

      // Update the donation status
      await _firestore.collection('blood_donations').doc(donationId).update({
        'status': _donationStatusToString(DonationStatus.accepted),
      });

      // Record activity for both donor and recipient
      await _activityService.recordActivity(
        type: ActivityType.bloodDonation,
        title: "Donation Accepted",
        description:
            "Accepted blood donation request from ${donation.recipientName}",
        additionalData: {
          'donationId': donationId,
          'bloodType': donation.bloodType,
          'recipientName': donation.recipientName,
        },
      );

      return true;
    } catch (e) {
      print('Error accepting donation request: $e');
      return false;
    }
  }

  // Complete a donation
  Future<bool> completeDonation(String donationId) async {
    if (_userId.isEmpty) return false;

    try {
      final donationDoc =
          await _firestore.collection('blood_donations').doc(donationId).get();

      if (!donationDoc.exists) return false;

      final donation = BloodDonationRecord.fromFirestore(donationDoc);

      // Verify that the current user is either the donor or recipient
      if (donation.donorId != _userId && donation.recipientId != _userId)
        return false;

      // Update the donation status
      await _firestore.collection('blood_donations').doc(donationId).update({
        'status': _donationStatusToString(DonationStatus.completed),
        'completionDate': Timestamp.fromDate(DateTime.now()),
      });

      // Record activity for both donor and recipient
      if (_userId == donation.donorId) {
        await _activityService.recordActivity(
          type: ActivityType.bloodDonation,
          title: "Donation Completed",
          description: "Completed blood donation to ${donation.recipientName}",
          additionalData: {
            'donationId': donationId,
            'bloodType': donation.bloodType,
            'recipientName': donation.recipientName,
          },
        );
      } else {
        await _activityService.recordActivity(
          type: ActivityType.bloodRequest,
          title: "Donation Received",
          description: "Received blood donation from ${donation.donorName}",
          additionalData: {
            'donationId': donationId,
            'bloodType': donation.bloodType,
            'donorName': donation.donorName,
          },
        );
      }

      return true;
    } catch (e) {
      print('Error completing donation: $e');
      return false;
    }
  }

  // Decline or cancel a donation request
  Future<bool> cancelDonation(String donationId, bool isDonor) async {
    if (_userId.isEmpty) return false;

    try {
      final donationDoc =
          await _firestore.collection('blood_donations').doc(donationId).get();

      if (!donationDoc.exists) return false;

      final donation = BloodDonationRecord.fromFirestore(donationDoc);

      // Verify that the current user is either the donor or recipient
      if (isDonor && donation.donorId != _userId) return false;
      if (!isDonor && donation.recipientId != _userId) return false;

      final newStatus =
          isDonor ? DonationStatus.declined : DonationStatus.cancelled;

      // Update the donation status
      await _firestore.collection('blood_donations').doc(donationId).update({
        'status': _donationStatusToString(newStatus),
      });

      // Record activity for the user who cancelled/declined
      final actionType = isDonor ? "Declined" : "Cancelled";
      final otherPerson = isDonor ? donation.recipientName : donation.donorName;

      await _activityService.recordActivity(
        type: isDonor ? ActivityType.bloodDonation : ActivityType.bloodRequest,
        title: "$actionType Donation",
        description: "$actionType blood donation with $otherPerson",
        additionalData: {
          'donationId': donationId,
          'bloodType': donation.bloodType,
          'otherPersonName': otherPerson,
        },
      );

      return true;
    } catch (e) {
      print('Error cancelling donation: $e');
      return false;
    }
  }

  // Get all donation records where the user is either donor or recipient
  // REQUIRES FIRESTORE INDEX:
  // Collection: blood_donations
  // Fields to index:
  // 1. donorId (Ascending) + requestDate (Descending)
  // 2. recipientId (Ascending) + requestDate (Descending)
  Stream<List<BloodDonationRecord>> getUserDonations() {
    print('DonationService.getUserDonations() called');
    print('Current user ID: $_userId');

    if (_userId.isEmpty) {
      print('User ID is empty, returning empty stream');
      return Stream.value([]);
    }

    // Verify collection exists by checking once
    _firestore.collection('blood_donations').limit(1).get().then((snapshot) {
      print(
          'Collection check - blood_donations exists: ${snapshot.docs.isNotEmpty}');
    }).catchError((error) {
      print('Error checking collection: $error');
    });

    print('Querying Firestore for donations...');
    print('Collection: blood_donations');
    print('Filter conditions: donorId = $_userId OR recipientId = $_userId');

    // Note: Using '.where(Filter.or())' requires the corresponding composite indexes
    // Make sure you've created them in the Firebase console
    return _firestore
        .collection('blood_donations')
        .where(Filter.or(
          Filter('donorId', isEqualTo: _userId),
          Filter('recipientId', isEqualTo: _userId),
        ))
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Firestore donation snapshot received');
      print('Document count: ${snapshot.docs.length}');

      final donations = snapshot.docs.map((doc) {
        print('Processing document ID: ${doc.id}');
        try {
          final donation = BloodDonationRecord.fromFirestore(doc);
          return donation;
        } catch (e) {
          print('Error parsing donation document ${doc.id}: $e');
          rethrow; // Rethrow to help identify the exact problem
        }
      }).toList();

      print('Parsed ${donations.length} valid donation records');
      return donations;
    }).handleError((error) {
      print('ERROR IN DONATION STREAM: $error');
      return <BloodDonationRecord>[];
    });
  }

  // Get donation requests for a specific donor
  // REQUIRES FIRESTORE INDEX:
  // Collection: blood_donations
  // Fields to index:
  // - donorId (Ascending) + status (Ascending) + requestDate (Descending)
  Stream<List<BloodDonationRecord>> getDonationRequestsForDonor() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('blood_donations')
        .where('donorId', isEqualTo: _userId)
        .where('status',
            isEqualTo: _donationStatusToString(DonationStatus.requested))
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodDonationRecord.fromFirestore(doc))
            .toList());
  }

  // Get donation requests from a specific recipient
  // REQUIRES FIRESTORE INDEX:
  // Collection: blood_donations
  // Fields to index:
  // - recipientId (Ascending) + requestDate (Descending)
  Stream<List<BloodDonationRecord>> getDonationRequestsFromRecipient() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('blood_donations')
        .where('recipientId', isEqualTo: _userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodDonationRecord.fromFirestore(doc))
            .toList());
  }

  // Helper method to convert DonationStatus to string
  String _donationStatusToString(DonationStatus status) {
    switch (status) {
      case DonationStatus.requested:
        return 'requested';
      case DonationStatus.accepted:
        return 'accepted';
      case DonationStatus.completed:
        return 'completed';
      case DonationStatus.declined:
        return 'declined';
      case DonationStatus.cancelled:
        return 'cancelled';
    }
  }

  // Debugging helper method to troubleshoot common issues
  Future<Map<String, dynamic>> troubleshootDonations() async {
    final results = <String, dynamic>{};

    try {
      print('🔍 Running donation service troubleshooting...');

      // Check current user
      final user = _auth.currentUser;
      results['currentUser'] = user != null;
      results['userId'] = _userId;
      print(
          'Current user: ${results['currentUser']} (ID: ${results['userId']})');

      // Check if collection exists
      final collections =
          await _firestore.collection('blood_donations').limit(1).get();
      results['collectionExists'] = collections.docs.isNotEmpty;
      print(
          'Collection blood_donations exists: ${results['collectionExists']}');

      // Test simple query without indexes
      final testDocs =
          await _firestore.collection('blood_donations').limit(5).get();
      results['queryWorking'] = true;
      results['totalDocuments'] = testDocs.docs.length;
      print(
          'Simple query successful, found ${results['totalDocuments']} documents');

      // Test user-specific query without order
      if (!_userId.isEmpty) {
        final userDocs = await _firestore
            .collection('blood_donations')
            .where('donorId', isEqualTo: _userId)
            .get();
        results['userDocsAsDonor'] = userDocs.docs.length;
        print('User documents as donor: ${results['userDocsAsDonor']}');

        final recipientDocs = await _firestore
            .collection('blood_donations')
            .where('recipientId', isEqualTo: _userId)
            .get();
        results['userDocsAsRecipient'] = recipientDocs.docs.length;
        print('User documents as recipient: ${results['userDocsAsRecipient']}');
      }

      // Test index query
      try {
        final indexedDocs = await _firestore
            .collection('blood_donations')
            .where('donorId', isEqualTo: _userId)
            .orderBy('requestDate', descending: true)
            .get();
        results['indexedQueryWorking'] = true;
        print('Indexed query successful');
      } catch (e) {
        results['indexedQueryWorking'] = false;
        results['indexError'] = e.toString();
        print('Indexed query failed: $e');
      }

      print('Troubleshooting completed!');
      return results;
    } catch (e) {
      print('Error during troubleshooting: $e');
      results['error'] = e.toString();
      return results;
    }
  }
}

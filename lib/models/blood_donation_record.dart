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

enum DonationStatus { requested, accepted, completed, declined, cancelled }

class BloodDonationRecord {
  final String id;
  final String donorId;
  final String recipientId;
  final String donorName;
  final String recipientName;
  final String donorPhone;
  final String recipientPhone;
  final String bloodType;
  final DateTime requestDate;
  final DateTime? completionDate;
  final String location;
  final String hospitalName;
  final DonationStatus status;
  final String? notes;
  final Map<String, dynamic>? additionalData;

  BloodDonationRecord({
    required this.id,
    required this.donorId,
    required this.recipientId,
    required this.donorName,
    required this.recipientName,
    required this.donorPhone,
    required this.recipientPhone,
    required this.bloodType,
    required this.requestDate,
    this.completionDate,
    required this.location,
    required this.hospitalName,
    required this.status,
    this.notes,
    this.additionalData,
  });

  factory BloodDonationRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return BloodDonationRecord(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      donorName: data['donorName'] ?? '',
      recipientName: data['recipientName'] ?? '',
      donorPhone: data['donorPhone'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      bloodType: data['bloodType'] ?? '',
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      completionDate: data['completionDate'] != null
          ? (data['completionDate'] as Timestamp).toDate()
          : null,
      location: data['location'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      status: _stringToDonationStatus(data['status'] ?? 'requested'),
      notes: data['notes'],
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'recipientId': recipientId,
      'donorName': donorName,
      'recipientName': recipientName,
      'donorPhone': donorPhone,
      'recipientPhone': recipientPhone,
      'bloodType': bloodType,
      'requestDate': Timestamp.fromDate(requestDate),
      'completionDate':
          completionDate != null ? Timestamp.fromDate(completionDate!) : null,
      'location': location,
      'hospitalName': hospitalName,
      'status': _donationStatusToString(status),
      'notes': notes,
      'additionalData': additionalData,
    };
  }

  static DonationStatus _stringToDonationStatus(String statusStr) {
    switch (statusStr) {
      case 'requested':
        return DonationStatus.requested;
      case 'accepted':
        return DonationStatus.accepted;
      case 'completed':
        return DonationStatus.completed;
      case 'declined':
        return DonationStatus.declined;
      case 'cancelled':
        return DonationStatus.cancelled;
      default:
        return DonationStatus.requested;
    }
  }

  static String _donationStatusToString(DonationStatus status) {
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

  String get statusDisplayName {
    switch (status) {
      case DonationStatus.requested:
        return 'Requested';
      case DonationStatus.accepted:
        return 'Accepted';
      case DonationStatus.completed:
        return 'Completed';
      case DonationStatus.declined:
        return 'Declined';
      case DonationStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Create a copy of the record with updated fields
  BloodDonationRecord copyWith({
    String? id,
    String? donorId,
    String? recipientId,
    String? donorName,
    String? recipientName,
    String? donorPhone,
    String? recipientPhone,
    String? bloodType,
    DateTime? requestDate,
    DateTime? completionDate,
    String? location,
    String? hospitalName,
    DonationStatus? status,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    return BloodDonationRecord(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      recipientId: recipientId ?? this.recipientId,
      donorName: donorName ?? this.donorName,
      recipientName: recipientName ?? this.recipientName,
      donorPhone: donorPhone ?? this.donorPhone,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      bloodType: bloodType ?? this.bloodType,
      requestDate: requestDate ?? this.requestDate,
      completionDate: completionDate ?? this.completionDate,
      location: location ?? this.location,
      hospitalName: hospitalName ?? this.hospitalName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}


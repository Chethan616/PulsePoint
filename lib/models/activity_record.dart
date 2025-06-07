import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  bloodDonation,
  bloodRequest,
  hospitalVisit,
}

class ActivityRecord {
  final String id;
  final String userId;
  final ActivityType type;
  final DateTime timestamp;
  final String title;
  final String description;
  final Map<String, dynamic>? additionalData;

  ActivityRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    this.additionalData,
  });

  factory ActivityRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ActivityRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _stringToActivityType(data['type'] ?? 'bloodDonation'),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      title: data['title'] ?? 'Activity',
      description: data['description'] ?? '',
      additionalData: data['additionalData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': _activityTypeToString(type),
      'timestamp': Timestamp.fromDate(timestamp),
      'title': title,
      'description': description,
      'additionalData': additionalData,
    };
  }

  static ActivityType _stringToActivityType(String typeStr) {
    switch (typeStr) {
      case 'bloodDonation':
        return ActivityType.bloodDonation;
      case 'bloodRequest':
        return ActivityType.bloodRequest;
      case 'hospitalVisit':
        return ActivityType.hospitalVisit;
      default:
        return ActivityType.bloodDonation;
    }
  }

  static String _activityTypeToString(ActivityType type) {
    switch (type) {
      case ActivityType.bloodDonation:
        return 'bloodDonation';
      case ActivityType.bloodRequest:
        return 'bloodRequest';
      case ActivityType.hospitalVisit:
        return 'hospitalVisit';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case ActivityType.bloodDonation:
        return 'Blood Donation';
      case ActivityType.bloodRequest:
        return 'Blood Request';
      case ActivityType.hospitalVisit:
        return 'Hospital Visit';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case ActivityType.bloodDonation:
        return Icons.favorite;
      case ActivityType.bloodRequest:
        return Icons.bloodtype;
      case ActivityType.hospitalVisit:
        return Icons.local_hospital;
    }
  }
}

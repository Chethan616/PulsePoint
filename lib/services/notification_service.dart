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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Global navigator key for navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Request notification permissions
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permission for iOS devices
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Get device token for FCM
      String? token = await _fcm.getToken();
      print('FCM Token: $token');

      if (token != null) {
        // Save the token to Firestore
        await _saveTokenToFirestore(token);
        print('FCM token saved to Firestore');
      } else {
        print('Failed to get FCM token');
      }

      // Configure FCM callbacks
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Configure refresh token logic
      _fcm.onTokenRefresh.listen((newToken) async {
        print('FCM token refreshed: $newToken');
        await _saveTokenToFirestore(newToken);
      });

      // Create Android notification channels
      await createNotificationChannels();

      // Configure local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification,
      );

      print('Notification service initialized successfully');
    } catch (e, stackTrace) {
      print('Error initializing notification service: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Create notification channels for Android
  Future<void> createNotificationChannels() async {
    print('Creating notification channels for Android');

    try {
      const chatChannel = AndroidNotificationChannel(
        'chat_channel',
        'Chat Notifications',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      const bloodRequestChannel = AndroidNotificationChannel(
        'blood_request_channel',
        'Blood Request Notifications',
        description: 'Notifications for blood donation requests',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(chatChannel);
        await androidPlugin.createNotificationChannel(bloodRequestChannel);
        print('Notification channels created successfully');
      } else {
        print('Android plugin is null, cannot create channels');
      }
    } catch (e, stackTrace) {
      print('Error creating notification channels: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    // We don't need to show notification here as FCM will handle it
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print('Got foreground message: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // Show local notification
    if (notification != null) {
      String channelId = 'default_channel';

      // Determine channel based on notification type
      if (message.data['type'] == 'chat') {
        channelId = 'chat_channel';
      } else if (message.data['type'] == 'blood_request') {
        channelId = 'blood_request_channel';
      }

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId,
            icon: android?.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Handle notification taps
  void _onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      try {
        Map<String, dynamic> payload = json.decode(response.payload!);
        _navigateBasedOnPayload(payload);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    _navigateBasedOnPayload(message.data);
  }

  // Navigate based on notification payload
  void _navigateBasedOnPayload(Map<String, dynamic> payload) {
    // Get navigator context
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      print('Navigator not available for handling notification');
      return;
    }

    final notificationType = payload['type'] as String?;

    if (notificationType == 'chat') {
      // Handle chat notification
      final senderId = payload['senderId'] as String?;
      final conversationId = payload['conversationId'] as String?;

      if (senderId != null && conversationId != null) {
        // Navigate to chat screen
        navigator.pushNamed(
          '/chat',
          arguments: {
            'conversationId': conversationId,
            'recipientUserId': senderId,
          },
        );
      }
    } else if (notificationType == 'blood_request') {
      // Handle blood request notification
      final requestId = payload['requestId'] as String?;

      if (requestId != null) {
        // Navigate to blood request details screen
        navigator.pushNamed(
          '/blood_request_details',
          arguments: {
            'requestId': requestId,
          },
        );
      }
    }
  }

  // Send notifications to nearby users about blood request
  Future<void> sendBloodRequestNotifications({
    required String bloodType,
    required double latitude,
    required double longitude,
    required String requestId,
    required String title,
    required String body,
  }) async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Find users within 50km who match blood type
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();

      List<String> tokensList = [];

      for (var doc in userSnapshot.docs) {
        // Skip self
        if (doc.id == currentUser.uid) continue;

        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        String? fcmToken = userData['fcmToken'];

        // Skip if no token
        if (fcmToken == null || fcmToken.isEmpty) continue;

        // Check if user has location data
        if (userData['location'] != null) {
          double userLat = userData['location']['latitude'];
          double userLng = userData['location']['longitude'];

          // Calculate distance
          double distance = Geolocator.distanceBetween(
                latitude,
                longitude,
                userLat,
                userLng,
              ) /
              1000; // Convert to km

          // Check if user is within 50km and has matching blood type
          bool isBloodMatch = userData['bloodType'] == bloodType;
          bool isNearby = distance <= 50;

          if (isNearby && (isBloodMatch || bloodType == 'Any')) {
            tokensList.add(fcmToken);
          }
        }
      }

      // Send notifications to all matching users
      for (String token in tokensList) {
        await _sendPushNotification(
          token: token,
          title: title,
          body: body,
          data: {
            'type': 'blood_request',
            'requestId': requestId,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );
      }
    } catch (e) {
      print('Error sending blood request notifications: $e');
    }
  }

  // Send notification for blood request thread replies or offers
  Future<void> sendBloodRequestThreadNotification({
    required String requestId,
    required String authorId,
    required String authorName,
    required String recipientUserId,
    required String title,
    required String body,
    required String type, // 'reply', 'offer', 'location'
  }) async {
    try {
      print('Preparing to send thread notification:');
      print('- Request ID: $requestId');
      print('- Author ID: $authorId');
      print('- Author Name: $authorName');
      print('- Recipient User ID: $recipientUserId');
      print('- Title: $title');
      print('- Body: $body');
      print('- Type: $type');

      // Skip if sending to self
      if (recipientUserId == authorId) {
        print('Skipping notification as recipient is the author');
        return;
      }

      // Get recipient's FCM token
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(recipientUserId).get();

      if (!userDoc.exists) {
        print('User document does not exist for ID: $recipientUserId');
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? fcmToken = userData['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) {
        print('No FCM token found for user: $recipientUserId');
        return;
      }

      print('Found FCM token: $fcmToken');

      // Get user notification preferences
      bool enableBloodRequestNotifications = true;
      if (userData.containsKey('notificationPreferences')) {
        final prefs = userData['notificationPreferences'];
        if (prefs is Map &&
            prefs.containsKey('enableBloodRequestNotifications')) {
          enableBloodRequestNotifications =
              prefs['enableBloodRequestNotifications'] ?? true;
        }
      }

      if (!enableBloodRequestNotifications) {
        print('User has disabled blood request notifications');
        return;
      }

      print('Sending notification to token: $fcmToken');
      await _sendPushNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: {
          'type': 'blood_request',
          'requestId': requestId,
          'replyType': type,
          'authorId': authorId,
          'authorName': authorName,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );

      print('Blood request thread notification sent successfully');
    } catch (e, stackTrace) {
      print('Error sending blood request thread notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Send chat message notification
  Future<void> sendChatNotification({
    required String recipientUserId,
    required String senderId,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    try {
      // Get recipient's FCM token
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(recipientUserId).get();

      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? fcmToken = userData['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) return;

      await _sendPushNotification(
        token: fcmToken,
        title: 'New message from $senderName',
        body: message,
        data: {
          'type': 'chat',
          'senderId': senderId,
          'conversationId': conversationId,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  // Send push notification using Firebase Cloud Messaging HTTP v1 API
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // Log the notification being sent (for debugging)
      print('Sending notification to token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      // Create an HTTP request to send to FCM
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAApHKm5vA:APA91bGR8Klf3sQ5SsulKO1BPGjp-xeN5Zh8wdTEfpYIKd_kYf-1H4NcpUzA_f5fNRbvuWsWK1zP6m1KXzQS1qTZVlZ8JcZqZ5TgQ0rlsXgN8u33KfhRW-QDsERdLFzZYszwf1jfQHYM',
        },
        body: jsonEncode(<String, dynamic>{
          'notification': <String, dynamic>{
            'title': title,
            'body': body,
            'sound': 'default',
            'android_channel_id': 'blood_request_channel',
            'badge': '1',
          },
          'priority': 'high',
          'data': data,
          'to': token,
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        print('Response body: ${response.body}');

        // Parse response to get more details
        Map<String, dynamic> responseData = jsonDecode(response.body);
        int success = responseData['success'] ?? 0;

        if (success <= 0) {
          print('FCM returned success=0: ${response.body}');
          // Check for error messages
          if (responseData.containsKey('results')) {
            final results = responseData['results'];
            if (results is List && results.isNotEmpty) {
              print('Error details: ${results[0]}');
            }
          }
        }
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error sending push notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Subscription methods
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  // Setting user preferences for notifications
  Future<void> saveNotificationPreferences({
    required bool enableChatNotifications,
    required bool enableBloodRequestNotifications,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableChatNotifications', enableChatNotifications);
    await prefs.setBool(
        'enableBloodRequestNotifications', enableBloodRequestNotifications);

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'notificationPreferences': {
          'enableChatNotifications': enableChatNotifications,
          'enableBloodRequestNotifications': enableBloodRequestNotifications,
        },
      });
    }
  }
}


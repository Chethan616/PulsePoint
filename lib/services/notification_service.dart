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

  // Initialize notification channels and request permissions
  Future<void> init() async {
    // Request notification permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // For iOS only
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await createNotificationChannels();
    }

    // Get FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      print('FCM Token: $token');
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });

    // Handle message when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Create notification channels for Android
  Future<void> createNotificationChannels() async {
    const chatChannel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Notifications',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
    );

    const bloodRequestChannel = AndroidNotificationChannel(
      'blood_request_channel',
      'Blood Request Notifications',
      description: 'Notifications for blood donation requests',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bloodRequestChannel);
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
    // NOTE: This method uses Firebase Admin SDK approach
    // In a production app, this should be handled by a secure server
    // This is a simplified version for demonstration purposes

    // Ideally, you'd use your backend server to send notifications
    // The below is a placeholder for how it would work with a real server
    try {
      // Simulate sending push notification
      print('Sending notification to token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      // In a real implementation, you would make an HTTP request to your server
      // which would then use Firebase Admin SDK to send the notification
    } catch (e) {
      print('Error sending push notification: $e');
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

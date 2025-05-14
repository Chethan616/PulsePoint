import 'dart:io';
import 'package:flutter/services.dart';

/// A simpler implementation of home_widget functionality
/// to avoid compatibility issues with the original package
class HomeWidgetCustom {
  static const MethodChannel _channel = MethodChannel('home_widget');
  static const _eventChannel = EventChannel('home_widget/updates');

  /// Save data to be used by the home screen widget
  static Future<bool> saveWidgetData(String id, dynamic data) async {
    try {
      await _channel.invokeMethod('saveWidgetData', {'id': id, 'data': data});
      return true;
    } catch (e) {
      print('Error saving widget data: $e');
      return false;
    }
  }

  /// Update all widgets
  static Future<bool> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'name': name,
        'android': androidName ?? qualifiedAndroidName,
        'ios': iOSName,
      });
      return true;
    } catch (e) {
      print('Error updating widget: $e');
      return false;
    }
  }

  /// Set the App Group ID (Required for iOS)
  static Future<bool> setAppGroupId(String groupId) async {
    try {
      if (!Platform.isIOS) return true;
      await _channel.invokeMethod('setAppGroupId', {'groupId': groupId});
      return true;
    } catch (e) {
      print('Error setting app group ID: $e');
      return false;
    }
  }

  /// Get data saved for widgets
  static Future<dynamic> getWidgetData(String id) async {
    try {
      return await _channel.invokeMethod('getWidgetData', {'id': id});
    } catch (e) {
      print('Error getting widget data: $e');
      return null;
    }
  }

  /// Stream of widget updates
  static Stream<Uri> get widgetClicked {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => Uri.parse(event.toString()));
  }

  /// Register a background callback
  static Future<bool> registerBackgroundCallback(
      Function(Uri? uri) callback) async {
    // This is a simplified implementation - in real apps,
    // background callback registration would be more complex
    try {
      // For now, we'll just simulate this by setting up a listener
      widgetClicked.listen((uri) {
        callback(uri);
      });
      return true;
    } catch (e) {
      print('Error registering background callback: $e');
      return false;
    }
  }
}

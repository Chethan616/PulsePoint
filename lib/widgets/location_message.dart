import 'package:flutter/material.dart';
import 'package:pulsepoint_v2/utilities/location_utils.dart';

class LocationMessage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? senderName;
  final DateTime? timestamp;
  final bool showActions;

  const LocationMessage({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.senderName,
    this.timestamp,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      color: isDark ? Colors.grey[800] : Colors.blue[50],
      child: InkWell(
        onTap: showActions
            ? () => LocationUtils.openLocationInMaps(latitude, longitude)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: isDark ? colorScheme.primary : Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      senderName != null
                          ? '$senderName shared a location'
                          : 'Location shared',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Coordinates display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LocationUtils.formatLocation(latitude, longitude),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white : Colors.blue[900],
                  ),
                ),
              ),

              // Timestamp if provided
              if (timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),

              // Action buttons
              if (showActions)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('View on Map'),
                        onPressed: () => LocationUtils.openLocationInMaps(
                            latitude, longitude),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDark ? colorScheme.primary : Colors.blue[700],
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// A simpler version for chat bubbles
class LocationBubble extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isMe;

  const LocationBubble({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? (isDark ? Colors.blue[800] : Colors.blue[100])
            : (isDark ? Colors.grey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMe ? 16 : 4),
          topRight: Radius.circular(isMe ? 4 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isMe
                    ? (isDark ? Colors.white : Colors.blue[700])
                    : (isDark ? Colors.white70 : Colors.black87),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Location shared',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMe
                      ? (isDark ? Colors.white : Colors.blue[700])
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => LocationUtils.openLocationInMaps(latitude, longitude),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMe
                    ? (isDark ? Colors.blue[700] : Colors.blue[50])
                    : (isDark ? Colors.grey[700] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                LocationUtils.formatLocation(latitude, longitude),
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isMe
                      ? (isDark ? Colors.white : Colors.blue[900])
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

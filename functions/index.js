const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Send notification when a new blood request is created
 * Triggers when a new document is created in the 'blood_requests' collection
 */
exports.sendBloodRequestNotifications = functions.region('us-central1').firestore
  .document('blood_requests/{requestId}')
  .onCreate(async (snapshot, context) => {
    try {
      const requestData = snapshot.data();
      const requestId = context.params.requestId;
      
      // Skip if no location data is available
      if (!requestData.location) {
        console.log('No location data found for blood request:', requestId);
        return null;
      }

      // Get request details
      const { bloodType, authorName, title, location } = requestData;
      const { latitude, longitude } = location;
      
      // Query users within 50km who match the blood type
      const usersSnapshot = await admin.firestore().collection('users').get();
      const currentUserId = requestData.authorId;
      
      const tokens = [];
      
      // Find relevant users and their FCM tokens
      for (const userDoc of usersSnapshot.docs) {
        // Skip the request creator
        if (userDoc.id === currentUserId) continue;
        
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        // Skip if no token or no location
        if (!fcmToken || !userData.location) continue;
        
        const userLat = userData.location.latitude;
        const userLng = userData.location.longitude;
        
        // Calculate distance between request and user
        const distance = calculateDistance(
          latitude,
          longitude,
          userLat,
          userLng
        );
        
        // Check if user is within 50km and has matching blood type
        const isBloodMatch = userData.bloodType === bloodType || bloodType === 'Any';
        const isNearby = distance <= 50;
        
        if (isNearby && isBloodMatch) {
          tokens.push(fcmToken);
        }
      }
      
      if (tokens.length === 0) {
        console.log('No matching users found for blood request:', requestId);
        return null;
      }
      
      // Create the notification message
      const notificationMessage = {
        notification: {
          title: 'Urgent Blood Request Nearby',
          body: `${authorName} needs ${bloodType} blood: ${title}`,
        },
        data: {
          type: 'blood_request',
          requestId: requestId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };
      
      // Send notifications to all tokens
      const response = await admin.messaging().sendMulticast({
        tokens,
        ...notificationMessage,
      });
      
      console.log(
        `${response.successCount} messages were sent successfully for blood request: ${requestId}`
      );
      
      return null;
    } catch (error) {
      console.error('Error sending blood request notifications:', error);
      return null;
    }
  });

/**
 * Send notification when a new chat message is sent
 * Triggers when a new document is created in a conversation's messages subcollection
 */
exports.sendChatNotifications = functions.region('us-central1').firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      const messageData = snapshot.data();
      const conversationId = context.params.conversationId;
      
      // Skip messages sent by the system
      if (messageData.senderId === 'system') return null;
      
      // Get conversation data to find recipients
      const conversationDoc = await admin
        .firestore()
        .collection('conversations')
        .doc(conversationId)
        .get();
      
      if (!conversationDoc.exists) {
        console.log('Conversation not found:', conversationId);
        return null;
      }
      
      const conversationData = conversationDoc.data();
      const participants = conversationData.participants || [];
      
      // Skip if no participants
      if (participants.length === 0) return null;
      
      // Get sender details
      const senderId = messageData.senderId;
      const senderName = messageData.senderName || 'Unknown';
      const messageText = messageData.text || 'New message';
      
      // For each participant (excluding sender), send a notification
      for (const participantId of participants) {
        // Skip sending notification to the sender
        if (participantId === senderId) continue;
        
        // Get recipient FCM token
        const userDoc = await admin
          .firestore()
          .collection('users')
          .doc(participantId)
          .get();
        
        if (!userDoc.exists) continue;
        
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        // Skip if no FCM token
        if (!fcmToken) continue;
        
        // Create notification message
        const notificationMessage = {
          notification: {
            title: `New message from ${senderName}`,
            body: messageText,
          },
          data: {
            type: 'chat',
            senderId: senderId,
            conversationId: conversationId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        };
        
        // Send notification
        await admin.messaging().send({
          token: fcmToken,
          ...notificationMessage,
        });
        
        console.log(`Chat notification sent to user ${participantId} for conversation ${conversationId}`);
      }
      
      return null;
    } catch (error) {
      console.error('Error sending chat notification:', error);
      return null;
    }
  });

// Calculate distance between two points in kilometers
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in kilometers
  
  return distance;
}

// Convert degrees to radians
function deg2rad(deg) {
  return deg * (Math.PI / 180);
} 
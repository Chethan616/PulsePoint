# PulsePoint Notifications Setup Guide

This guide will help you set up push notifications for the PulsePoint app.

## Firebase Console Setup

1. **Go to Firebase Console**:
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - Select your project

2. **Set up Cloud Messaging**:
   - Navigate to "Cloud Messaging" in the left sidebar under "Engage"
   - Enable Cloud Messaging API if it's not already enabled
   - For Android, download the google-services.json file and place it in the `android/app` directory
   - For iOS, download the GoogleService-Info.plist file and add it to your iOS project using Xcode

3. **Enable Background Modes for iOS**:
   - In Xcode, select your project and navigate to "Capabilities"
   - Enable "Background Modes" and check "Remote Notifications"

## Deploying Cloud Functions

Cloud Functions are needed to send notifications when specific events happen in the app.

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Log in to Firebase**:
   ```bash
   firebase login
   ```

3. **Deploy the Functions**:
   ```bash
   cd functions
   npm install
   npm run deploy
   ```

## Testing Notifications

1. **Test Chat Notifications**:
   - Open the app on two different devices (or simulators)
   - Sign in with two different accounts
   - Start a conversation and send a message
   - The recipient should receive a notification if the app is in the background

2. **Test Blood Request Notifications**:
   - Sign in with one account and create a blood request
   - Sign in with another account on a different device
   - Make sure the second account is within 50km of the first and has a matching blood type
   - The second account should receive a notification about the blood request

## Troubleshooting

1. **Android Notifications Not Working**:
   - Check that you have the correct google-services.json file in android/app
   - Ensure that the FCM token is being saved to Firestore
   - Look for any errors in the Android logcat related to FCM

2. **iOS Notifications Not Working**:
   - Verify that you have the correct GoogleService-Info.plist file in your iOS project
   - Check if you have the necessary entitlements for push notifications
   - Make sure you have an Apple Developer account and have configured APNs
   - Check if you have a valid provisioning profile with push notification entitlements

3. **Cloud Functions Issues**:
   - Check the Firebase Functions logs in the Firebase Console
   - Ensure your Firebase project is on the Blaze plan (pay-as-you-go)
   - Verify that the functions were deployed correctly

## Conclusion

You should now have push notifications working in your PulsePoint app. Users will receive notifications for:

- New chat messages
- Blood requests from nearby users with matching blood types

These notifications will work even when the app is in the background or closed completely.

For any issues, check the Firebase Console logs and the app logs for more information. 
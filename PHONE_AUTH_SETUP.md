# Firebase Phone Authentication Setup Guide

This guide provides step-by-step instructions for implementing Firebase Phone Authentication in your Flutter app.

## 1. Generate SHA Certificate Keys

SHA keys are required for Android applications to use Firebase Authentication services.

### For Debug Build:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### For Release Build:

```bash
keytool -list -v -keystore <your_keystore_path> -alias <your_alias> -storepass <your_storepass> -keypass <your_keypass>
```

You'll need both SHA-1 and SHA-256 fingerprints.

## 2. Add SHA Keys to Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on the gear icon (⚙️) and select "Project settings"
4. Select your Android app under "Your apps"
5. Scroll down to "SHA certificate fingerprints"
6. Click "Add fingerprint"
7. Enter your SHA-1 and SHA-256 keys

## 3. Enable Phone Authentication

1. In Firebase Console, navigate to "Authentication"
2. Click on "Sign-in method" tab
3. Enable "Phone" as a sign-in provider
4. Save your changes

## 4. Update Android Configuration

### Update build.gradle (app-level)

Ensure your app-level `build.gradle` file has the following:

```gradle
dependencies {
    // Add Firebase Authentication
    implementation 'com.google.firebase:firebase-auth:22.1.2'
}
```

### Update AndroidManifest.xml

Add the required permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 5. Update iOS Configuration

### Update Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>REVERSED_CLIENT_ID_FROM_GOOGLESERVICE_INFO_PLIST</string>
    </array>
  </dict>
</array>
```

## 6. Implement Flutter Phone Authentication

Here's a basic implementation for your Flutter app:

```dart
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Step 1: Send verification code
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onVerificationFailed,
    Function(PhoneAuthCredential) onVerificationCompleted,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }
  
  // Step 2: Verify OTP
  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    // Sign in the user with the credential
    return await _auth.signInWithCredential(credential);
  }
}
```

## 7. Usage in Your Flutter App

```dart
// Create instance of auth service
final phoneAuthService = PhoneAuthService();
String _verificationId = '';

// Step 1: Send verification code when user enters phone number
void sendVerificationCode(String phoneNumber) async {
  await phoneAuthService.verifyPhoneNumber(
    phoneNumber,
    (String verificationId) {
      setState(() {
        _verificationId = verificationId;
        // Navigate to OTP input screen
      });
    },
    (FirebaseAuthException e) {
      // Handle verification failed
      print('Verification Failed: ${e.message}');
    },
    (PhoneAuthCredential credential) {
      // Auto-verification completed (rare on most devices)
      _auth.signInWithCredential(credential);
    },
  );
}

// Step 2: Verify OTP when user enters the code
void verifyOTP(String otp) async {
  try {
    final userCredential = await phoneAuthService.verifyOTP(_verificationId, otp);
    if (userCredential.user != null) {
      // User successfully signed in
      // Navigate to home screen or set up user profile
    }
  } catch (e) {
    // Handle verification error
    print('OTP Verification Failed: $e');
  }
}
```

## 8. Testing

1. In Firebase Console, go to Authentication → Phone
2. Add test phone numbers for development
3. Use these test numbers during development to avoid SMS verification limits

## 9. Troubleshooting Common Issues

### Invalid SHA Keys
- Double-check the SHA keys added to Firebase
- Make sure you're using the correct keystore file
- Ensure you've added both debug and release SHA keys

### SMS Verification Not Working
- Check your Firebase billing is set up correctly
- Ensure your project has SMS verification enabled
- Verify your SHA keys are correct and added to Firebase

### OTP Not Received
- Make sure you have formatted the phone number correctly with country code
- Test with Firebase test phone numbers
- Check your Firebase Console logs for errors

### App Crashing During Authentication
- Check Firebase dependencies are correctly implemented
- Ensure your app has internet permissions
- Verify the Firebase configuration files are properly set up

## 10. Security Best Practices

- Never store OTP codes in your app
- Implement rate limiting for OTP attempts
- Set proper timeout for OTP verification
- Use Firebase App Check for additional security

## Additional Resources

- [Official Firebase Phone Auth Documentation](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [Firebase Authentication Best Practices](https://firebase.google.com/docs/auth/web/phone-auth#security-concerns) 
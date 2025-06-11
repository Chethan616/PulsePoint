# Generating and Adding SHA Keys to Firebase

This guide provides step-by-step instructions for generating SHA-1 and SHA-256 keys and adding them to your Firebase project for PulsePoint.

## Step 1: Generate SHA Keys

### For Windows

Find your JDK path (usually located at `C:\Program Files\Java\jdk-version\bin`) and use the following commands:

```powershell
# For debug key
cd "C:\Program Files\Java\jdk-version\bin"
.\keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release key (if you have a keystore file)
.\keytool -list -v -keystore path\to\your\release\keystore.jks -alias your_alias -storepass your_storepass -keypass your_keypass
```

### For macOS/Linux

```bash
# For debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release key (if you have a keystore file)
keytool -list -v -keystore /path/to/your/release/keystore.jks -alias your_alias -storepass your_storepass -keypass your_keypass
```

### Using Android Studio

1. Open Android Studio
2. Open your project
3. Click on "Gradle" tab on the right side
4. Navigate to Tasks > android > signingReport
5. Double-click on signingReport to run it
6. Look for SHA-1 and SHA-256 certificates in the Build output

## Step 2: Add SHA Keys to Firebase

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on the gear icon (⚙️) in the top left corner and select "Project settings"
4. In the "Your apps" section, select your Android app
5. Scroll down to "SHA certificate fingerprints"
6. Click "Add fingerprint"
7. Enter your SHA-1 and SHA-256 keys one by one
8. Click "Save"

## Step 3: Enable Phone Authentication

1. In Firebase Console, navigate to "Authentication" in the left sidebar
2. Click on the "Sign-in method" tab
3. Find "Phone" in the list of sign-in providers
4. Click the pencil icon to edit the settings
5. Toggle the switch to enable Phone Authentication
6. Click "Save"

## Step 4: Testing Phone Authentication

For testing during development:

1. Go to Authentication > Phone in Firebase Console
2. Scroll down to "Phone numbers for testing" 
3. Add test phone numbers for development (e.g., +1 234-567-8910)
4. For these test numbers, you can specify a verification code that will be automatically used

## Troubleshooting

If phone authentication is not working:

1. Verify that you've added the correct SHA keys to Firebase
2. Make sure your app is properly connected to Firebase
3. Check that you have the latest Firebase dependencies in your app
4. Ensure that the package name in Firebase matches your app's package name
5. Check Firebase console logs for any error messages
6. Make sure you have a valid billing account set up in Firebase

## Notes

- SHA-1 and SHA-256 keys are different for debug and release builds
- Always add both debug and release SHA keys to Firebase
- When publishing to Google Play, you may need to add the upload certificate SHA-1 fingerprint to Firebase
- If you're using CI/CD, you'll need to configure the keys appropriately for your build environment 
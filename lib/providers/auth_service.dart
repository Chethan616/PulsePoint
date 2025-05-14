import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user exists in Firestore
  Future<bool> checkIfUserExists(String userId) async {
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print("Error checking user existence: $e");
      return false;
    }
  }

  // Send verification code to phone number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    Function(PhoneAuthCredential)? onVerificationCompleted,
    Function(String)? onCodeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted:
          onVerificationCompleted ?? (PhoneAuthCredential credential) {},
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout:
          onCodeAutoRetrievalTimeout ?? (String verificationId) {},
      timeout: timeout,
      forceResendingToken: resendToken,
    );
  }

  // Verify OTP and sign in
  Future<UserCredential> verifyOTPAndSignIn(
      String verificationId, String otp) async {
    // Create a PhoneAuthCredential with the code
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    // Sign in the user with the credential
    return await _auth.signInWithCredential(credential);
  }

  // Create user profile in Firestore after successful authentication
  Future<void> createUserProfile({
    required String userId,
    required String phoneNumber,
    String? name,
    String? email,
    String? bloodType,
    String? address,
    String? photoURL,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'bloodType': bloodType,
      'address': address,
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete user account and all associated data
  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user is currently signed in');

      final String userId = user.uid;

      // 1. Delete profile picture from storage if it exists
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${userId}.jpg');
        await storageRef.delete();
      } catch (e) {
        // Ignore if file doesn't exist
        print('Storage delete error (might be ok): $e');
      }

      // 2. Delete all user data in Firestore collections

      // 2.1 Delete user blood requests
      final bloodRequestsQuery = await _firestore
          .collection('blood_requests')
          .where('authorId', isEqualTo: userId)
          .get();

      for (var doc in bloodRequestsQuery.docs) {
        // Delete all replies in the blood request
        final repliesQuery = await _firestore
            .collection('blood_requests')
            .doc(doc.id)
            .collection('replies')
            .get();

        for (var replyDoc in repliesQuery.docs) {
          await _firestore
              .collection('blood_requests')
              .doc(doc.id)
              .collection('replies')
              .doc(replyDoc.id)
              .delete();
        }

        // Delete the blood request document
        await _firestore.collection('blood_requests').doc(doc.id).delete();
      }

      // 2.2 Delete user chat conversations
      final conversationsQuery = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in conversationsQuery.docs) {
        // Delete all messages in the conversation
        final messagesQuery = await _firestore
            .collection('conversations')
            .doc(doc.id)
            .collection('messages')
            .get();

        for (var messageDoc in messagesQuery.docs) {
          await _firestore
              .collection('conversations')
              .doc(doc.id)
              .collection('messages')
              .doc(messageDoc.id)
              .delete();
        }

        // Delete the conversation document
        await _firestore.collection('conversations').doc(doc.id).delete();
      }

      // 2.3 Delete user activities
      final activitiesQuery = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in activitiesQuery.docs) {
        await _firestore.collection('activities').doc(doc.id).delete();
      }

      // 2.4 Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // 3. Finally, delete the authentication user
      await user.delete();
    } catch (e) {
      print('Error deleting user account: $e');
      throw e;
    }
  }
}

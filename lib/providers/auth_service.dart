import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}

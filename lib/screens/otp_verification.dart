import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pulsepoint_v2/screens/home_screen.dart'; // Import HomeScreen if the user is already logged in
import 'package:pulsepoint_v2/screens/signup_screen.dart';

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;

  OTPVerificationPage({required this.verificationId});

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isResending = false;
  bool isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF4338CA),
              Color(0xFF312E81),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            SizedBox(height: 40),
            _buildOTPForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedSwitcher(
      duration: Duration(seconds: 1),
      child: CircleAvatar(
        key: ValueKey(isUnlocked),
        radius: 60,
        backgroundColor: Colors.transparent,
        child: Icon(
          isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOTPForm(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 25),
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              hintText: 'Enter OTP',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              counterText: '',
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              PhoneAuthCredential credential = PhoneAuthProvider.credential(
                verificationId: widget.verificationId,
                smsCode: otpController.text,
              );
              await _auth
                  .signInWithCredential(credential)
                  .then((userCredential) async {
                User? user = userCredential.user;
                if (user != null) {
                  setState(() => isUnlocked = true);
                  await Future.delayed(Duration(seconds: 2));
                  bool userExists = await _checkIfUserExists(user.uid);
                  if (userExists) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  }
                }
              }).catchError((e) {
                print("Error during OTP verification: \$e");
              });
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Color(0xFF4F46E5),
              backgroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Verify',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(width: 10),
                Icon(Icons.check_rounded),
              ],
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: isResending
                ? null
                : () async {
                    setState(() => isResending = true);
                    await _auth.verifyPhoneNumber(
                      phoneNumber: "Your Phone Number",
                      verificationCompleted:
                          (PhoneAuthCredential credential) {},
                      verificationFailed: (FirebaseAuthException e) {
                        print("Verification Failed: \${e.message}");
                      },
                      codeSent: (String verificationId, int? resendToken) {
                        setState(() => isResending = false);
                      },
                      codeAutoRetrievalTimeout: (String verificationId) {},
                    );
                  },
            child: Text(
              isResending ? 'Resending...' : 'Resend OTP',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkIfUserExists(String userId) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.exists;
    } catch (e) {
      print("Error checking user existence: \$e");
      return false;
    }
  }
}

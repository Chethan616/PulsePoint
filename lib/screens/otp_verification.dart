import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:pulsepoint_v2/screens/home_screen.dart'; // Import HomeScreen if the user is already logged in
import 'package:pulsepoint_v2/screens/signup_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';

class OTPVerificationPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  OTPVerificationPage({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isResending = false;
  bool isVerifying = false;
  bool isSuccess = false;
  bool hasError = false;
  String errorMessage = '';
  int _countdown = 30;
  Timer? _timer;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _restartCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 30;
    });
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ]
                  : [
                      Color(0xFFFF5F6D),
                      Color(0xFFFF8068),
                      Color(0xFFFFC371),
                    ],
            ),
          ),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.06),
                  _buildHeader(isDark, colorScheme),
                  SizedBox(height: size.height * 0.05),
                  _buildOTPForm(context, isDark, colorScheme),
                  SizedBox(height: size.height * 0.03),
                  _buildResendButton(isDark),
                  SizedBox(height: size.height * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        if (isSuccess)
          Lottie.network(
            'https://assets3.lottiefiles.com/packages/lf20_m9Jt8f.json', // Blood donation success animation
            width: 150,
            height: 150,
            controller: _animationController,
            onLoaded: (composition) {
              _animationController.forward();
            },
            frameRate: FrameRate.max,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
              );
            },
          )
        else
          isDark
              ? Lottie.network(
                  'https://assets5.lottiefiles.com/private_files/lf30_e0rywva2.json', // Blood drop dark mode
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.primary.withOpacity(0.2)
                            : Color(0xFFFF5F6D).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bloodtype,
                        color: isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                        size: 80,
                      ),
                    );
                  },
                )
              : Lottie.network(
                  'https://assets3.lottiefiles.com/packages/lf20_tbjbheqa.json', // Blood donation light mode
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF5F6D).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bloodtype,
                        color: Color(0xFFFF5F6D),
                        size: 80,
                      ),
                    );
                  },
                ),
        SizedBox(height: 20),
        Text(
          'Verification',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          "We've sent a verification code to",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            widget.phoneNumber,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPForm(
      BuildContext context, bool isDark, ColorScheme colorScheme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth -
        74; // 25px horizontal padding on each side + 24px container padding on each side
    final fieldWidth = (availableWidth / 6) -
        8; // Divide by 6 digits and subtract some spacing

    return Container(
      padding: EdgeInsets.symmetric(vertical: 35, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 1,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.message,
                color: isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Enter your OTP code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 28),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: otpController,
            keyboardType: TextInputType.number,
            textStyle: TextStyle(
              color: isDark ? Colors.white : Color(0xFF333333),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            animationType: AnimationType.scale,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: 55,
              fieldWidth: fieldWidth,
              activeFillColor: isDark ? Color(0xFF2A2A2A) : Colors.white,
              inactiveFillColor: isDark ? Color(0xFF252525) : Colors.grey[100],
              selectedFillColor: isDark ? Color(0xFF2A2A2A) : Colors.white,
              activeColor: isDark ? colorScheme.primary : Color(0xFFFF5F6D),
              inactiveColor: isDark ? Colors.grey[700] : Colors.grey[300],
              selectedColor: isDark ? colorScheme.primary : Color(0xFFFF5F6D),
            ),
            animationDuration: Duration(milliseconds: 300),
            enableActiveFill: true,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                hasError = false;
                errorMessage = '';
              });
            },
            beforeTextPaste: (text) {
              return true;
            },
          ),
          if (hasError)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              margin: const EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: isVerifying || isSuccess
                ? null
                : () async {
                    if (otpController.text.length != 6) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        hasError = true;
                        errorMessage = 'Please enter all 6 digits';
                      });
                      return;
                    }

                    setState(() {
                      isVerifying = true;
                      hasError = false;
                    });

                    try {
                      PhoneAuthCredential credential =
                          PhoneAuthProvider.credential(
                        verificationId: widget.verificationId,
                        smsCode: otpController.text,
                      );

                      UserCredential userCredential =
                          await _auth.signInWithCredential(credential);
                      User? user = userCredential.user;

                      if (user != null) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          isVerifying = false;
                          isSuccess = true;
                        });

                        // Wait for animation to complete
                        await Future.delayed(Duration(seconds: 2));

                        // Check if user exists in Firestore
                        bool userExists = await _checkIfUserExists(user.uid);
                        if (userExists) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()),
                          );
                        }
                      }
                    } catch (e) {
                      HapticFeedback.vibrate();
                      setState(() {
                        isVerifying = false;
                        hasError = true;
                        errorMessage = 'Invalid OTP. Please try again.';
                      });
                      print("Error during OTP verification: $e");
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? colorScheme.primary : Color(0xFFFF5F6D),
              foregroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 56),
              disabledBackgroundColor: isDark
                  ? colorScheme.primary.withOpacity(0.5)
                  : Color(0xFFFF5F6D).withOpacity(0.5),
            ),
            child: isVerifying
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Verify',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendButton(bool isDark) {
    return Column(
      children: [
        Text(
          _countdown > 0
              ? "Didn't receive the code?"
              : "Didn't receive any code?",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        TextButton.icon(
          onPressed: (_countdown == 0 && !isResending && !isSuccess)
              ? () async {
                  HapticFeedback.lightImpact();
                  setState(() {
                    isResending = true;
                  });

                  try {
                    await _auth.verifyPhoneNumber(
                      phoneNumber: widget.phoneNumber,
                      verificationCompleted:
                          (PhoneAuthCredential credential) {},
                      verificationFailed: (FirebaseAuthException e) {
                        setState(() {
                          isResending = false;
                          hasError = true;
                          errorMessage = 'Could not resend code: ${e.message}';
                        });
                      },
                      codeSent: (String verificationId, int? resendToken) {
                        setState(() {
                          isResending = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('OTP has been sent again!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _restartCountdown();
                      },
                      codeAutoRetrievalTimeout: (String verificationId) {},
                    );
                  } catch (e) {
                    setState(() {
                      isResending = false;
                    });
                    print("Error resending OTP: $e");
                  }
                }
              : null,
          icon: Icon(
            Icons.refresh_rounded,
            color: _countdown == 0 && !isResending && !isSuccess
                ? Colors.white
                : Colors.white60,
            size: 18,
          ),
          label: Text(
            _countdown > 0
                ? 'Resend code in $_countdown seconds'
                : isResending
                    ? 'Sending...'
                    : 'Resend code',
            style: TextStyle(
              color: _countdown == 0 && !isResending && !isSuccess
                  ? Colors.white
                  : Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
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
      print("Error checking user existence: $e");
      return false;
    }
  }
}

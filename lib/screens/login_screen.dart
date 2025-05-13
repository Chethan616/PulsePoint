import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pulsepoint_v2/app_preferences_screens/privacy_policy_screen.dart';
import 'package:pulsepoint_v2/screens/home_screen.dart';
import 'package:pulsepoint_v2/screens/otp_verification.dart';
import 'package:pulsepoint_v2/screens/signup_screen.dart';
import 'package:provider/provider.dart';
import 'package:pulsepoint_v2/providers/theme_provider.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String completePhoneNumber = '+91';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkUserData(User? user, BuildContext context) async {
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
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
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.06),
                      _buildLogo(isDark),
                      SizedBox(height: 40),
                      _buildWelcomeText(isDark),
                      SizedBox(height: 50),
                      _buildLoginForm(size, isDark, colorScheme),
                      SizedBox(height: 30),
                      _buildFooter(isDark, colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Lottie.network(
          isDark
              ? 'https://assets4.lottiefiles.com/packages/lf20_tutvdkg0.json' // Heart pulse animation for dark mode
              : 'https://assets10.lottiefiles.com/packages/lf20_mzbdc6a4.json', // Blood donation animation for light mode
          height: 180,
          width: 180,
          repeat: true,
          animate: true,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20),
        Text(
          "PulsePoint",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black.withOpacity(0.3),
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Connecting lives through blood donation",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Sign in to continue saving lives',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(Size size, bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntlPhoneField(
                controller: phoneController,
                initialCountryCode: 'IN',
                onChanged: (phone) {
                  completePhoneNumber = phone.completeNumber;
                },
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                dropdownTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade50,
                  hintText: 'Enter your phone number',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      if (phoneController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please enter a valid phone number"),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                isDark ? colorScheme.error : Color(0xFFFF5F6D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        await _auth.verifyPhoneNumber(
                          phoneNumber: completePhoneNumber,
                          verificationCompleted:
                              (PhoneAuthCredential credential) async {
                            await _auth
                                .signInWithCredential(credential)
                                .then((userCredential) {
                              _checkUserData(userCredential.user, context);
                            });
                          },
                          verificationFailed: (FirebaseAuthException e) {
                            print("Verification Failed: ${e.message}");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(e.message ?? "Verification failed"),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: isDark
                                    ? colorScheme.error
                                    : Color(0xFFFF5F6D),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          codeSent: (String verificationId, int? resendToken) {
                            setState(() {
                              _isLoading = false;
                            });
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => OTPVerificationPage(
                                  verificationId: verificationId,
                                  phoneNumber: completePhoneNumber,
                                ),
                              ),
                            );
                          },
                          codeAutoRetrievalTimeout: (String verificationId) {
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          timeout: Duration(seconds: 60),
                        );
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "An error occurred. Please try again later."),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                isDark ? colorScheme.error : Color(0xFFFF5F6D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          isDark ? colorScheme.primary : Color(0xFFFF5F6D),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(height: 16),
        Text(
          'By continuing, you agree to our',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => PrivacyPolicyPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              '•',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: isDark ? Color(0xFF1F1F1F) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => Container(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'By using PulsePoint, you agree to our terms of service and privacy policy. We are committed to protecting your data and ensuring the best experience for all our users.',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: isDark
                                  ? colorScheme.primary
                                  : Color(0xFFFF5F6D),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'I Agree',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

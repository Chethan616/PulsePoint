import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactUsPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitQuery(BuildContext context) async {
    final String name = nameController.text.trim();
    final String message = messageController.text.trim();
    final User? user = _auth.currentUser;

    if (name.isEmpty || message.isEmpty) {
      _showSnackBar(
          context, 'Please fill in both name and message', Colors.red);
      return;
    }

    try {
      // Save to Firestore queries collection
      await _firestore.collection('queries').add({
        'name': name,
        'message': message,
        'phoneNumber': user?.phoneNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Send email
      await _sendEmail(name, message);

      _showSnackBar(context, 'Message submitted successfully!', Colors.green);

      // Clear text fields after successful submission
      nameController.clear();
      messageController.clear();
    } catch (e) {
      _showSnackBar(
          context, 'Error submitting message: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _sendEmail(String name, String message) async {
    final String email = 'chethankrishna2022@gmail.com';
    final String subject = 'Message from $name';
    final String body = 'Hello, $message';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(emailUri)) {
      try {
        await launchUrl(emailUri);
      } catch (e) {
        print('Error launching email: $e');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Contact Us'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 30),
            _buildContactForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We\'d Love to Hear From You!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Whether you have a question, feedback, or just want to say hello, feel free to reach out.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                prefixIcon: Icon(Icons.person, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Your Message',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.message, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _submitQuery(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Send Message',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

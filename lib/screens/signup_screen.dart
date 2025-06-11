// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Copyright (C) 2025  Author Name

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulsepoint/screens/home_screen.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController healthaddictionsController =
      TextEditingController();
  late TextEditingController phoneController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  String? bloodType;
  String? gender;
  Position? _currentPosition;
  File? _profileImage;

  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = Color(0xFFE53935);
  final Color _backgroundColor = Color(0xFFF5F5F5);
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    final authUser = FirebaseAuth.instance.currentUser;
    phoneController = TextEditingController(text: authUser?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    zipCodeController.dispose();
    ageController.dispose();
    healthaddictionsController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar("❌ Error picking image: ${e.toString()}");
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar("⚠️ Location services are disabled. Please enable them.");
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("⚠️ Location permissions are denied.");
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("❌ Location permissions are permanently denied.");
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _showSnackBar("✅ Location fetched successfully!");
    } catch (e) {
      _showSnackBar("❌ Error fetching location: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    if (nameController.text.isEmpty ||
        bloodType == null ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        zipCodeController.text.isEmpty ||
        _currentPosition == null) {
      _showSnackBar("⚠️ Please fill all required fields and enable location.");
      return;
    }

    setState(() => _isSaving = true);
    User? user = FirebaseAuth.instance.currentUser;

    try {
      String? profileImageUrl;
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pics/${user!.uid}.jpg');

        await storageRef.putFile(_profileImage!);
        profileImageUrl = await storageRef.getDownloadURL();
      }

      await _firestore.collection("users").doc(user!.uid).set({
        "name": nameController.text,
        "gender": gender,
        "bloodType": bloodType,
        "height": heightController.text,
        "weight": weightController.text,
        "age": ageController.text,
        "phoneNumber": user.phoneNumber ?? 'Not provided',
        "healthAddictions": healthaddictionsController.text,
        "profileImageUrl": profileImageUrl,
        "location": {
          "latitude": _currentPosition!.latitude,
          "longitude": _currentPosition!.longitude,
          "zipCode": zipCodeController.text,
        },
      });

      _showSnackBar("✅ Profile saved successfully!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      _showSnackBar("❌ Error saving profile: ${e.toString()}");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complete Your Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, Color(0xFFEF5350)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : Container(
              color: _backgroundColor,
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: _primaryColor.withOpacity(0.2),
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: Stack(
                              children: [
                                if (_profileImage == null)
                                  Center(
                                    child: Icon(Icons.camera_alt,
                                        size: 40, color: _primaryColor),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit,
                                        size: 20, color: _primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('Tap to add profile picture',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 20),
                        _buildSectionHeader(
                            "Personal Information", Icons.person),
                        _buildInputCard(
                          child: TextFormField(
                            controller: nameController,
                            decoration:
                                _inputDecoration("Username", Icons.person),
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildInputCard(
                          child: DropdownButtonFormField<String>(
                            value: gender,
                            items: ["Male", "Female", "Other"]
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => gender = value),
                            decoration:
                                _inputDecoration("Gender", Icons.transgender),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildSectionHeader("Health Details", Icons.favorite),
                        _buildInputCard(
                          child: DropdownButtonFormField<String>(
                            value: bloodType,
                            items: [
                              "A+",
                              "A-",
                              "B+",
                              "B-",
                              "O+",
                              "O-",
                              "AB+",
                              "AB-"
                            ]
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => bloodType = value),
                            decoration:
                                _inputDecoration("Blood Type", Icons.opacity),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildInputCard(
                          child: TextFormField(
                            controller: healthaddictionsController,
                            decoration: _inputDecoration(
                                "Health Details (Optional: allergies, conditions)",
                                Icons.healing),
                            maxLines: 2,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputCard(
                                child: TextFormField(
                                  controller: heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                      "Height (cm)", Icons.straighten),
                                  validator: (value) =>
                                      value!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildInputCard(
                                child: TextFormField(
                                  controller: weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                      "Weight (kg)", Icons.monitor_weight),
                                  validator: (value) =>
                                      value!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildSectionHeader("Location", Icons.location_on),
                        _buildLocationStatusCard(),
                        SizedBox(height: 10),
                        _buildInputCard(
                          child: TextFormField(
                            controller: zipCodeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("Zip Code", Icons.map),
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildInputCard(
                          child: TextFormField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDecoration("Age", Icons.calendar_today),
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildInputCard(
                          child: TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+()-]')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration:
                                _inputDecoration("Phone Number", Icons.phone),
                            validator: (value) {
                              if (FirebaseAuth
                                      .instance.currentUser?.phoneNumber !=
                                  null) return null;
                              if (value!.isEmpty) return 'Required';
                              final phoneRegExp = RegExp(
                                  r'^\+?[0-9]{1,4}?[-. ]?\(?[0-9]{1,3}?\)?[-. ]?[0-9]{1,4}[-. ]?[0-9]{1,4}[-. ]?[0-9]{1,9}$');
                              if (!phoneRegExp.hasMatch(value))
                                return 'Enter valid phone number';
                              return null;
                            },
                            readOnly: FirebaseAuth
                                    .instance.currentUser?.phoneNumber !=
                                null,
                          ),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveUserData,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Text("SAVE PROFILE",
                                style: TextStyle(fontSize: 16)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              )),
        ],
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: child,
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Location status:",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            if (_isLoadingLocation)
              CircularProgressIndicator()
            else
              Text(_currentPosition == null
                  ? "Not available"
                  : "Location acquired"),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _primaryColor, width: 1),
      ),
    );
  }
}


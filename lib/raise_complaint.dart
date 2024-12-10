import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class RauseComplaint extends StatefulWidget {
  const RauseComplaint({super.key});

  @override
  State<RauseComplaint> createState() => _RauseComplaintState();
}

class _RauseComplaintState extends State<RauseComplaint> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subtypeController = TextEditingController();
  String? _complaintType;
  bool hideContact = false;
  List<XFile>? files = [];
  bool isLoading = false;
  String? currentAddress;
  String? photoLocation;

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _complaintController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _subtypeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (files == null || files!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get the user's current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latitude = position.latitude;
      final longitude = position.longitude;

      // Prepare complaint data
      final complaintData = {
        'complaintDescription': _complaintController.text,
        'landmark': _landmarkController.text,
        'phone': hideContact ? 'Hidden' : _phoneController.text,
        'complaintType': _complaintType,
        'complaintSubtype': _subtypeController.text,
        'address': currentAddress ?? 'No address available',
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'userEmail': hideContact ? 'Hidden' : currentUser?.email,
        'status': 'Pending',
      };

      // Save the complaint to Firestore
      final complaintDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .collection('complaints')
          .add(complaintData);

      // Add images as sub-collection
      for (var file in files!) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('complaints')
            .doc(complaintDoc.id)
            .collection('images')
            .add({'path': file.path});
      }

      // Check for nearby complaints within 100 to 80 meters
      await _checkNearbyComplaints(latitude, longitude);

      // Clear form after submission
      setState(() {
        _complaintController.clear();
        _landmarkController.clear();
        _phoneController.clear();
        _subtypeController.clear();
        _complaintType = null;
        files = [];
        currentAddress = null;
        hideContact = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint Submitted Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkNearbyComplaints(double latitude, double longitude) async {
    try {
      // Query Firestore for complaints within 100 to 80 meters radius
      final complaintsQuery = await FirebaseFirestore.instance
          .collectionGroup('complaints')
          .where('status', isEqualTo: 'Pending')
          .get();

      int nearbyComplaintsCount = 0;
      for (var doc in complaintsQuery.docs) {
        final complaintData = doc.data();
        final docLatitude = complaintData['latitude'];
        final docLongitude = complaintData['longitude'];

        // Calculate distance between current complaint and existing complaints
        double distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          docLatitude,
          docLongitude,
        );

        // If within 100 to 80 meters, consider it as a nearby complaint
        if (distance >= 80 && distance <= 100) {
          nearbyComplaintsCount++;
        }
      }

      // If more than 6 complaints in the area, mark as heatmap
      if (nearbyComplaintsCount > 6) {
        await FirebaseFirestore.instance
            .collection('heatmap')
            .doc('$latitude,$longitude')
            .set({
          'complaintsCount': nearbyComplaintsCount,
          'latitude': latitude,
          'longitude': longitude,
          'status': 'Heatmap',
        });
      }
    } catch (e) {
      print('Error checking nearby complaints: $e');
    }
  }

  Future<void> _captureImageAndGetLocation() async {
    final picker = ImagePicker();
    if (files!.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 2 images.')),
      );
      return;
    }

    try {
      // Capture the image using the camera
      final capturedFile = await picker.pickImage(source: ImageSource.camera);

      if (capturedFile != null) {
        // Fetch the current location
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final latitude = position.latitude;
        final longitude = position.longitude;

        // Get address from the coordinates
        String address = await getAddress(latitude, longitude);

        // Update the UI with the fetched address
        setState(() {
          photoLocation = address;
          currentAddress = address;
        });

        // Add the image path and location data to Firestore
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('images')
              .add({
            'path': capturedFile.path,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // Update the local UI with the captured image
        setState(() {
          files?.add(capturedFile);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image and location saved successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<String> getAddress(double lat, double long) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, long);
      final place = placemarks[0];
      return "${place.locality}, ${place.subLocality}, ${place.street}, ${place.postalCode}";
    } catch (e) {
      return 'Unable to fetch address.';
    }
  }

  void _removeImage(int index) {
    setState(() {
      files!.removeAt(index);
      photoLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildImageSection(),
                if (photoLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF442C2E)),
                        Expanded(
                          child: Text(
                            photoLocation!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                _buildDetailsFrame(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _captureImageAndGetLocation,
        backgroundColor: const Color(0xFFFEDBD0),
        child: isLoading
            ? const CircularProgressIndicator(color: Color(0xFF442C2E))
            : const Icon(Icons.camera_alt, color: Color(0xFF442C2E)),
      ),
    );
  }

  Widget _buildImageSection() {
    return files!.isEmpty
        ? Center(
            child: GestureDetector(
              onTap: _captureImageAndGetLocation,
              child: Text(
                'Upload Image',
                style: TextStyle(
                  fontFamily: 'Amaranth',  // Set Amaranth font
                  fontSize: 18,
                  color: Color(0xFF442C2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        : Column(
            children: [
              // Display images side by side if there are two images
              Row(
                children: List.generate(files!.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Image.file(
                        File(files![index].path),
                        width: 150,  // Resize image to fit in a row
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
  }

  Widget _buildDetailsFrame() {
    return Column(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _complaintController,
                decoration: const InputDecoration(labelText: 'Complaint Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a complaint description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(labelText: 'Landmark (optional)'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                keyboardType: TextInputType.phone,
              ),
              DropdownButtonFormField<String>(
                value: _complaintType,
                decoration: const InputDecoration(labelText: 'Complaint Type'),
                onChanged: (value) {
                  setState(() {
                    _complaintType = value;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Electricity',
                    child: Text('Electricity'),
                  ),
                  DropdownMenuItem(
                    value: 'Water Supply',
                    child: Text('Water Supply'),
                  ),
                  DropdownMenuItem(
                    value: 'Street Light',
                    child: Text('Street Light'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF442C2E),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Complaint'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

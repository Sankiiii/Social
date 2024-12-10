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
  String? photoLocation; // To store location of the clicked image

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
    if (files!.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 3 images.')),
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
        photoLocation = await getAddress(latitude, longitude);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEDBD0),
        title: const Text(
          'Raise Complaint',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF442C2E),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildImageFrame(),
                const SizedBox(height: 20),
                _buildDetailsFrame(),
                if (photoLocation != null)
                  Text(
                    'Photo Location: $photoLocation',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF442C2E)),
                  ),
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

  Widget _buildImageFrame() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE3DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Uploaded Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amaranth',
              color: Color(0xFF442C2E),
            ),
          ),
          const SizedBox(height: 10),
          if (files != null && files!.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              itemCount: files!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(files![index].path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            )
          else
            const Text('No images uploaded yet.'),
        ],
      ),
    );
  }

  Widget _buildDetailsFrame() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE3DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextInput(
              controller: _complaintController,
              label: 'Complaint Description',
              hint: 'Enter your complaint details...',
            ),
            const SizedBox(height: 10),
            _buildDropdown(),
            const SizedBox(height: 10),
            _buildTextInput(
              controller: _subtypeController,
              label: 'Complaint Subtype',
              hint: 'Enter complaint subtype...',
            ),
            const SizedBox(height: 10),
            _buildTextInput(
              controller: _landmarkController,
              label: 'Nearest Landmark',
              hint: 'Enter the nearest landmark...',
            ),
            const SizedBox(height: 10),
            _buildTextInput(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number...',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                  return 'Enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (currentAddress != null)
              Text('Address: $currentAddress'),
            Row(
              children: [
                Switch(
                  value: hideContact,
                  onChanged: (value) => setState(() => hideContact = value),
                ),
                const Text('Hide Contact Details'),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF442C2E),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _complaintType,
      onChanged: (value) {
        setState(() {
          _complaintType = value;
        });
      },
      items: [
        'Water',
        'Road',
        'Waste Management',
        'Electronics',
        'Others'
      ]
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      decoration: const InputDecoration(
        labelText: 'Complaint Type',
        border: OutlineInputBorder(),
      ),
    );
  }
}

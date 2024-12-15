import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime_type/mime_type.dart';
import 'dart:convert';

class RauseComplaint extends StatefulWidget {
  const RauseComplaint({Key? key}) : super(key: key);

  @override
  State<RauseComplaint> createState() => _RauseComplaintState();
}

class _RauseComplaintState extends State<RauseComplaint> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _complaintType;
  String? _complaintSubtype;
  bool hideContact = false;
  List<XFile> files = [];
  bool isLoading = false;
  String? currentAddress;
  String? _locationError;

  final String pinataApiKey = '2dfc4e3fec850909b6e1';
  final String pinataApiSecret = '3a9b9b71f1d65bf68349049b5316af65a7f48642b281edb9f2aaf7672402080c';
  
  @override
  void dispose() {
    _complaintController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Enhanced error handling for network connectivity
  Future<bool> _checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Comprehensive error handling for location permissions
  Future<bool> _checkLocationPermissions() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  // Enhanced image upload with comprehensive error handling
  Future<String?> uploadImageToPinata(File imageFile) async {
    try {
      // Check internet connectivity before upload
      if (!await _checkInternetConnectivity()) {
        _showErrorSnackBar('No internet connection. Please check your network.');
        return null;
      }

      final uri = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
      final request = http.MultipartRequest('POST', uri)
        ..headers['pinata_api_key'] = pinataApiKey
        ..headers['pinata_secret_api_key'] = pinataApiSecret
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final jsonResponse = jsonDecode(responseData.body);
        return jsonResponse['IpfsHash'];
      } else {
        _showErrorSnackBar('Failed to upload image. Please try again.');
        return null;
      }
    } catch (e) {
      _showErrorSnackBar('Unexpected error during image upload: $e');
      return null;
    }
  }

  // Comprehensive location fetching with multiple error scenarios
  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _locationError = null;
      isLoading = true;
    });

    try {
      // Check location permissions
      if (!await _checkLocationPermissions()) {
        setState(() {
          _locationError = 'Location permissions denied';
          isLoading = false;
        });
        return;
      }

      // Check internet connectivity
      if (!await _checkInternetConnectivity()) {
        setState(() {
          _locationError = 'No internet connection';
          isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final address = await getAddress(position.latitude, position.longitude);
      
      setState(() {
        currentAddress = address;
        _locationError = null;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Location fetch timed out';
      });
    } catch (e) {
      setState(() {
        _locationError = 'Unable to fetch location: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Improved address fetching with more robust error handling
  Future<String> getAddress(double lat, double long) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, long);
      final place = placemarks[0];
      return "${place.locality ?? ''}, ${place.subLocality ?? ''}, ${place.subThoroughfare ?? ''}, ${place.postalCode ?? ''}".trim();
    } catch (e) {
      return 'Unable to fetch precise address';
    }
  }

  // Submit complaint form with enhanced error handling
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check internet connectivity
    if (!await _checkInternetConnectivity()) {
      _showErrorSnackBar('No internet connection. Please check your network.');
      return;
    }

    if (files.isEmpty) {
      _showErrorSnackBar('Please upload at least one image!');
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('You need to be logged in to raise a complaint!');
        return;
      }

      final userId = currentUser.uid;

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
        'complaintSubtype': _complaintSubtype,
        'address': currentAddress ?? 'No address available',
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'anonymous': false, // Default value
        'status': 'Pending',
      };

      // Save the complaint to Firestore under the logged-in user's collection
      final complaintDoc = await FirebaseFirestore.instance
          .collection('users/$userId/complaints')
          .add(complaintData);

      // Upload images to Pinata and store the CID in Firestore
      for (var file in files) {
        final imageFile = File(file.path);
        final cid = await uploadImageToPinata(imageFile);

        if (cid != null) {
          // Add the CID of the image to Firestore
          await FirebaseFirestore.instance
              .collection('users/$userId/complaints')
              .doc(complaintDoc.id)
              .collection('images')
              .add({'cid': cid});
        }
      }

      // Clear form after successful submission
      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint Submitted Successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2), // Display duration of the SnackBar
      ),
    );

    // Navigate to the other page after the SnackBar is shown
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamed(context, 'complaints');
    });
    } catch (e) {
      _showErrorSnackBar('Error submitting complaint: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Image capture with enhanced error handling
  Future<void> _captureImage() async {
    if (files.length >= 2) {
      _showErrorSnackBar('You can upload a maximum of 2 images!');
      return;
    }

    final picker = ImagePicker();
    try {
      final capturedFile = await picker.pickImage(source: ImageSource.camera);

      if (capturedFile != null) {
        // Check location permissions and internet connectivity
        if (!await _checkLocationPermissions() || 
            !await _checkInternetConnectivity()) {
          _showErrorSnackBar('Please enable location and internet to capture image.');
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final latitude = position.latitude;
        final longitude = position.longitude;

        String address = await getAddress(latitude, longitude);

        setState(() {
          files.add(capturedFile);
          currentAddress = address;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error capturing image: $e');
    }
  }

  // Reset form to initial state
  void _resetForm() {
    setState(() {
      _complaintController.clear();
      _landmarkController.clear();
      _phoneController.clear();
      _complaintType = null;
      _complaintSubtype = null;
      files.clear();
      currentAddress = null;
      hideContact = false;
    });
  }

  // Remove image from the list
  void _removeImage(int index) {
    setState(() {
      files.removeAt(index);
    });
  }

  // Get subtypes based on complaint type
  List<String> _getSubtypesForComplaintType() {
    switch (_complaintType) {
      case 'Solid Waste Management':
        return ['Garbage Dumping', 'Overflowing Bins', 'Uncollected Waste'];
      case 'Damaged Infrastructure':
        return ['Road Damage', 'Public Property'];
      case 'Road Pot Holes':
        return ['Minor Potholes', 'Major Potholes'];
      default:
        return [];
    }
  }

  // Custom error snackbar for consistent error messaging
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFEDBD0),
        title: Text(
          'Raise Complaint',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF442C2E),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFEEAE6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Upload Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: files.isNotEmpty ? Colors.green.shade200 : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: files
                              .asMap()
                              .entries
                              .map(
                                (entry) => Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(entry.value.path),
                                        height: 150,
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.red.withOpacity(0.7),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => _removeImage(entry.key),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                        if (files.length < 2)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: _captureImage,
                              child: Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 50,
                                        color: Colors.grey.shade600,
                                      ),
                                      Text(
                                        'Upload Image',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Location Section
                  if (_locationError != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationError!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                 if (currentAddress != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Location: $currentAddress',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ElevatedButton.icon(
                    onPressed: _fetchCurrentLocation,
                    icon: const Icon(Icons.location_searching),
                    label: const Text('Fetch Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Complaint Description
                  TextFormField(
                    controller: _complaintController,
                    decoration: InputDecoration(
                      labelText: 'Complaint Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a complaint description';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Landmark (Optional)
                  TextFormField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      labelText: 'Landmark (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      // Basic phone number validation
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Please enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Complaint Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _complaintType,
                    decoration: InputDecoration(
                      labelText: 'Complaint Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _complaintType = value;
                        _complaintSubtype = null; // Reset subtype when type changes
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'Solid Waste Management',
                        child: Text('Solid Waste Management'),
                      ),
                      DropdownMenuItem(
                        value: 'Damaged Infrastructure',
                        child: Text('Damaged Infrastructure'),
                      ),
                      DropdownMenuItem(
                        value: 'Road Pot Holes',
                        child: Text('Road Pot Holes'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a complaint type';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Complaint Subtype Dropdown (Conditional)
                  if (_complaintType != null)
                    DropdownButtonFormField<String>(
                      value: _complaintSubtype,
                      decoration: InputDecoration(
                        labelText: 'Complaint Subtype',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _complaintSubtype = value;
                        });
                      },
                      items: _getSubtypesForComplaintType().map((subtype) {
                        return DropdownMenuItem(
                          value: subtype,
                          child: Text(subtype),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a complaint subtype';
                        }
                        return null;
                      },
                    ),

                  const SizedBox(height: 20),

                  // Hide Contact Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hide Contact Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch.adaptive(
                        value: hideContact,
                        onChanged: (value) {
                          setState(() {
                            hideContact = value;
                          });
                        },
                        activeColor: Colors.green.shade400,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Submit Complaint',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
}
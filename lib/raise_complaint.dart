import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime_type/mime_type.dart';
import 'dart:convert';

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
  String? _complaintType;
  String? _complaintSubtype;
  bool hideContact = false;
  List<XFile> files = [];
  bool isLoading = false;
  String? currentAddress;

  final String pinataApiKey = '2dfc4e3fec850909b6e1';
  final String pinataApiSecret = '3a9b9b71f1d65bf68349049b5316af65a7f48642b281edb9f2aaf7672402080c';
  
  @override
  void dispose() {
    _complaintController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<String> uploadImageToPinata(File imageFile) async {
    final uri = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
    final request = http.MultipartRequest('POST', uri)
      ..headers['pinata_api_key'] = pinataApiKey
      ..headers['pinata_secret_api_key'] = pinataApiSecret
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final jsonResponse = jsonDecode(responseData.body);
      return jsonResponse['IpfsHash']; // This is the CID of the image
    } else {
      throw Exception('Failed to upload image to Pinata');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to raise a complaint!')),
        );
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

        // Add the CID of the image to Firestore
        await FirebaseFirestore.instance
            .collection('users/$userId/complaints')
            .doc(complaintDoc.id)
            .collection('images')
            .add({'cid': cid});
      }

      // Clear form after submission
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

  Future<void> _captureImage() async {
    if (files.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can upload a maximum of 2 images!')),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final capturedFile = await picker.pickImage(source: ImageSource.camera);

      if (capturedFile != null) {
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
          const SnackBar(content: Text('Image captured successfully!')),
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
      return "${place.locality}, ${place.subLocality}, ${place.thoroughfare}, ${place.postalCode}";
    } catch (e) {
      return 'Unable to fetch address.';
    }
  }

  void _removeImage(int index) {
    setState(() {
      files.removeAt(index);
    });
  }

  List<String> _getSubtypesForComplaintType() {
    if (_complaintType == 'Solid Waste Management') {
      return ['Garbage Dumping', 'Overflowing Bins', 'Uncollected Waste'];
    }
    return []; // No subtypes for other complaint types
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      backgroundColor: const Color(0xFFFEEAE6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                            Image.file(
                              File(entry.value.path),
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeImage(entry.key),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                if (files.length < 2)
                  GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('Upload Image', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (currentAddress != null)
                  Text(
                    'Location: $currentAddress',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _complaintController,
                        decoration: const InputDecoration(
                          labelText: 'Complaint Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a complaint description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _landmarkController,
                        decoration: const InputDecoration(
                          labelText: 'Landmark (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _complaintType,
                        decoration: const InputDecoration(
                          labelText: 'Complaint Type',
                          border: OutlineInputBorder(),
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
                            child: Text('Damaged Infrastructure (Coming Soon)', style: TextStyle(color: Colors.grey)),
                          ),
                          DropdownMenuItem(
                            value: 'Road Pot Holes',
                            child: Text('Road Pot Holes (Coming Soon)', style: TextStyle(color: Colors.grey)),
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
                      if (_complaintType != null)
                        DropdownButtonFormField<String>(
                          value: _complaintSubtype,
                          decoration: const InputDecoration(
                            labelText: 'Complaint Subtype',
                            border: OutlineInputBorder(),
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
                      Row(
                        children: [
                          const Text('Hide Contact'),
                          Switch(
                            value: hideContact,
                            onChanged: (value) {
                              setState(() {
                                hideContact = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

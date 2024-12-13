import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "Loading...";
  String profilePicUrl = ""; // This will store the profile image CID
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  bool isOffline = false; // Flag to track if the user is offline

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkConnectivity();
    _checkPendingImageUploads();
  }

  // Check internet connectivity
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
      });
    } else {
      setState(() {
        isOffline = false;
      });
    }
  }

  // Check if there are any pending local image uploads when the app is back online
  Future<void> _checkPendingImageUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final localImagePath = prefs.getString('localProfilePicPath');
    if (localImagePath != null && localImagePath.isNotEmpty) {
      _uploadPendingImage(File(localImagePath));
    }
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        username = userDoc.data()?['username'] ?? "Unknown User";
        profilePicUrl = userDoc.data()?['profilePic'] ?? ''; // Get profile picture CID
      });
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'username': newUsername,
      });
      setState(() {
        username = newUsername;
      });
    }
  }

  Future<void> _updateProfilePicture(File image) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    setState(() {
      isUploading = true;  // Start uploading
    });
    
    try {
      if (isOffline) {
        // Save image locally if the user is offline
        _saveImageLocally(image);
        // Show a snackbar or alert to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No internet connection. Image saved locally.')),
        );
      } else {
        // Step 1: Upload to Pinata (Image Uploading Function)
        String cid = await _uploadToPinata(image);

        // Step 2: Update Firestore with new profile picture CID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePic': cid,
        });
        setState(() {
          profilePicUrl = cid; // Update the profile picture URL (CID)
        });
      }
    } catch (e) {
      // Handle upload failure (show a message, retry, etc.)
      print('Error uploading image: $e');
    } finally {
      setState(() {
        isUploading = false;  // End uploading
      });
    }
  }
}

  Future<String> _uploadToPinata(File image) async {
    String apiUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
    
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    
    request.headers.addAll({
      'pinata_api_key': '2dfc4e3fec850909b6e1',
      'pinata_secret_api_key': '3a9b9b71f1d65bf68349049b5316af65a7f48642b281edb9f2aaf7672402080c',
    });
    
    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(responseBody);
      return jsonResponse['IpfsHash'];  // Return IPFS hash from the response
    } else {
      throw Exception('Failed to upload image to Pinata');
    }
  }

  void _saveImageLocally(File image) async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming you save the path as a string for later retrieval
    await prefs.setString('localProfilePicPath', image.path);
  }

  Future<void> _uploadPendingImage(File image) async {
    // Try uploading the pending image once the internet is available
    try {
      String cid = await _uploadToPinata(image);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePic': cid,
        });
        setState(() {
          profilePicUrl = cid;
        });
      }
      // Remove the saved path after upload
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('localProfilePicPath');
    } catch (e) {
      // Handle upload error (show a message, retry, etc.)
      print('Error uploading pending image: $e');
    }
  }

  void _showEditUsernameDialog() {
    TextEditingController usernameController = TextEditingController(text: username);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Username'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(hintText: 'Enter new username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateUsername(usernameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                Navigator.pushReplacementNamed(context, 'loading');
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      await _updateProfilePicture(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF442C2E),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Profile Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF442C2E),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  // Circle Avatar for Profile Picture (using CID from Firestore)
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // Display CircularProgressIndicator if uploading
                      isUploading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey,
                              backgroundImage: profilePicUrl.isNotEmpty
                                  ? NetworkImage('https://gateway.pinata.cloud/ipfs/$profilePicUrl')
                                  : const AssetImage('assets/images/profile_placeholder1.png') as ImageProvider,
                            ),
                      // IconButton for picking a new image
                      IconButton(
                        icon: const Icon(Icons.add_a_photo, color: Colors.white, size: 30),
                        onPressed: _pickImage,
                        splashRadius: 25,
                        tooltip: 'Change Profile Picture',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _showEditUsernameDialog,
                    child: const Text(
                      'Edit Username',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Options Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ProfileOptionCard(
                    icon: Icons.person_add,
                    title: 'Invite Friends',
                    onTap: () {
                      // Navigate to Invite Friends
                    },
                  ),
                  const SizedBox(height: 10),
                  ProfileOptionCard(
                    icon: Icons.info,
                    title: 'About Us',
                    onTap: () {
                      // Navigate to About Us
                    },
                  ),
                  const SizedBox(height: 10),
                  ProfileOptionCard(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () {
                      // Navigate to Support
                    },
                  ),
                  const SizedBox(height: 10),
                  ProfileOptionCard(
                    icon: Icons.logout,
                    title: 'Log Out',
                    onTap: _showLogoutConfirmationDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Card Widget for Profile Options
class ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileOptionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF442C2E), size: 30),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF442C2E),
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

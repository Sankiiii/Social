import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "Loading...";
  String profilePicUrl = ""; // This will store the profile image CID
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
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
  }

 Future<String> _uploadToPinata(File image) async {
  // Pinata API URL for uploading
  String apiUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  
  var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
  
  // Add API key (Make sure to replace these with your actual Pinata API keys)
  request.headers.addAll({
    'pinata_api_key': 'YOUR_PINATA_API_KEY',
    'pinata_secret_api_key': 'YOUR_PINATA_SECRET_API_KEY',
  });
  
  // Add image to the request
  request.files.add(await http.MultipartFile.fromPath('file', image.path));
  
  // Send the request
  var response = await request.send();
  var responseBody = await response.stream.bytesToString();

  // Decode the response body as JSON
  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(responseBody);  // Decode the response body
    return jsonResponse['IpfsHash'];  // Extract the IpfsHash from the JSON response
  } else {
    throw Exception('Failed to upload image to Pinata');
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
    // Pick an image from gallery or camera
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
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    backgroundImage: profilePicUrl.isNotEmpty
                        ? NetworkImage('https://gateway.pinata.cloud/ipfs/$profilePicUrl')
                        : const AssetImage('assets/images/profile_placeholder1.png') as ImageProvider,
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
                  // Button to Change Profile Picture
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text(
                      'Change Profile Picture',
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

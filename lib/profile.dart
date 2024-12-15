import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "Loading...";
  String profilePicUrl = ""; 
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;
  bool isOffline = false;

  final String pinataApiKeyO= '2dfc4e3fec850909b6e1';
  final String pinataApiSecretO = '3a9b9b71f1d65bf68349049b5316af65a7f48642b281edb9f2aaf7672402080c';
  
  // New error handling variables
  String errorMessage = "";
  bool isErrorVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeProfileData();
  }

  // Consolidated initialization method
  Future<void> _initializeProfileData() async {
    try {
      await _checkConnectivity();
      await _fetchUserProfile();
      await _checkPendingImageUploads();
    } catch (e) {
      _showErrorSnackBar('Failed to initialize profile: ${e.toString()}');
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _checkPendingImageUploads() async {
    final prefs = await SharedPreferences.getInstance();
    final localImagePath = prefs.getString('localProfilePicPath');
    if (localImagePath != null && localImagePath.isNotEmpty) {
      try {
        await _uploadPendingImage(File(localImagePath));
      } catch (e) {
        _showErrorSnackBar('Failed to upload pending image: ${e.toString()}');
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          username = userDoc.data()?['username'] ?? "Unknown User";
          profilePicUrl = userDoc.data()?['profilePic'] ?? ''; 
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching user profile: ${e.toString()}');
    }
  }

  // Enhanced error handling methods
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateUsername(String newUsername) async {
    if (newUsername.isEmpty) {
      _showErrorSnackBar('Username cannot be empty');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'username': newUsername});
        
        setState(() {
          username = newUsername;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update username: ${e.toString()}');
    }
  }

  Future<void> _updateProfilePicture(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      if (isOffline) {
        _saveImageLocally(image);
        _showErrorSnackBar('No internet. Image saved locally.');
      } else {
        String cid = await _uploadToPinata(image);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePic': cid});
        
        setState(() {
          profilePicUrl = cid;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Image upload failed: ${e.toString()}');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<String> _uploadToPinata(File image) async {
  const String apiUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  const String pinataApiKey = '2dfc4e3fec850909b6e1' ;// Replace with a secure source
  const String pinataApiSecret = '3a9b9b71f1d65bf68349049b5316af65a7f48642b281edb9f2aaf7672402080c'; // Replace with a secure source

  try {
    // Connectivity check (optional but recommended)
    if (!(await _checkInternetConnectivity())) {
      throw Exception('No internet connection. Please check your network.');
    }

    // Create the multipart request
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..headers.addAll({
        'pinata_api_key': pinataApiKey,
        'pinata_secret_api_key': pinataApiSecret,
      })
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    // Send the request
    var response = await request.send();

    // Process the response
    var responseBody = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(responseBody);
      if (jsonResponse.containsKey('IpfsHash')) {
        return jsonResponse['IpfsHash'];
      } else {
        throw Exception('Unexpected response format. Missing IpfsHash.');
      }
    } else {
      throw Exception(
          'Failed to upload image to Pinata. Status code: ${response.statusCode}, Response: $responseBody');
    }
  } catch (e) {
    // Log and rethrow for better error tracing
    print('Error during Pinata upload: $e');
    throw Exception('Error during Pinata upload: $e');
  }
}

  void _saveImageLocally(File image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('localProfilePicPath', image.path);
  }

  Future<void> _uploadPendingImage(File image) async {
    try {
      String cid = await _uploadToPinata(image);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePic': cid});
        
        setState(() {
          profilePicUrl = cid;
        });
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('localProfilePicPath');
    } catch (e) {
      _showErrorSnackBar('Error uploading pending image: ${e.toString()}');
    }
  }

  Future<bool> _checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      await _updateProfilePicture(image);
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
            decoration: const InputDecoration(
              hintText: 'Enter new username',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF442C2E)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF442C2E))),
            ),
            ElevatedButton(
              onPressed: () {
                _updateUsername(usernameController.text);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF442C2E),
              ),
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
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF442C2E))),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                Navigator.pushReplacementNamed(context, 'loading');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF442C2E),
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Profile', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: const Color(0xFF442C2E),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _initializeProfileData,
        color: const Color(0xFF442C2E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF442C2E),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ]
                ),
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(height: 15),
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _showEditUsernameDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Edit Username'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
              )
            ]
          ),
          child: isUploading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profilePicUrl.isNotEmpty
                      ? CachedNetworkImageProvider(
                          'https://gateway.pinata.cloud/ipfs/$profilePicUrl'
                        )
                      : const AssetImage('assets/images/profile_placeholder1.png') 
                          as ImageProvider,
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                )
              ]
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF442C2E)),
              onPressed: _pickImage,
              tooltip: 'Change Profile Picture',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ProfileOptionCard(
            icon: Icons.person_add,
            title: 'Invite Friends',
            onTap: () {
              // Implement invite friends functionality
              _showErrorSnackBar('Feature coming soon!');
            },
          ),
          const SizedBox(height: 10),
          ProfileOptionCard(
            icon: Icons.info,
            title: 'About Us',
            onTap: () {
              // Implement about us page
              _showErrorSnackBar('Feature coming soon!');
            },
          ),
          const SizedBox(height: 10),
          ProfileOptionCard(
            icon: Icons.support_agent,
            title: 'Support',
            onTap: () {
              // Implement support page
              _showErrorSnackBar('Feature coming soon!');
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
    );
  }
}

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
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
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
                const Icon(
                  Icons.arrow_forward_ios, 
                  color: Colors.grey, 
                  size: 18
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Utility function for showing loading dialogs
void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF442C2E)),
        ),
      );
    },
  );
}

// Custom Alert Dialog Widget
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.message,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF442C2E),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel!();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF442C2E)),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF442C2E),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// Enhanced User Profile Model
class UserProfile {
  final String username;
  final String profilePicUrl;
  final String email;
  final DateTime createdAt;

  UserProfile({
    required this.username,
    required this.profilePicUrl,
    required this.email,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      username: data['username'] ?? 'Unknown User',
      profilePicUrl: data['profilePic'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'profilePic': profilePicUrl,
      'email': email,
      'createdAt': createdAt,
    };
  }
}

// Image Upload Service
class ImageUploadService {
  static Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      // Implement image compression logic
      final compressedFile = await _compressImage(imageFile);
      
      // Upload to Pinata or your preferred service
      // Implement actual upload logic here
      return null; // Return the image URL or CID
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  static Future<File> _compressImage(File file) async {
    // Implement image compression 
    // You might want to use packages like flutter_image_compress
    return file;
  }
}

// Connectivity Service
class ConnectivityService {
  static Future<bool> checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Stream<List<ConnectivityResult>> watchConnectivity() {
    return Connectivity().onConnectivityChanged;
  }
}

// Privacy Settings Model
class PrivacySettings {
  bool profileVisibility;
  bool emailVisibility;
  bool activityTracking;

  PrivacySettings({
    this.profileVisibility = true,
    this.emailVisibility = false,
    this.activityTracking = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility,
      'emailVisibility': emailVisibility,
      'activityTracking': activityTracking,
    };
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      profileVisibility: map['profileVisibility'] ?? true,
      emailVisibility: map['emailVisibility'] ?? false,
      activityTracking: map['activityTracking'] ?? true,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "Loading..."; // Placeholder before fetching

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
                // Navigate to the Login page
                Navigator.pushReplacementNamed(context, 'login');
              },
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
                  // Circle Avatar for Profile Picture (Removed Upload Option)
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    backgroundImage: AssetImage('assets/images/profile_placeholder1.png'),
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

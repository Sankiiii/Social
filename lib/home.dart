import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:design_model/view_complaint.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
}



// Complaint model class
class Complaint {
  final String id;
  final String complaintType;
  final String status;
  final String imagePath;
  final String landmark;
  final bool hotComplaint;

  Complaint({
    required this.id,
    required this.complaintType,
    required this.status,
    required this.imagePath,
    required this.landmark,
    required this.hotComplaint,
  });

  // Factory constructor to create Complaint from Firestore document
  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Complaint(
      id: doc.id,
      complaintType: data['complaintType'] ?? 'No complaint type available',
      status: data['status'] ?? 'No status available',
      imagePath: data['images'] ?? 'assets/images/hot4.jpg',
      landmark: data['landmark'] ?? 'No landmark available',
      hotComplaint: data['hotComplaint'] ?? false,
    );
  }
}

// Home Screen StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentCarouselIndex = 0;
  int _notificationCount = 0;

  List<Complaint> complaints = []; // To store complaints fetched from Firestore
  bool _isLoading = true;
  String _errorMessage = '';

  // Method to fetch complaint details from Firestore
  Future<void> fetchComplaintDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User is not logged in');
      }

      // Path to the complaints collection for the logged-in user
      CollectionReference complaintsCollection = firestore
          .collection('users')
          .doc(user.uid)
          .collection('complaints');

      // Query to get complaints with hotComplaint set to true
      QuerySnapshot querySnapshot = await complaintsCollection
          .where('hotComplint', isEqualTo: true)
          .get();

      // Check if there are any complaints in the result
      if (querySnapshot.docs.isNotEmpty) {
        List<Complaint> fetchedComplaints = querySnapshot.docs
            .map((doc) => Complaint.fromFirestore(doc))
            .toList();

        // Update state with the fetched complaints
        setState(() {
          complaints = fetchedComplaints;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No hot complaints found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching complaints: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch data when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchComplaintDetails();
      // _fetchNotificationCount();
    });
  }

  // Image list for carousel
  final List<String> imageList = [
    'assets/images/image1.jpg',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
    'assets/images/image4.jpg',
    'assets/images/image5.jpg',
    'assets/images/image6.jpg'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildSliverAppBar(),
          
          // Body Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildOurResultsSection(),
                _buildQuickActionsSection(),
                _buildHotComplaintsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build SliverAppBar
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'City Complaint Portal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: "Amaranth",
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black45,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // City background image
            Image.asset(
              'assets/images/city_background.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildNotificationAndProfileIcons(),
      ],
    );
  }

  // Build Notification and Profile Icons
  Widget _buildNotificationAndProfileIcons() {
    return Row(
      children: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.pushNamed(context, 'notification');
              },
            ),
            Positioned(
              top: 5,
              right: 5,
              child: _notificationCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.person,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            Navigator.pushNamed(context, 'profile');
          },
        ),
      ],
    );
  }

  // Build Our Results Section
  Widget _buildOurResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Our Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontFamily: "Amaranth"
            ),

          ),
        ),
        // Carousel Slider
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: CarouselSlider.builder(
            itemCount: imageList.length,
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.85,
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              return _buildCarouselItem(index);
            },
          ),
        ),
        // Carousel Indicator
        _buildCarouselIndicator(),
      ],
    );
  }

  // Build Carousel Item
  Widget _buildCarouselItem(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imageList[index],
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Text(
                  'Before        After ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Amaranth"
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Carousel Indicator
  Widget _buildCarouselIndicator() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: imageList.map((url) {
          int index = imageList.indexOf(url);
          return Container(
            width: 10.0,
            height: 10.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentCarouselIndex == index
                  ? Colors.deepPurple
                  : Colors.grey,
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontFamily: "Amaranth"
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
  children: [
   _buildQuickActionButton(
  icon: CupertinoIcons.list_bullet,
  label: 'My Complaints',
  onTap: () {
    Navigator.pushNamed(context, 'complaints');
  },
),
const SizedBox(width: 16),

_buildQuickActionButton(
  icon: CupertinoIcons.exclamationmark_circle, // Replace with any other icon you prefer
  label: 'Raise Complaints',
  onTap: () {
    Navigator.pushNamed(context, 'raise');
  },
),

const SizedBox(width: 16),
_buildQuickActionButton(
  icon: CupertinoIcons.bell,
  label: 'Notifications',
  onTap: () {
    Navigator.pushNamed(context, 'notification');
  },
  // textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 14), // Updated font family
),
  ],
),
          ),
        ],
      ),
    );
  }

  // Build Hot Complaints Section
  Widget _buildHotComplaintsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hot Complaints',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,fontFamily: "Amaranth"
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red,fontFamily: "Amaranth")
                      ),
                    )
                  : complaints.isEmpty
                      ? Center(
                          child: Text(
                            'No hot complaints found',
                            style: TextStyle(color: Colors.grey,fontFamily: "Amaranth"),
                          ),
                        )
                      : Column(
                          children: complaints
                              .map((complaint) => _buildComplaintCard(complaint))
                              .toList(),
                        ),
        ],
      ),
    );
  }

  // Quick Action Button Widget
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.deepPurple,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,fontFamily: "Amaranth"
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Complaint Card Widget
  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          complaint.complaintType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,fontFamily: "Amaranth"
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${complaint.status}',
              style: TextStyle(
                color: _getStatusColor(complaint.status),fontFamily: "Amaranth"
              ),
            ),
            Text('Landmark: ${complaint.landmark}'),
          ],
        ),
        leading: _buildComplaintImage(complaint.imagePath),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
          onPressed: () {
            _navigateToComplaintDetails(complaint.id);
          },
        ),
      ),
    );
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Build Complaint Image with error handling
  Widget _buildComplaintImage(String imagePath) {
    return Container(
    width: 80, // Set the width to 80 pixels
    height: 80, // Set the height to 80 pixels
    child: Image.asset(
      "assets/images/hot3.jpeg", // Use the imagePath provided
      fit: BoxFit.cover, // Ensure the image covers the container proportionally
    ),
  );
  }

//  Navigate to Complaint Details
 void _navigateToComplaintDetails(String complaintId) {
  Navigator.push(
    context, // Add the missing comma here
    MaterialPageRoute(
      builder: (context) => ComplaintDetailsScreen(complaintId: complaintId),
    ),
  );
}

}
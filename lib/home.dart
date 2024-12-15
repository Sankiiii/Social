import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Complaint model class
class Complaint {
  final String title;
  final String status;
  final String imagePath;
  final Color statusColor;

  Complaint({
    required this.title,
    required this.status,
    required this.imagePath,
    required this.statusColor,
  });
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

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
  }

  // Method to fetch notification count from Firestore
  void _fetchNotificationCount() async {
    try {
      // Replace 'userId' with actual user authentication logic
      final userDoc = FirebaseFirestore.instance.collection('users').doc('userId');
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        setState(() {
          _notificationCount = docSnapshot.data()?['notificationCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
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

  // Complaints list
  final List<Complaint> complaints = [
    Complaint(
      title: 'Garbage Dumping',
      status: 'Pending',
      imagePath: 'assets/images/hot1.jpeg',
      statusColor: Colors.orange,
    ),
    Complaint(
      title: 'Overflowing Bins',
      status: 'In Progress',
      imagePath: 'assets/images/hot2.jpeg',
      statusColor: Colors.blue,
    ),
    Complaint(
      title: 'Uncollected Waste',
      status: 'Hot Complaint',
      imagePath: 'assets/images/hot3.jpeg',
      statusColor: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'City Complaint Portal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
              // Notification Icon with Badge
              Row(
                children: [
                  Stack(
                    children: [
                      Positioned(
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, 'notification');
                          },
                        ),
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          left: 10,
                          top: 5,
                          child: Container(
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
                          ),
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
              ),
            ],
          ),
          // Body Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                      const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Our Results',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
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
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Carousel Indicator
                Center(
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
                ),
                
                // Quick Action Buttons
                Padding(
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickActionButton(
                              icon: CupertinoIcons.add,
                              label: 'Raise Complaint',
                              onTap: () {
                                Navigator.pushNamed(context, 'raise');
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildQuickActionButton(
                              icon: CupertinoIcons.list_bullet,
                              label: 'My Complaints',
                              onTap: () {
                                Navigator.pushNamed(context, 'complaints');
                              },
                            ),
                            const SizedBox(width: 16),
                            _buildQuickActionButton(
                              icon: CupertinoIcons.bell,
                              label: 'Notifications',
                              onTap: () {
                                Navigator.pushNamed(context, 'notification');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Hot Complaints Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hot Complaints',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...complaints
                          .map((complaint) => _buildComplaintCard(complaint))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
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
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
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
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            complaint.imagePath,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          complaint.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        subtitle: Text(
          complaint.status,
          style: TextStyle(
            color: complaint.statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: complaint.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'View',
            style: TextStyle(
              color: complaint.statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
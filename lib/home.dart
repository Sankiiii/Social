import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Import for Carousel
import 'package:flutter/cupertino.dart';
import 'package:design_model/raise_complaint.dart';
import 'package:design_model/complaint.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample images for the slider
    final List<String> imageList = [
      'assets/images/image1.jpg', // Replace with your image paths
      'assets/images/image2.jpg',
      'assets/images/image3.jpg',
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Image Slider
          CarouselSlider(
            items: imageList.map((item) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  item,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            }).toList(),
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Your Dashboard!',
            style: TextStyle(
              fontFamily: 'Amaranth',
              fontSize: 24,
              color: const Color(0xFF442C2E),
            ),
          ),
          const SizedBox(height: 20),
          // Hot Complaints Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEDBD0),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Hot Complaints',
                  style: TextStyle(
                    fontFamily: 'Amaranth',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF442C2E),
                  ),
                ),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5, // Example count
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/hot_complaint.jpg', // Replace with your image paths
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                          ),
                        ),
                        title: Text('Complaint #${index + 1}'),
                        subtitle: Text('Status: Hot Complaint'),
                        trailing: Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(),
    const RauseComplaint(), // Replace with your actual RaiseComplaint screen
    const MyComplaints(), // Replace with your actual MyComplaints screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // switch (index) {
    //   case 1:
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => const RauseComplaint()),
    //     );
    //     break;
    //   case 2:
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => const MyComplaints()),
    //     );
    //     break;
    //   default:
    //     break;
    // }
  }

  Future<bool> _onWillPop() async {
    final exit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              SystemNavigator.pop(); // Close the app
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEDBD0), // Set the background color of the app bar
        title: Text(
          'Home',
          style: TextStyle(
            fontFamily: 'Amaranth', // Set the font family to Amaranth
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: const Color(0xFF442C2E), // Font color set to #442C2E
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.home, color: Color(0xFF442C2E),size: 30.0), // Home icon with custom color
          onPressed: () {
            setState(() {
              _selectedIndex = 0; // Set to home tab when pressed
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: Color(0xFF442C2E),size: 30.0), // Bell icon with custom color
            onPressed: () {
              Navigator.pushNamed(context,'notification');
              print('Notification button pressed');
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.profile_circled, color: Color(0xFF442C2E),size: 30.0), // Search icon with custom color
            onPressed: () {
              Navigator.pushNamed(context,'profile');
              print('Search button pressed');
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFEDBD0),
        selectedItemColor: const Color(0xFF442C2E),
        unselectedItemColor: const Color(0xFF8D6E63),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add),
            label: 'Raise',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.exclamationmark_triangle),
            label: 'Complaints',
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Home(),
    ),
  );
}

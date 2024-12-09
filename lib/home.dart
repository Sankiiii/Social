import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import for Cupertino Icons
import 'raise_complaint.dart'; // Import RaiseComplaintScreen
import 'complaint.dart'; // Import ComplaintsScreen

// Define the Home screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home Page Content',
        style: TextStyle(
          fontFamily: 'Amaranth',
          fontSize: 18,
          color: Color(0xFF442C2E),
        ),
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
  int _selectedIndex = 0; // Index for the selected tab

  // List of pages to display for each tab
  final List<Widget> _pages = [
    const HomeScreen(),
    const RauseComplaint(),
    const MyComplaints(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected tab index
    });

    // Navigate to the corresponding screen based on the selected tab
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RauseComplaint()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyComplaints()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6), // Set the background color of the page
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
          icon: const Icon(CupertinoIcons.home, color: Color(0xFF442C2E)), // Home icon with custom color
          onPressed: () {
            setState(() {
              _selectedIndex = 0; // Set to home tab when pressed
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: Color(0xFF442C2E)), // Search icon with custom color
            onPressed: () {
              print('Search button pressed');
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.bell, color: Color(0xFF442C2E)), // Bell icon with custom color
            onPressed: () {
              print('Notification button pressed');
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the page based on the selected index
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFEDBD0), // Set background color for the bottom navigation bar
        selectedItemColor: const Color(0xFF442C2E), // Set selected item color
        unselectedItemColor: const Color(0xFF8D6E63), // Set unselected item color
        currentIndex: _selectedIndex, // Set the selected index
        onTap: _onItemTapped, // Handle tab change
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home), // Home icon
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add), // Raise icon
            label: 'Raise',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.exclamationmark_triangle), // Complaints icon
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
      home: Home(), // Set Home as the starting screen
    ),
  );
}

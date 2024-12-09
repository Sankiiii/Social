  import 'package:flutter/material.dart';

  class MyLoading extends StatefulWidget {
    const MyLoading({super.key});

    @override
    State<MyLoading> createState() => _MyLoadingState();
  }

  class _MyLoadingState extends State<MyLoading> {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDEBE7), // Background color
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Align content vertically in the center
            crossAxisAlignment: CrossAxisAlignment.center, // Align content horizontally in the center
            mainAxisSize: MainAxisSize.max, // Use the maximum available height
            children: [
              const Spacer(),
              // Image widget (loaded from assets)
              Image.asset(
                'assets/images/bg_load_img.png', // Replace with your image path in assets folder
                width: 400,
                height: 400,
              ),
              const SizedBox(height: 10),

              // Text widget for "SOCIAL"
              const Text(
                'SOCIAL',
                style: TextStyle(
                  fontFamily: 'Amaranth',
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF442C2E), // Font color set to #442C2E
                ),
              ),
              const SizedBox(height: 10),

              // Paragraph below "SOCIAL"
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'Your Voice for a Cleaner City!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amaranth',
                    fontSize: 16,
                    color: Color(0xFF442C2E), // Font color set to #442C2E
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space before button

              // Button widget
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'login');
                  print("Start Using button pressed");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEDBD0), // Button background color set to FEDBD0
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Padding for the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                ),
                child: const Text(
                  'Start Using → ',
                  style: TextStyle(
                    fontFamily: 'Amaranth',
                    fontSize: 18,
                    color: Color(0xFF442C2E), // Font color set to #442C2E
                  ),
                ),
              ),

              const SizedBox(height: 10), // Space before footer
              const Spacer(),
              // Footer section at the bottom
              const Text(
                'Powered by Mine64',
                style: TextStyle(
                  fontFamily: 'Amaranth',
                  fontSize: 14,
                  color: Color(0xFF442C2E), // Font color set to #442C2E
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

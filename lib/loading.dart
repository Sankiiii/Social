import 'package:flutter/material.dart';

class MyLoading extends StatefulWidget {
  const MyLoading({super.key});

  @override
  State<MyLoading> createState() => _MyLoadingState();
}

class _MyLoadingState extends State<MyLoading> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate a loading delay
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEBE7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              'assets/images/bg_load_img.png',
              width: 400,
              height: 400,
            ),
            const SizedBox(height: 10),
            const Text(
              'SOCIAL',
              style: TextStyle(
                fontFamily: 'Amaranth',
                fontSize: 70,
                fontWeight: FontWeight.bold,
                color: Color(0xFF442C2E),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Your Voice for a Cleaner City!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amaranth',
                  fontSize: 16,
                  color: Color(0xFF442C2E),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF442C2E))
                : ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDBD0),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Start Using → ',
                      style: TextStyle(
                        fontFamily: 'Amaranth',
                        fontSize: 18,
                        color: Color(0xFF442C2E),
                      ),
                    ),
                  ),
            const Spacer(),
            const Text(
              'Powered by Mine64',
              style: TextStyle(
                fontFamily: 'Amaranth',
                fontSize: 14,
                color: Color(0xFF442C2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

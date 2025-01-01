import 'package:flutter/material.dart';

class ComplaintDetail extends StatefulWidget {
  const ComplaintDetail({super.key});

  @override
  State<ComplaintDetail> createState() => _ComplaintDetailState();
}

class _ComplaintDetailState extends State<ComplaintDetail> {
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProfileHidden = false;
  String _complaintType = 'Replacement of missing/damaged manholes/inspection';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Detail'),
        backgroundColor: const Color(0xFF442C2E),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal scrollable images
              Container(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Image.asset(
                      'assets/images/image1.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      'assets/images/image2.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      'assets/images/image3.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Brief description of the complaint
              const Text(
                'Brief Description of the Complaint:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'The complaint is regarding the missing or damaged manholes '
                    'that need immediate replacement to prevent accidents.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Nearest landmark input
              const Text(
                'Nearest Landmark:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  hintText: 'Enter the nearest landmark',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),

              // Complaint type dropdown
              const Text(
                'Complaint Type:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButton<String>(
                  value: _complaintType,
                  items: [
                    'Replacement of missing/damaged manholes/inspection',
                    'Other complaint type 1',
                    'Other complaint type 2',
                  ]
                      .map((type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _complaintType = newValue!;
                    });
                  },
                  isExpanded: true,
                  underline: const SizedBox(),
                ),
              ),
              const SizedBox(height: 20),

              // Phone number input
              const Text(
                'Phone Number:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Toggle to hide the profile
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Hide My Profile:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _isProfileHidden,
                    onChanged: (bool value) {
                      setState(() {
                        _isProfileHidden = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



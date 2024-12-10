import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Complaint Status"),
          backgroundColor: const Color(0xFFFDEBE7),
        ),
        body: const Center(child: Text('Please log in to see your complaints.')),
      );
    }

    final String userId = user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Status"),
        backgroundColor: const Color(0xFFFDEBE7),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users')
                          .doc(userId)
                          .collection('complaints')
                          .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No complaints found.'));
          }

          var complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var complaintData = complaints[index];
              String status = complaintData['status'] ?? 'Unknown';
              String location = complaintData['address'] ?? 'Unknown Location';
              String complaintType = complaintData['complaintType'] ?? 'General';
              Timestamp time = complaintData['timestamp'] ?? Timestamp.now();
              IconData statusIcon;

              // Format time to hours and minutes
              DateTime complaintTime = time.toDate();
              String timeString = "${complaintTime.hour}:${complaintTime.minute.toString().padLeft(2, '0')}"; // Format time properly

              // Set different icons based on the complaint status
              if (status == 'Success') {
                statusIcon = Icons.check_circle_outline;
              } else if (status == 'Pending') {
                statusIcon = Icons.timer;
              } else if (status == 'In Progress') {
                statusIcon = Icons.build;
              } else {
                statusIcon = Icons.error_outline;
              }

              return Card(
                margin: const EdgeInsets.all(12.0),
                color: const Color(0xFFFDE3DC),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: _getStatusColor(status), size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis, // To handle long addresses
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "Type: $complaintType",
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            "Time: $timeString",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "Status: $status",
                            style: TextStyle(fontSize: 16, color: _getStatusColor(status)),
                          ),
                          const Spacer(),
                          // isAnonymous ? "Anonymous" : "Identified"
                          Text(
                            "Yoo",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Success') {
      return Colors.green;
    } else if (status == 'Pending') {
      return Colors.orange;
    } else if (status == 'In Progress') {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const NotificationPage(),
    ),
  );
}

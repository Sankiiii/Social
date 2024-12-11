import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          backgroundColor: const Color(0xFFFEDBD0),// const Color()
        ),
        body: const Center(child: Text('Please log in to see your complaints.')),
      );
    }

    final String userId = user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Status"),
        backgroundColor: const Color(0xFFFDEBE7),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              _clearAllNotifications(userId);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(userId)
            .collection('complaints')
            .where('status', whereIn: ['In Progress', 'Succeeded']) // Fetch both "In Progress" and "Succeeded"
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications available.'));
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
              String docId = complaintData.id;

              DateTime complaintTime = time.toDate();
              String timeString =
                  "${complaintTime.hour}:${complaintTime.minute.toString().padLeft(2, '0')}";

              // Determine the color based on status
              Color cardColor = status == 'Succeeded'
                  ? Colors.green
                  : (status == 'In Progress' ? Colors.blue : Colors.grey);
              IconData icon = status == 'Succeeded' ? Icons.check_circle_outline : Icons.build;
              Color iconColor = status == 'Succeeded' ? Colors.green : Colors.blue;

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _removeNotification(userId, docId);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.all(12.0),
                  color: cardColor.withOpacity(0.5), // Adjust opacity for visual appeal
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
                            Icon(
                              icon,
                              color: iconColor,
                              size: 40,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                        Text(
                          "Status: $status",
                          style: TextStyle(
                            fontSize: 16,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _removeNotification(String userId, String docId) {
    // Remove the specific notification from Firestore
    _firestore
        .collection('users')
        .doc(userId)
        .collection('complaints')
        .doc(docId)
        .delete();
  }

  void _clearAllNotifications(String userId) {
    // Remove all notifications with the given statuses from Firestore
    _firestore
        .collection('users')
        .doc(userId)
        .collection('complaints')
        .where('status', whereIn: ['In Progress', 'Succeeded'])
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
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

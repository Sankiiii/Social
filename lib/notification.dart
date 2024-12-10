import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore
import 'package:flutter/cupertino.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEDBD0),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: const Color(0xFF442C2E),
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.bell, color: Color(0xFF442C2E)),
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users/ 5EI3mRAtRtYderGdqtN4rSY3zKD2/complaints/DYsITEAzk6u83asXexU5 ').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No Notifications Yet!',
                  style: TextStyle(
                    fontFamily: 'Amaranth',
                    fontSize: 20,
                    color: Color(0xFF8D6E63),
                  ),
                ),
              );
            }

            final notifications = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final title = notification['title'] ?? 'No Title';
                final message = notification['message'] ?? 'No Message';
                final status = notification['status'] ?? 'Unknown Status';
                final isHotComplaint = notification['isHotComplaint'] ?? false;

                // If the status changes from 'Pending' to 'Success', show a notification
                if (status == 'Success') {
                  _showStatusChangeNotification(context, title, message);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isHotComplaint ? const Color(0xFFFFCDD2) : const Color(0xFFFEDBD0),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isHotComplaint ? Colors.red : Colors.blue,
                      child: Icon(
                        isHotComplaint ? CupertinoIcons.flame : CupertinoIcons.bell,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Amaranth',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF442C2E),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            fontFamily: 'Amaranth',
                            fontSize: 16,
                            color: Color(0xFF8D6E63),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontFamily: 'Amaranth',
                            fontSize: 14,
                            color: isHotComplaint ? Colors.red : const Color(0xFF442C2E),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(CupertinoIcons.right_chevron, color: Color(0xFF442C2E)),
                      onPressed: () {
                        // Navigate to detailed view or handle action
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Show a notification when the status changes from Pending to Success
  void _showStatusChangeNotification(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

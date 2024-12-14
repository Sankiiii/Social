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
  void initState() {
    super.initState();
    if (user != null) {
      _setupNotificationListener(user!.uid);
    }
  }

  void _setupNotificationListener(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('complaints')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var complaintData = change.doc.data();
          if (complaintData != null) {
            String status = complaintData['status'] ?? '';
            if (status == 'In Progress' || status == 'Succeeded') {
              _incrementNotificationCount(userId);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Complaint Status"),
          backgroundColor: const Color(0xFFFEDBD0),
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
          _buildNotificationBadge(userId),
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
            .where('status', whereIn: ['In Progress', 'Succeeded'])
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

              Color cardColor = status == 'Succeeded'
                  ? Colors.green
                  : (status == 'In Progress' ? Colors.blue : Colors.grey);
              IconData icon =
                  status == 'Succeeded' ? Icons.check_circle_outline : Icons.build;
              Color iconColor =
                  status == 'Succeeded' ? Colors.green : Colors.blue;

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
                  color: cardColor.withOpacity(0.5),
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

  Widget _buildNotificationBadge(String userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const SizedBox();
        }

        int notificationCount = snapshot.data!.get('notificationCount') ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications),
            if (notificationCount > 0)
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _removeNotification(String userId, String docId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('complaints')
        .doc(docId)
        .delete()
        .then((_) => _decrementNotificationCount(userId))
        .catchError((error) {
          debugPrint('Error removing notification: $error');
        });
  }

  void _clearAllNotifications(String userId) {
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
      _firestore.collection('users').doc(userId).update({'notificationCount': 0}).catchError((error) {
        debugPrint('Error clearing notifications: $error');
      });
    });
  }

  void _incrementNotificationCount(String userId) {
    _firestore.collection('users').doc(userId).update({
      'notificationCount': FieldValue.increment(1),
    }).catchError((error) {
      debugPrint('Error incrementing notification count: $error');
    });
  }

  void _decrementNotificationCount(String userId) {
    _firestore.collection('users').doc(userId).update({
      'notificationCount': FieldValue.increment(-1),
    }).catchError((error) {
      debugPrint('Error decrementing notification count: $error');
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

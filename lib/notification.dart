import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _setupNotificationListener(user!.uid);
    }
  }

  void _setupNotificationListener(String userId) {
    try {
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
    } catch (e) {
      _showErrorSnackBar('Error setting up notifications: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildLoginRequiredScreen();
    }

    final String userId = user!.uid;

    return Scaffold(
      appBar: _buildAppBar(userId),
      body: _buildNotificationBody(userId),
    );
  }

  Scaffold _buildLoginRequiredScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEDBD0), Color(0xFFFDF1F5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.pink,
              ),
              const SizedBox(height: 20),
              const Text(
                'Please Log In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You need to be logged in to view notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement login navigation
                  // Navigator.of(context).pushReplacement(...)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(String userId) {
    return AppBar(
      title: const Text(
        "Complaint Notifications",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      actions: [
        _buildNotificationBadge(userId),
        IconButton(
          icon: const Icon(Icons.clear_all, color: Colors.white),
          tooltip: 'Clear All Notifications',
          onPressed: () => _clearAllNotifications(userId),
        ),
      ],
    );
  }

  Widget _buildNotificationBody(String userId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {
                _errorMessage = '';
                _isLoading = true;
                // Retry loading notifications
              }),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('complaints')
          .where('status', whereIn: ['In Progress', 'Succeeded'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyNotificationsWidget();
        }

        var complaints = snapshot.data!.docs;

        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            var complaintData = complaints[index];
            return _buildNotificationCard(complaintData, userId);
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to load notifications: $errorMessage',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Trigger refresh
              setState(() {});
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotificationsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            color: Colors.grey,
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Active Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You have no pending or completed complaints at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to complaint submission page
              // Navigator.of(context).push(...)
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Submit a Complaint'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(DocumentSnapshot complaintData, String userId) {
    String status = complaintData['status'] ?? 'Unknown';
    String location = complaintData['address'] ?? 'Unknown Location';
    String complaintType = complaintData['complaintType'] ?? 'General';
    Timestamp time = complaintData['timestamp'] ?? Timestamp.now();
    String docId = complaintData.id;

    DateTime complaintTime = time.toDate();
    String formattedTime = DateFormat('hh:mm a').format(complaintTime);
    String formattedDate = DateFormat('dd MMM yyyy').format(complaintTime);

    Color cardColor = _getStatusColor(status);
    IconData icon = _getStatusIcon(status);
    Color iconColor = _getStatusIconColor(status);

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeNotification(userId, docId);
      },
      background: _buildDismissBackground(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: cardColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.category, complaintType),
                  _buildInfoChip(Icons.calendar_today, formattedDate),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Status: $status",
                    style: TextStyle(
                      fontSize: 16,
                      color: iconColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Time: $formattedTime",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.deepPurple),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      child: const Icon(
        Icons.delete,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Succeeded':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Succeeded':
        return Icons.check_circle_outline;
      case 'In Progress':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusIconColor(String status) {
    switch (status) {
      case 'Succeeded':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

 const Icon(Icons.notifications, size: 30),

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

 // Mark the notification as soft deleted in Firestore

 _firestore

.collection('users')

.doc(userId)

.update({'notificationCount': FieldValue.increment(-1)})

.then((_) {

_firestore

.collection('users')

.doc(userId)

.collection('complaints')

.doc(docId)

.update({'softDeleted': true});

})

.catchError((error) {

debugPrint('Error updating Firestore: $error');

});

 // Decrement the notification count but ensure it doesn't go below 0

 _firestore.collection('users').doc(userId).get().then((doc) {

int currentCount = doc.get('notificationCount') ?? 0;

if (currentCount > 0) {

_firestore.collection('users').doc(userId).update({

 'notificationCount': FieldValue.increment(-1),

}).catchError((error) {

 debugPrint('Error decrementing notification count: $error');

});

}

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

  // Keep the previous methods (_buildNotificationBadge, _removeNotification, _clearAllNotifications, _incrementNotificationCount) 
  // from the original code, as they remain mostly the same
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotificationPage(),
    ),
  );
}
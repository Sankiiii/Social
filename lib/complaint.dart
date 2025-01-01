import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting date

class MyComplaints extends StatefulWidget {
  const MyComplaints({super.key});

  @override
  State<MyComplaints> createState() => _MyComplaintsState();
}

class _MyComplaintsState extends State<MyComplaints> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> fetchComplaints() async {
    if (user == null) {
      return [];
    }
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users/${user!.uid}/complaints')
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id, // Add document ID for updates/deletions
        };
      }).toList();
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      return [];
    }
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users/${user!.uid}/complaints')
          .doc(id)
          .update({'status': status});
      setState(() {}); // Refresh the UI
    } catch (e) {
      debugPrint("Error updating complaint status: $e");
    }
  }

  void _showComplaintDetailsDialog(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Complaint Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.location_on, 'Address', complaint['address']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.label, 'Type', complaint['complaintType']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.label_important, 'Sub-Type', complaint['complaintSubtype']),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.description, 'Description', complaint['complaintDescription']),
              const SizedBox(height: 10),
              _buildDateTimeRow(complaint['timestamp']),
              const SizedBox(height: 10),
              _buildStatusDetailRow(complaint['status']),
              
              // Image Preview Section
              if (complaint['imageCID'] != null) ...[
                const SizedBox(height: 15),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      'https://ipfs.io/ipfs/${complaint['images']}',
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (complaint['status'] == 'Pending') 
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCancelConfirmationDialog(complaint['id']);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
              child: const Text('Cancel Complaint'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(String complaintId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Cancel Complaint'),
        content: const Text('Are you sure you want to cancel this complaint?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              updateComplaintStatus(complaintId, 'Canceled');
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Complaints',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.deepPurple.shade50,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'An error occurred while fetching complaints.',
                style: TextStyle(
                  fontFamily: 'Amaranth',
                  fontSize: 18,
                  color: Colors.red.shade700,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No complaints found for your account.',
                    style: TextStyle(
                      fontFamily: 'Amaranth',
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final complaints = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return GestureDetector(
                onTap: () => _showComplaintDetailsDialog(complaint),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.deepPurple.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.shade100,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                complaint['complaintType'] ?? 'Unknown Complaint',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusChip(complaint['status']),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          complaint['complaintDescription'] ?? 'No description provided',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        _buildDateTimeRow(complaint['timestamp']),
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

  Widget _buildDetailRow(IconData icon, String title, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$title: ${value ?? 'Not available'}',
            style: TextStyle(
              fontFamily: 'Amaranth',
              fontSize: 16,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(Timestamp? complaintTime) {
    if (complaintTime == null) {
      return const SizedBox.shrink();
    }
    
    DateTime dateTime = complaintTime.toDate();
    String formattedTime = DateFormat('hh:mm a').format(dateTime);
    String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);

    return Row(
      children: [
        Icon(Icons.calendar_today, color: Colors.deepPurple.shade700),
        const SizedBox(width: 10),
        Text(
          '$formattedDate at $formattedTime',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDetailRow(String? status) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline, color: _getStatusColor(status)),
        const SizedBox(width: 10),
        Text(
          'Status: ${status ?? 'Pending'}',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontSize: 16,
            color: _getStatusColor(status),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status ?? 'Pending',
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Succeeded':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
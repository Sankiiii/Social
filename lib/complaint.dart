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

  Future<void> deleteComplaint(String id, int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('users/${user!.uid}/complaints')
          .doc(id)
          .delete();
      setState(() {
        // Remove complaint from the list after deletion
      });
    } catch (e) {
      debugPrint("Error deleting complaint: $e");
    }
  }

  void _showImageDialog(BuildContext context, String imageCID) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 15,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://ipfs.io/ipfs/$imageCID',
                fit: BoxFit.contain,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.white, size: 50),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
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
            color: const Color(0xFF442C2E),
          ),
        ),
        backgroundColor: const Color(0xFFFEEAE6),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFEEAE6),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF442C2E)),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
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
                      _buildDetailRow(Icons.location_on, 'Address', complaint['address']),
                      const SizedBox(height: 10),
                      _buildDetailRow(Icons.label, 'Type', complaint['complaintType']),
                      const SizedBox(height: 10),
                      _buildDetailRow(Icons.label_important, 'Sub-Type', complaint['complaintSubType']),
                      const SizedBox(height: 10),
                      _buildDetailRow(Icons.description, 'Description', complaint['complaintDescription']),
                      const SizedBox(height: 10),
                      _buildStatusRow(complaint['status']),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        Icons.timer,
                        'Timestamp',
                        complaint['timestamp'] != null
                            ? DateFormat('yyyy-MM-dd – kk:mm').format(complaint['timestamp'].toDate())
                            : 'Not available',
                      ),
                      
                      // Image Preview Section
                      if (complaint['imageCID'] != null) ...[
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () => _showImageDialog(context, complaint['imageCID']),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                'https://ipfs.io/ipfs/${complaint['imageCID']}',
                                fit: BoxFit.cover,
                                height: 150,
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
                                    height: 150,
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
                        ),
                      ],
                      
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            text: 'Cancel',
                            color: Colors.orange,
                            onPressed: () {
                              updateComplaintStatus(complaint['id'], 'Canceled');
                            },
                          ),
                          _buildActionButton(
                            text: 'Delete',
                            color: Colors.red,
                            onPressed: () {
                              deleteComplaint(complaint['id'], index);
                              complaints.removeAt(index);
                              setState(() {});
                            },
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

  Widget _buildDetailRow(IconData icon, String title, String? value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF442C2E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$title: ${value ?? 'Not available'}',
            style: const TextStyle(
              fontFamily: 'Amaranth',
              fontSize: 16,
              color: Color(0xFF442C2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String? status) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF442C2E)),
        const SizedBox(width: 10),
        Text(
          'Status: ${status ?? 'Pending'}',
          style: TextStyle(
            fontFamily: 'Amaranth',
            fontSize: 16,
            color: status == 'Succeeded'
                   ? Colors.green
                   : status == 'Pending'
                       ? Colors.orange
                       : status == 'Canceled'
                           ? Colors.red
                           : status == 'In Progress'
                               ? Colors.blue
                               : Colors.yellow,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
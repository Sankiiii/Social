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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'An error occurred while fetching complaints.',
                style: TextStyle(
                  fontFamily: 'Amaranth',
                  fontSize: 18,
                  color: Color(0xFF442C2E),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No complaints found for your account.',
                style: TextStyle(
                  fontFamily: 'Amaranth',
                  fontSize: 18,
                  color: Color(0xFF442C2E),
                ),
              ),
            );
          }

          final complaints = snapshot.data!;
          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 8,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
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
                      const SizedBox(height: 15),
                      // Display the image from IPFS
                      complaint['imageCID'] != null
                          ? Image.network(
                              'https://ipfs.io/ipfs/${complaint['imageCID']}',
                              fit: BoxFit.cover,
                              height: 200, // Adjust height as needed
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  );
                                }
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                );
                              },
                            )
                          : const SizedBox.shrink(), // If no image CID, show nothing
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              updateComplaintStatus(complaint['id'], 'Canceled');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              deleteComplaint(complaint['id'], index);
                              complaints.removeAt(index);
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
}

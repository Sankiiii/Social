import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          .where('userEmail', isEqualTo: user!.email)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      return [];
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
              return GestureDetector(
                onTap: () {
                  // Action when the card is clicked
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
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
                        _buildDetailRow(
                            Icons.location_on, 'Address', complaint['address']),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.label, 'Type',
                            complaint['complaintType']),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.description, 'Description',
                            complaint['complaintDescription']),
                        const SizedBox(height: 10),
                        _buildStatusRow(complaint['status']),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.phone, 'Anonymous',
                            complaint['phone'] == 'Hidden' ? 'Yes' : 'No'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.timer, 'Timestamp',
                            complaint['timestamp']?.toDate()?.toString() ??
                                'Not available'),
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
            color: status == 'Succeeded' ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

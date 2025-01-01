import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// Complaint Model
class Complaint {
  final String id;
  final String complaintType;
  final String complaintSubType;
  final String status;
  final String address;
  final String landmark;
  final String phone;
  final String description;
  final List<String> images; // List of CIDs or URLs for images
  final bool isHotComplaint;

  Complaint({
    required this.id,
    required this.complaintType,
    required this.complaintSubType,
    required this.status,
    required this.address,
    required this.landmark,
    required this.phone,
    required this.description,
    required this.images,
    required this.isHotComplaint,
  });

  // Factory constructor to create Complaint from Firestore document
  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Complaint(
      id: doc.id,
      complaintType: data['complaintType'] ?? 'Not Specified',
      complaintSubType: data['complaintSubType'] ?? 'Not Specified',
      status: data['status'] ?? 'Pending',
      address: data['address'] ?? 'Not Provided',
      landmark: data['landmark'] ?? 'No Landmark',
      phone: data['phone'] ?? 'Not Available',
      description: data['complaintDescription '] ?? 'No Description Provided',
      images: List<String>.from(data['images'] ?? []), // CID list from Firestore
      isHotComplaint: data['hotComplint'] ?? false,
    );
  }
}

// Complaint Details Screen
class ComplaintDetailsScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailsScreen({
    super.key, 
    required this.complaintId,
  });

  @override
  _ComplaintDetailsScreenState createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  Complaint? _complaint;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();
  }

  Future<void> _fetchComplaintDetails() async {
    try {
      // Fetch the currently logged-in user's UID
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        setState(() {
          _errorMessage = 'User is not logged in';
          _isLoading = false;
        });
        return;
      }

      String userId = currentUser.uid;

      // Fetch complaint details from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('complaints')
          .doc(widget.complaintId)
          .get();

      if (doc.exists) {
        setState(() {
          _complaint = Complaint.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Complaint not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching complaint details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _buildComplaintDetails(),
    );
  }

  Widget _buildComplaintDetails() {
    if (_complaint == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images Section
          _buildImagesSection(),

          // Complaint Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complaint Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRows(),
                    const SizedBox(height: 16),
                    _buildDescriptionSection(),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        image: _complaint!.images.isNotEmpty
            ? DecorationImage(
                image: NetworkImage('https://gateway.pinata.cloud/ipfs/${_complaint!.images.first}'),
                fit: BoxFit.cover,
              )
            : const DecorationImage(
                image: AssetImage('assets/images/image6.jpg'),
                fit: BoxFit.cover,
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: _complaint!.images.length > 1
              ? ElevatedButton.icon(
                  onPressed: _showMoreImages,
                  icon: const Icon(Icons.photo_album),
                  label: const Text('View More'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.7),
                    foregroundColor: Colors.white,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showMoreImages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complaint Images'),
        content: SingleChildScrollView(
          child: Column(
            children: _complaint!.images.map((imageCid) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Image.network(
                  'https://gateway.pinata.cloud/ipfs/$imageCid',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRows() {
    return Column(
      children: [
        DetailRow(
          icon: Icons.location_on,
          label: "Address",
          value: _complaint!.address,
        ),
        DetailRow(
          icon: Icons.category,
          label: "Complaint Type",
          value: _complaint!.complaintType,
        ),
        DetailRow(
          icon: Icons.description,
          label: "Subtype",
          value: _complaint!.complaintSubType,
        ),
        DetailRow(
          icon: Icons.timelapse,
          label: "Status",
          value: _complaint!.status,
          valueColor: _getStatusColor(_complaint!.status),
        ),
        DetailRow(
          icon: Icons.place,
          label: "Landmark",
          value: _complaint!.landmark,
        ),
        DetailRow(
          icon: Icons.phone,
          label: "Phone",
          value: _complaint!.phone,
        ),
        DetailRow(
          icon: Icons.warning,
          label: "Hot Complaint",
          value: _complaint!.isHotComplaint ? "Yes" : "No",
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complaint Description',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _complaint!.description,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

// Existing DetailRow and ActionButton classes remain the same as in the previous implementation
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

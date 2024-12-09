// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:image_picker/image_picker.dart';

// class RaiseComplaintScreen extends StatefulWidget {
//   const RaiseComplaintScreen({super.key});

//   @override
//   State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
// }

// class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
//   CameraController? _cameraController;
//   XFile? _imageFile;
//   Position? _currentPosition;
//   TextEditingController _descriptionController = TextEditingController();
//   String _priority = 'Low'; // Default priority
//   bool _isCameraInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _getCurrentLocation();
//   }

//   // Initialize the camera
//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     final camera = cameras.first; // Use the first available camera
//     _cameraController = CameraController(camera, ResolutionPreset.high);
//     await _cameraController!.initialize();
//     setState(() {
//       _isCameraInitialized = true;
//     });
//   }

//   // Get the current location
//   Future<void> _getCurrentLocation() async {
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     setState(() {
//       _currentPosition = position;
//     });
//   }

//   // Take a picture with the camera
//   Future<void> _takePicture() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }

//     try {
//       final image = await _cameraController!.takePicture();
//       setState(() {
//         _imageFile = image;
//       });
//     } catch (e) {
//       print("Error capturing image: $e");
//     }
//   }

//   // Submit the complaint
//   void _submitComplaint() {
//     if (_imageFile != null && _descriptionController.text.isNotEmpty) {
//       final complaint = {
//         'image': _imageFile!.path,
//         'description': _descriptionController.text,
//         'priority': _priority,
//         'location': _currentPosition != null
//             ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}'
//             : 'Location not available',
//       };
//       // Handle the complaint submission logic here
//       print("Complaint Submitted: $complaint");
//       // You can show the complaint details or navigate to another screen
//     } else {
//       // Show error message if required fields are missing
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please take a photo and fill out the description')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Raise a Complaint'),
//         backgroundColor: const Color(0xFFFEDBD0),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             if (_isCameraInitialized)
//               CameraPreview(_cameraController!)
//             else
//               const Center(child: CircularProgressIndicator()),
//             const SizedBox(height: 16),
//             if (_imageFile != null)
//               Image.file(
//                 File(_imageFile!.path),
//                 height: 200,
//                 width: 200,
//                 fit: BoxFit.cover,
//               ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _takePicture,
//               child: const Text('Take Picture'),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _descriptionController,
//               decoration: const InputDecoration(
//                 labelText: 'Description',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//             const SizedBox(height: 16),
//             DropdownButton<String>(
//               value: _priority,
//               onChanged: (String? newValue) {
//                 setState(() {
//                   _priority = newValue!;
//                 });
//               },
//               items: <String>['Low', 'Medium', 'High']
//                   .map<DropdownMenuItem<String>>((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _submitComplaint,
//               child: const Text('Submit Complaint'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// void main() {
//   runApp(
//     MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const RaiseComplaintScreen(), // Set Home as the starting screen
//     ),
//   );
// }


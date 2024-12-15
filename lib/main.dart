import 'dart:io';
import 'dart:typed_data';

import 'package:design_model/loading.dart';
import 'package:design_model/login.dart';
import 'package:design_model/register.dart';
import 'package:design_model/home.dart';
import 'package:design_model/raise_complaint.dart';
import 'package:design_model/complaint.dart';
import 'package:design_model/notification.dart';
import 'package:design_model/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image/image.dart' as img;

class ApiKeys {
  static const String pinataApiKey = '2dfc4e3fec850909b6e1';
  static const String pinataApiSecrectKey = '3a9b9b71f1d65bf68349049b5316af65a7f48642b281edb9f2aaf7672402080c';

  // You can add other keys here as needed
}




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final sessionOptions = OrtSessionOptions();
// const assetFileName = 'assets/models/garbage.onnx';



// detectGarbage();
// final rawAssetFile = await rootBundle.load(assetFileName);
// final bytes = rawAssetFile.buffer.asUint8List();
// final session = OrtSession.fromBuffer(bytes, sessionOptions!);
// final runOptions = OrtRunOptions();
// ByteData bytesData = await rootBundle.load('assets/images/hot1.jpeg');
// final bytesView = Uint8List.view(bytesData.buffer).indexed; 
// final greyScale = bytesView.where((e)=>e.$1 % 4  ==0);
// final binary = greyScale.map((e)=>e.$2.toDouble() /255).toList();
// final input = OrtValueTensor.createTensorWithDataList(Float32List.fromList(binary), [1,1,128,128]);
// final output = await session.runAsync(runOptions, {"input": input});
// var result = ( output?[0]?.value as List)[0] as List<double>;
// output?.forEach((e)=> e?.release()); 
// input.release();
// runOptions.release();
// session.release();
// OrtEnv.instance.release();
// var index = 0;
// for(int i = 1; i< result.length; i++){
//   if(result[i] > result[index]) index = i;
// }
// final confidence = (result[index] * 100).toInt();

// print("Output $index confidence $confidence");
await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBt2ghase2-osD2T12T4dIcfBGpOr5gZlI',
      appId: '1:706274649488:android:723909297cf2ae8ae17f15',
      messagingSenderId: 'sendid',
      projectId: 'public-pulse-4',
      storageBucket: 'public-pulse-4.firebasestorage.app',
    ),
  );
  runApp(MyApp());
}

// Future<void> detectGarbage() async {
//   // Load ONNX model
//   final rawAssetFile = await rootBundle.load('assets/models/garbage.onnx');
//   final sessionOptions = OrtSessionOptions();
//  final bytes = rawAssetFile.buffer.asUint8List();
//   final session = OrtSession.fromBuffer(bytes, sessionOptions);
// final runOptions = OrtRunOptions();

// ByteData bytesData = await rootBundle.load('assets/images/profile_placeholder.png');

//   // Read and preprocess image
//   final image = img.decodeImage(Uint8List.view(bytesData.buffer));
//   if (image == null) {
//     throw Exception("Unable to decode image");
//   }

//   // Resize to 128x128 (or the expected input size of your model)
//   final resizedImage = img.copyResize(image, width: 128, height: 128);

//   // Convert image to Float32List
//   final inputTensor = Float32List(1 * 3 * 640 * 640); // Assuming grayscale input
//   for (var y = 0; y < 128; y++) {
//     for (var x = 0; x < 128; x++) {
//       final pixel = resizedImage.getPixel(x, y);
//       final gray = img.getLuminance(pixel) / 255.0; // Normalize pixel to [0, 1]
//       inputTensor[y * 128 + x] = gray;
//     }
//   }

//   // Create tensor input
//   final input = OrtValueTensor.createTensorWithDataList(
//     inputTensor,
//    [1,3, 640, 640],
//   );

//   // Run inference
//   final outputs = session.run(runOptions,{'images': input}); // Replace 'input' with your actual input name
//   final outputTensor = outputs.first?.value as List<List<List<double>>>;


//   // Assuming the last value corresponds to "garbage" class probability
// // Assuming your model provides scores for each pixel for garbage detection
// // Let's say the last value in each list corresponds to "garbage" or detection score

// double threshold = 0.5;  // This can vary based on your model's output range

// // Flatten the 3D output to 2D (flatten the rows and columns)
// List<List<double>> flattenedOutput = [];
// for (var row in outputTensor) {
//   for (var pixel in row) {
//     flattenedOutput.add(pixel);  // Add each pixel's score to the flattened list
//   }
// }

// // Now, iterate through the flattened output and check for garbage detection
// bool garbageDetected = false;
// for (var pixel in flattenedOutput) {
//   double garbageScore = pixel[1];  // Assuming the second value is for "garbage" score
  
//   // If the garbage score exceeds the threshold, mark it as detected
//   if (garbageScore > threshold) {
//     garbageDetected = true;
//     break;  // Stop further checking once garbage is detected
//   }
// }

// print("Garbage detected: $garbageDetected");

//   // Interpret output
//   // final isGarbage = outputTensor[0] > 0.5; // Assuming output is a single value with threshold 0.5
//   //  debugPrint("Garbage detected: $outputTensor");

//   // Clean up
//   session.release();
// }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _initialRoute = 'home'; // Default route while determining login status

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Determine the initial route
    setState(() {
      _initialRoute = isLoggedIn ? 'home' : 'login';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: _initialRoute,
      routes: {
        'loading': (context) => MyLoading(),
        'register': (context) => MyRegister(),
        'login': (context) => MyLogin(),
        'home': (context) => HomeScreen(),
        'raise': (context) => RauseComplaint(),
        'complaints': (context) => MyComplaints(),
        'profile': (context) => ProfilePage(),
        'notification': (context) => NotificationPage(),
      },
    );
  }
}

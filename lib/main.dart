import 'package:design_model/loading.dart';
import 'package:design_model/login.dart';
import 'package:design_model/register.dart';
import 'package:design_model/home.dart';
import 'package:design_model/raise_complaint.dart';
import 'package:design_model/complaint.dart';
import 'package:design_model/notification.dart';
import 'package:design_model/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBt2ghase2-osD2T12T4dIcfBGpOr5gZlI',
      appId: '1:706274649488:android:723909297cf2ae8ae17f15',
      messagingSenderId: 'sendid',
      projectId: 'public-pulse-4',
      storageBucket: 'public-pulse-4.firebasestorage.app',
    ),
  );
  runApp(MyApp());
}

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
        'home': (context) => Home(),
        'raise': (context) => RauseComplaint(),
        'complaints': (context) => MyComplaints(),
        'profile': (context) => ProfilePage(),
        'notification': (context) => NotificationPage(),
      },
    );
  }
}

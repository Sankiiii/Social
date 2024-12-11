import 'package:design_model/loading.dart';
import 'package:design_model/login.dart';
import 'package:design_model/register.dart';
import 'package:design_model/home.dart';
import 'package:design_model/raise_complaint.dart';
import 'package:design_model/complaint.dart';
import 'package:design_model/session.dart';
import 'package:design_model/notification.dart';
import 'package:design_model/profile.dart';
import 'package:design_model/session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


 

void main()async {

  WidgetsFlutterBinding.ensureInitialized();
  // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  await Firebase.initializeApp(options: FirebaseOptions(
    apiKey: 'AIzaSyBt2ghase2-osD2T12T4dIcfBGpOr5gZlI',
    appId: '1:706274649488:android:723909297cf2ae8ae17f15',
    messagingSenderId: 'sendid',
    projectId: 'public-pulse-4',
    storageBucket: 'public-pulse-4.firebasestorage.app',
  ));
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: 'loading',
    routes: {
      'register': (context) => MyRegister(),
      'login' : (context) => MyLogin(),
      'loading' : (context) => MyLoading(),
      'home' : (context) => Home(),
      'raise' : (context) => RauseComplaint(),
      'complaints' : (context) => MyComplaints(),
      'profile' : (context) => ProfilePage(),
      'notification' : (context) => NotificationPage(),

    },
  ));
}





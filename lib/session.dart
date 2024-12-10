import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        // If the user is logged in, navigate to the home screen
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            Future.microtask(() => Navigator.pushReplacementNamed(context, 'home'));
          } else {
            Future.microtask(() => Navigator.pushReplacementNamed(context, 'login'));
          }
        }
        // Show a loading indicator while checking auth state
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

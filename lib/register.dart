import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRegister extends StatefulWidget {
  @override
  State<MyRegister> createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEEAE6), // Set the background color of the screen
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Ensures the form stays at the top
            children: [
              const SizedBox(height: 80),
              const Text(
                'SOCIAL',
                style: TextStyle(
                  fontFamily: 'Amaranth', // Set the font family globally
                  fontSize: 70,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF442C2E), // Font color set to #442C2E
                ),
              ),
              const SizedBox(height: 60),

              // Registration Form with background color
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEDBD0), // Set background color for the form
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey, // Assign the form key here
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Text
                        const Text(
                          'Welcome...!!',
                          style: TextStyle(
                            fontFamily: 'Amaranth', // Set font family here
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF442C2E),
                          ),
                        ),
                        const Text(
                          'please create your account',
                          style: TextStyle(
                            fontFamily: 'Amaranth', // Set font family here
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF442C2E),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Already have an account? Option (above Register button)
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to the login screen
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Register button at the bottom
              const SizedBox(height: 90),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    try {
                      final userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userCredential.user?.uid)
                          .set({
                        'username': _usernameController.text.trim(),
                        'email': _emailController.text.trim(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration successful!')),
                      );
                      Navigator.pushNamed(context, 'home'); // Navigate to ProfilePage
                    } catch (e) {
                      String errorMessage = 'An error occurred!';
                      if (e is FirebaseAuthException) {
                        if (e.code == 'email-already-in-use') {
                          errorMessage = 'The email address is already in use.';
                        } else if (e.code == 'weak-password') {
                          errorMessage = 'The password is too weak.';
                        }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $errorMessage')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFFFEDBD0),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20), // Add spacing below the button
            ],
          ),
        ),
      ),
    );
  }
}

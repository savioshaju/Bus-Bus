import 'dart:io';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'transit_provider.dart';
import 'login.dart' as login;
import 'newreg.dart';
import 'searchpage.dart' as search;
import 'admin.dart';
import 'admin_approval.dart';
import 'pending_approval.dart';
import 'profile_page.dart';
import 'ChangePasswordPage.dart';

void main() {
  // Start the server before running the app
  startServer();

  // Run the Flutter app
  runApp(const MyApp());
}

// Function to start the server
void startServer() async {
  try {
    await Process.start(
      'node',
      ['D:/Savio Shaju/bus_bus/backend/server.js'], // Path to your server file
      mode: ProcessStartMode.detached, // Runs the server in a separate process
    );
    print('Server started successfully!');
  } catch (e) {
    print('Error starting the server: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus Tracking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const login.LoginPage(),
        '/homepage': (context) => const HomePage(),
        '/transit_provider': (context) => const TransitProviderPage(),
        '/signup': (context) => const SignUpPage(),
        '/searchpage': (context) => const search.SearchPage(),
        '/newreg': (context) => const SignUpPage(),
        '/admin': (context) => const AdminPage(),
        '/admin_approval': (context) => const AdminApprovalPage(),
        '/pending_approval': (context) => const PendingApprovalPage(),
        '/profile': (context) => ProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),  
      },
    );
  }
}
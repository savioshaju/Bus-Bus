import 'package:flutter/material.dart' show BuildContext, Colors, MaterialApp, StatelessWidget, ThemeData, Widget, runApp;
import 'homepage.dart';
import 'transit_provider.dart';
import 'login.dart' as login;
import 'newreg.dart';
import 'searchpage.dart' as search;
import 'admin.dart';
import 'admin_approval.dart';
import 'pending_approval.dart'; 

void main() {
  runApp(const MyApp());
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
        '/pending_approval': (context) =>
            const PendingApprovalPage(), // Added route for pending approval page
      },
    );
  }
}
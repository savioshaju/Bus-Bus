import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  _AdminApprovalPageState createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  List<dynamic> _pendingUsers = [];
  bool _isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    final url = 'http://localhost:5000/admin/pending-providers';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("auth_token");

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing authentication token')),
      );
      return;
    }

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        setState(() {
          _pendingUsers = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${response.body}')), // Show exact error message
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _approveUser(int userId) async {
    final url = 'http://localhost:5000/admin/approve-provider';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("auth_token");

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing authentication token')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // ✅ Use stored token here
        },
        body: jsonEncode({"userId": userId, "status": "Approved"}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User approved successfully')),
        );
        _fetchPendingUsers(); // Refresh list after approval
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')), // Show exact error
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // ✅ Refresh button
            onPressed: _fetchPendingUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Show loading indicator
          : _pendingUsers.isEmpty
              ? const Center(child: Text('No pending approvals'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = _pendingUsers[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Name: ${user['first_name']} ${user['last_name']}",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Email: ${user['email']}",
                                style: const TextStyle(fontSize: 16)),
                            Text("Phone: ${user['phone_number']}",
                                style: const TextStyle(fontSize: 16)),
                            Text("DOB: ${user['dob']}",
                                style: const TextStyle(fontSize: 16)),
                            Text("Address: ${user['address']}",
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _approveUser(user['id']),
                              child: const Text("Approve"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

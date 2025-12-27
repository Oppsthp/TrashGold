import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Sign out function
  // Future<void> _signOut(BuildContext context) async {
  //   await FirebaseAuth.instance.signOut();
  //   // Go back to login screen
  //   Navigator.pop(context);
  // }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: () => _signOut(context),
        //     tooltip: 'Sign Out',
        //   ),
        // ],
      ),
      drawer: 
      Drawer(
        child: ListView(
          children: [
      //      UserAccountsDrawerHeader(accountName: accountName, accountEmail: accountEmail)
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${user?.isAnonymous == true ? 'Guest' : user?.displayName ?? user?.email ?? ''}!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              "UID: ${user?.uid}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

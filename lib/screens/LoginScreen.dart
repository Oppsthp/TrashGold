import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trashgold/screens/DashboardScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleInitialized = false;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      if (mounted) {
        setState(() {
          _isGoogleInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Google Sign-In init failed: $e');
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );;
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guest login failed: ${e.message}')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // Skip on unsupported platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google login not supported on desktop")),
        );
      }
      return;
    }

    if (!_isGoogleInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In not ready")),
        );
      }
      return;
    }

    setState(() => _isSigningIn = true);

    try {
      // Authenticate with Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      // User cancelled - silent return
      if (googleUser == null || !mounted) {
        setState(() => _isSigningIn = false);
        return;
      }

      // Get authorization for Firebase
      final GoogleSignInClientAuthorization auth =
      await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);

      if (auth.accessToken == null) {
        throw Exception('No access token received');
      }

      // Create Firebase credential (accessToken only for v7.2.0)
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
      );

      // Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pop(context);
    } on GoogleSignInException catch (e) {
      // Handle cancellation silently, show other errors
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.code}')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Sign-In Button
            ElevatedButton(
              onPressed: _isGoogleInitialized && !_isSigningIn ? _signInWithGoogle : null,
              child: _isSigningIn
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    "Continue with Google",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "OR",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                Expanded(child: Container(height: 1, color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 20),

            // Guest Button
            OutlinedButton(
              onPressed: _isSigningIn ? null : _signInAnonymously,
              child: const Text(
                "Continue as Guest",
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import '../Screens/welcomescreen.dart';
import '../Screens/role_selection_screen.dart';
import '../hospital/hospital_welcome.dart';
import '../admin/admin_panel_screen.dart';
import '../utils/firebase_utils.dart';

class LoginScreen extends StatefulWidget {
  final bool showSuccessMessage;
  const LoginScreen({super.key, this.showSuccessMessage = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSuccessMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registered Successfully")),
        );
      });
    }
  }

  Future<void> _loginUser() async {
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter email and password")),
    );
    return;
  }

  if (mounted) setState(() => _loading = true);

  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final uid = userCredential.user?.uid;
    if (uid == null) return;

    await saveDeviceToken(uid);

    // ✅ Admin
    if (userCredential.user!.email?.toLowerCase() == "admin@gmail.com") {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      );
      return;
    }

    // ✅ Check role
    final roleDoc = await FirebaseFirestore.instance
        .collection('user_roles')
        .doc(uid)
        .get();

    if (!mounted) return; // stop if widget is gone

    if (!roleDoc.exists || roleDoc['accountType'] == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleSelectionScreen(
            name: userCredential.user!.displayName ?? userCredential.user!.email ?? "",
            onRoleSelected: () {},
          ),
        ),
      );
    } else {
      final accountType = roleDoc['accountType'];
      if (accountType == 'person') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(
              name: userCredential.user!.displayName ?? userCredential.user!.email ?? "",
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HospitalSplashScreen(name: 'Hospital/Blood Bank'),
          ),
        );
      }
    }
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? "Login failed")),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email to reset password")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to send reset email")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ListView(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.bloodtype, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Login",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildTextField("Email", _emailController),
            const SizedBox(height: 20),
            _buildTextField("Password", _passwordController, obscure: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: const Text("Forgot Password?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loginUser,
                    child: const Text("Login", style: TextStyle(fontSize: 18)),
                  ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "By Logging in, you agree to our Terms & Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                },
                child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

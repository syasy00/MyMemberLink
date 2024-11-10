import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_member_link/myconfig.dart';
import 'dart:developer' as developer;
import 'package:my_member_link/views/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({required this.email, Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      _showMessage("Passwords do not match");
      return;
    }

    if (password.length < 8) {
      _showMessage("Password must be at least 8 characters long");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${MyConfig.servername}/memberlink/api/reset_password.php"),
        body: {
          'email': widget.email,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        _showMessage("Password reset successful", color: Colors.green);
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const LoginScreen())); // Navigate back to login screen
      } else {
        _showMessage(data['message'] ?? "Password reset failed");
      }
    } catch (error) {
      _showMessage("An error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Enter a new password for your account",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      child: const Text("Submit"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';

// class ResetPasswordScreen extends StatelessWidget {
//   final String token;
//   const ResetPasswordScreen({required this.token, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Replace with your actual password reset logic using the token
//     return Scaffold(
//       appBar: AppBar(title: Text("Reset Password")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text("Token: $token"),
//             // Add text fields and a submit button for password reset here
//           ],
//         ),
//       ),
//     );
//   }
// }

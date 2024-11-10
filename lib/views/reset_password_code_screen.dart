import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_member_link/myconfig.dart';
import 'package:my_member_link/views/reset_password_screen.dart';

class ResetPasswordCodeScreen extends StatefulWidget {
  final String email;

  const ResetPasswordCodeScreen({super.key, required this.email});

  @override
  _ResetPasswordCodeScreenState createState() =>
      _ResetPasswordCodeScreenState();
}

class _ResetPasswordCodeScreenState extends State<ResetPasswordCodeScreen> {
  final TextEditingController codeController1 = TextEditingController();
  final TextEditingController codeController2 = TextEditingController();
  final TextEditingController codeController3 = TextEditingController();
  final TextEditingController codeController4 = TextEditingController();
  String codeError = "";

  @override
  void dispose() {
    codeController1.dispose();
    codeController2.dispose();
    codeController3.dispose();
    codeController4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Reset Code"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "A 4-digit verification code has been sent to your email.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCodeInputField(codeController1),
                  _buildCodeInputField(codeController2),
                  _buildCodeInputField(codeController3),
                  _buildCodeInputField(codeController4),
                ],
              ),
              if (codeError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    codeError,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onVerifyCode,
                child: const Text("Verify"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInputField(TextEditingController controller) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          counterText: "",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void onVerifyCode() {
    String enteredCode = codeController1.text +
        codeController2.text +
        codeController3.text +
        codeController4.text;

    setState(() {
      codeError = "";
    });

    if (enteredCode.length != 4) {
      setState(() {
        codeError = "Please enter a 4-digit code.";
      });
      return;
    }

    // Call backend to verify the code
    verifyCode(enteredCode);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void verifyCode(String code) async {
    final response = await http.post(
      Uri.parse(
          "${MyConfig.servername}/memberlink/api/verify_forgot_password_code.php"),
      body: {
        "email": widget.email,
        "code": code,
      },
    );

    if (response.body.isEmpty) {
      _showErrorDialog("No response from the server. Please try again later.");
      return;
    }

    final data = jsonDecode(response.body);

    developer.log(data.toString());

    if (data['status'] == "success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      setState(() {
        codeError = data['message'] ?? "Invalid code. Please try again.";
      });
    }
  }
}

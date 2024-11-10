import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_member_link/myconfig.dart';
import '../components/button.dart';
import '../components/input.dart';
import './login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();

  // Error message strings
  String nameError = "";
  String emailError = "";
  String passwordError = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Wrap the body with SingleChildScrollView
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "MyMemberLink",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  controller: namecontroller,
                  hintText: "Syu Syi",
                  keyboardType: TextInputType.name,
                  labelText: "Your Name",
                  icon: const Icon(Icons.person),
                ),
                if (nameError.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        nameError,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomInputField(
                  controller: emailcontroller,
                  hintText: "syasya@my.com",
                  keyboardType: TextInputType.emailAddress,
                  isPassword: false,
                  labelText: "Your Email",
                  icon: const Icon(Icons.email),
                ),
                if (emailError.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        emailError,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomInputField(
                  controller: passwordcontroller,
                  hintText: "password",
                  isPassword: true,
                  labelText: "Your Password",
                  icon: const Icon(Icons.lock),
                ),
                if (passwordError.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        passwordError,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                CustomButton(
                  text: "Register",
                  type: ButtonType.primary,
                  onPressed: onRegisterDialog,
                  size: ButtonSize.large,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onRegisterDialog() {
    // Clear previous error messages
    setState(() {
      nameError = "";
      emailError = "";
      passwordError = "";
    });

    String name = namecontroller.text;
    String email = emailcontroller.text;
    String password = passwordcontroller.text;

    // Validation
    bool isValid = true;
    if (name.isEmpty) {
      nameError = "Please enter your name";
      isValid = false;
    }
    if (email.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')
            .hasMatch(email)) {
      emailError = "Please enter a valid email";
      isValid = false;
    }
    if (password.isEmpty || password.length < 8) {
      passwordError = "Password must be at least 8 characters";
      isValid = false;
    }

    // If not valid, update state to show error messages
    if (!isValid) {
      setState(() {});
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.person_add_alt_1,
                color: Colors.blueAccent,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                "Register New Account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to create a new account?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 10),
          actions: <Widget>[
            Divider(height: 1, color: Colors.grey[300]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    foregroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    userRegistration();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Confirm",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    foregroundColor: Colors.redAccent,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void userRegistration() {
    String name = namecontroller.text;
    String email = emailcontroller.text;
    String pass = passwordcontroller.text;
    http.post(
      Uri.parse("${MyConfig.servername}/memberlink/api/register_user.php"),
      body: {"name": name, "email": email, "password": pass},
    ).then((response) {
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == "success") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          if (data['message'] == "Email already registered.") {
            // Show a pop-up dialog if the email is already registered
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Registration Failed"),
                  content: const Text(
                      "The email is already registered. Please use a different email."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          } else {
            // General error message if registration fails for other reasons
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Registration Failed"),
                  content: const Text("Registration failed. Please try again."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    });
  }
}

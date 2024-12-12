import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:my_member_link/myconfig.dart';
import 'package:my_member_link/views/news%20/main_screen.dart';
import 'package:my_member_link/views/authentication%20/register_screen.dart';
import 'package:my_member_link/views/authentication%20/reset_password_code_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../components/button.dart';
import '../../components/input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool rememberme = false;
  bool isLoggingIn = false;

  String emailError = "";
  String passwordError = "";

  @override
  void initState() {
    super.initState();
    loadPref();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Login"),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset:
          true, // Allows layout adjustments when the keyboard appears
      body: Center(
        child: SingleChildScrollView(
          // Makes content scrollable
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/log.gif",
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 10),
              CustomInputField(
                controller: emailcontroller,
                hintText: "syasya@my.com",
                isPassword: false,
                labelText: "Your Email",
                icon: const Icon(Icons.email),
              ),
              if (emailError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      emailError,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              CustomInputField(
                controller: passwordcontroller,
                hintText: "password",
                isPassword: true,
                labelText: "Password",
                icon: const Icon(Icons.lock),
              ),
              if (passwordError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      passwordError,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Remember me"),
                  Checkbox(
                    value: rememberme,
                    activeColor: Colors.grey[800],
                    onChanged: (bool? value) {
                      setState(() {
                        String email = emailcontroller.text;
                        String pass = passwordcontroller.text;
                        if (value!) {
                          if (email.isNotEmpty && pass.isNotEmpty) {
                            storeSharedPrefs(value, email, pass);
                          } else {
                            rememberme = false;
                            emailError =
                                email.isEmpty ? "Please enter email" : "";
                            passwordError =
                                pass.isEmpty ? "Please enter password" : "";
                            return;
                          }
                        } else {
                          email = "";
                          pass = "";
                          storeSharedPrefs(value, email, pass);
                        }
                        rememberme = value;
                        setState(() {});
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 5),
              CustomButton(
                text: "Login",
                state: isLoggingIn ? ButtonState.loading : ButtonState.enabled,
                type: ButtonType.primary,
                onPressed: onLogin,
                size: ButtonSize.large,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showForgotPasswordDialog(),
                child: const Text("Forgot Password?",
                    style: TextStyle(color: Colors.blue)),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  clearFields(); // Clear fields when navigating to Register
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (content) => const RegisterScreen()))
                      .then((_) {
                    clearFields(); // Clear fields when coming back from Register
                  });
                },
                child: const Text(
                  "Create new account?",
                  style: TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

 void onLogin() {
  setState(() {
    isLoggingIn = true;
    emailError = "";
    passwordError = "";
  });

  String email = emailcontroller.text;
  String password = passwordcontroller.text;
  bool isValid = true;

  if (email.isEmpty) {
    emailError = "Please enter email";
    isValid = false;
  } else if (!email.contains('@') || !email.contains('.com')) {
    emailError = "Please enter a valid email";
    isValid = false;
  }

  if (password.isEmpty) {
    passwordError = "Please enter password";
    isValid = false;
  } else if (password.length < 8) {
    passwordError = "Password must be at least 8 characters";
    isValid = false;
  }

  if (!isValid) {
    setState(() {
      isLoggingIn = false;
    });
    return;
  }

  http.post(Uri.parse("${MyConfig.servername}/memberlink/api/login_user.php"),
      body: {"email": email, "password": password}).then((response) async {
    setState(() {
      isLoggingIn = false;
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['status'] == "success") {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', data['username'] ?? "User");
        await prefs.setString('useremail', email);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        showLoginFailedDialog(context);
      }
    } else {
      showLoginFailedDialog(context);
    }
  });
}


  Future<void> storeSharedPrefs(bool value, String email, String pass) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value) {
      prefs.setString("email", email);
      prefs.setString("password", pass);
      prefs.setBool("rememberme", value);
    } else {
      prefs.setString("email", email);
      prefs.setString("password", pass);
      prefs.setBool("rememberme", value);
      emailcontroller.text = "";
      passwordcontroller.text = "";
      setState(() {});
    }
  }

  Future<void> loadPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    emailcontroller.text = prefs.getString("email") ?? "";
    passwordcontroller.text = prefs.getString("password") ?? "";
    rememberme = prefs.getBool("rememberme") ?? false;
    setState(() {});
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Forgot Password"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: "Enter your email"),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () {
                String email = emailController.text;
                if (email.isNotEmpty &&
                    email.contains('@') &&
                    email.contains('.')) {
                  requestPasswordReset(email);
                  Navigator.of(context)
                      .pop(); // Close the dialog after submitting
                } else {
                  Navigator.of(context).pop(); // Close the dialog
                  _showErrorDialog(
                      "Please enter a valid email."); // Show error popup
                }
              },
              child: const Text("Send Reset Code"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${MyConfig.servername}/memberlink/api/forgot_password.php"),
        body: {"email": email},
      );

      if (response.body.isEmpty) {
        _showErrorDialog(
            "No response from the server. Please try again later.");
        return;
      }

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final data = jsonDecode(response.body);

        developer.log(data.toString());

        if (data['status'] == "success") {
          Navigator.of(context).pop();

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                title: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Verification Code Sent",
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
                  "A 4-digit verification code has been sent to your email. Please check your inbox.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 10),
                actions: <Widget>[
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        foregroundColor: Colors.blueAccent,
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ResetPasswordCodeScreen(email: email),
                          ),
                        );
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          _showErrorDialog(data['message'] ?? "Error sending reset code.");
        }
      } else {
        _showErrorDialog("Unexpected response format from the server.");
      }
    } catch (error, stackTrace) {
      _showErrorDialog("An error occurred. Please try again.");
    }
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

  void showLoginFailedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            children: [
              Icon(
                Icons.error,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                "Login Failed",
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
            "Invalid email or password. Please try again.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 10),
          actions: <Widget>[
            Divider(height: 1, color: Colors.grey[300]),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  foregroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  clearFields();
                },
                child: const Text(
                  "Close",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void clearFields() {
    emailcontroller.clear();
    passwordcontroller.clear();
    setState(() {
      emailError = "";
      passwordError = "";
    });
  }
}

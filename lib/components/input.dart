import 'package:flutter/material.dart';

class CustomInputField extends StatefulWidget {
  const CustomInputField({
    Key? key,
    required this.hintText,
    this.labelText,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.icon,
  }) : super(key: key);

  final String hintText;
  final String? labelText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Icon? icon;

  @override
  _CustomInputFieldState createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23.0),
          borderSide: BorderSide(
              color: const Color.fromARGB(255, 223, 223, 223), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23.0),
          borderSide: BorderSide(
              color: const Color.fromARGB(255, 223, 223, 223), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(23.0),
          borderSide: BorderSide(
              color: const Color.fromARGB(255, 223, 223, 223), width: 1.0),
        ),
        prefixIcon: widget.icon, // Add icon here as prefix
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: _toggleVisibility,
              )
            : null,
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}

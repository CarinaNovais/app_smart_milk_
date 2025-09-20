import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    const offWhite = Color(0xFFF5F5F5); // tom off-white

    IconData? prefixIcon;
    if (hintText.toLowerCase().contains('usuário') ||
        hintText.toLowerCase().contains('email')) {
      prefixIcon = Icons.person_outline;
    } else if (hintText.toLowerCase().contains('senha')) {
      prefixIcon = Icons.lock_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: offWhite,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: offWhite,
        decoration: InputDecoration(
          prefixIcon:
              prefixIcon != null
                  ? Icon(prefixIcon, color: offWhite.withOpacity(0.8))
                  : null,
          hintText: hintText,
          hintStyle: TextStyle(color: offWhite.withOpacity(0.7), fontSize: 15),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: offWhite, width: 1.2),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: offWhite, width: 2),
          ),
        ),
      ),
    );
  }
}

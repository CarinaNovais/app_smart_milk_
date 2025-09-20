import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;

  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: CupertinoButton(
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF004aad), // cor principal
        pressedOpacity: 0.85, // efeito ao pressionar (iOS vibe)
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

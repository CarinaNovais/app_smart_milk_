import 'package:flutter/material.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationPressed;
  final TextStyle style;

  const Navbar({
    super.key,
    required this.title,
    this.onNotificationPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0097B2),
      title: Text(title, style: style),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white70),
          onPressed:
              onNotificationPressed ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Você abriu as notificações')),
                );
              },
        ),
        Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white70),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Funciona sempre aqui
                },
              ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';

const Color appBlue = Color(0xFF0097B2);

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle style;
  final VoidCallback? onNotificationPressed;

  const Navbar({
    super.key,
    required this.title,
    required this.style,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appBlue,
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
                  Scaffold.of(
                    context,
                  ).openEndDrawer(); // Abre o Drawer da página
                },
              ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

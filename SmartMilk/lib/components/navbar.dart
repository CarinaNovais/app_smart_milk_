import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color appBlue = Color(0xFF0097B2);

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle style;
  final String? backPageRoute;
  final Map<int, String>? backPageRoutePorCargo;
  final VoidCallback? onNotificationPressed;
  final IconData backIcon;
  final bool showEndDrawerButton;
  final bool showBackButton;

  const Navbar({
    super.key,
    required this.title,
    required this.style,
    this.backPageRoute,
    this.backPageRoutePorCargo,
    this.onNotificationPressed,
    this.backIcon = Icons.arrow_back,
    this.showEndDrawerButton = false, // padrão: false
    this.showBackButton = true, //padrao: mostra a seta
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appBlue,
      title: Text(title, style: style),
      automaticallyImplyLeading: showBackButton,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(backIcon, color: Colors.white),
                onPressed: () async {
                  if (backPageRoutePorCargo != null &&
                      backPageRoutePorCargo!.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    final cargo = prefs.getInt('cargo');
                    if (cargo != null &&
                        backPageRoutePorCargo!.containsKey(cargo)) {
                      Navigator.pushReplacementNamed(
                        context,
                        backPageRoutePorCargo![cargo]!,
                      );
                      return;
                    }
                  }
                  if (backPageRoute != null) {
                    Navigator.pushReplacementNamed(context, backPageRoute!);
                    return;
                  }
                  Navigator.pop(context);
                },
              )
              : null, //sem seta
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
        if (showEndDrawerButton)
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
      ],
    );
  }
  //     leading: IconButton(
  //       icon: Icon(backIcon, color: Colors.white),
  //       onPressed: () async {
  //         if (backPageRoutePorCargo != null &&
  //             backPageRoutePorCargo!.isNotEmpty) {
  //           final prefs = await SharedPreferences.getInstance();
  //           final cargo = prefs.getInt('cargo');
  //           if (cargo != null && backPageRoutePorCargo!.containsKey(cargo)) {
  //             Navigator.pushReplacementNamed(
  //               context,
  //               backPageRoutePorCargo![cargo]!,
  //             );
  //             return;
  //           }
  //         }
  //         if (backPageRoute != null) {
  //           Navigator.pushReplacementNamed(context, backPageRoute!);
  //           return;
  //         }
  //         Navigator.pop(context);
  //       },
  //     ),
  //     actions: [
  //       IconButton(
  //         icon: const Icon(Icons.notifications, color: Colors.white70),
  //         onPressed:
  //             onNotificationPressed ??
  //             () {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(content: Text('Você abriu as notificações')),
  //               );
  //             },
  //       ),
  //       if (showEndDrawerButton)
  //         Builder(
  //           builder:
  //               (context) => IconButton(
  //                 icon: const Icon(Icons.menu, color: Colors.white),
  //                 onPressed: () => Scaffold.of(context).openEndDrawer(),
  //               ),
  //         ),
  //     ],
  //   );
  // }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

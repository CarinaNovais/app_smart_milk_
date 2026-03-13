import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.showEndDrawerButton = false,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg = const Color(0xff219ebc).withOpacity(0.9);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent, // sem fundo sólido
      surfaceTintColor: Colors.transparent, // M3 sem “tinta”
      centerTitle: true,
      automaticallyImplyLeading: false,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,

      // Título
      title: Text(title, style: style.copyWith(color: style.color ?? fg)),

      // Botão de voltar
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(backIcon, color: fg),
                onPressed: () async {
                  if (backPageRoutePorCargo != null &&
                      backPageRoutePorCargo!.isNotEmpty) {
                    final prefs = await SharedPreferences.getInstance();
                    final cargo = prefs.getInt('cargo');
                    if (cargo != null &&
                        backPageRoutePorCargo!.containsKey(cargo)) {
                      // substitui a rota atual
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
              : null,

      // Ações (notificação + menu opcional)
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_none_rounded,
            color: fg.withOpacity(0.85),
          ),
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
                  icon: Icon(Icons.menu_rounded, color: fg),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
          ),
      ],

      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.10),
              // sem borda/linha
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  appBlue.withOpacity(0.06),
                  Colors.white.withOpacity(isDark ? 0.02 : 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

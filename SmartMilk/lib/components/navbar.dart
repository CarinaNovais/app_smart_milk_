import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Azul da sua marca (se quiser, ajuste aqui)
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
    // Off-white para ícones/título (combina com seus inputs)
    final Color fg = const Color(0xff219ebc).withOpacity(0.9);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent, // sem fundo sólido
      surfaceTintColor: Colors.transparent, // M3 sem “tinta”
      centerTitle: true,
      automaticallyImplyLeading: false, // controlamos manualmente
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,

      // Título
      title: Text(
        title,
        // usa o seu style, mas garante cor off-white se não vier definida
        style: style.copyWith(color: style.color ?? fg),
      ),

      // Botão de voltar (com a sua lógica completa)
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
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(
                        context,
                        backPageRoutePorCargo![cargo]!,
                      );
                      return;
                    }
                  }
                  if (backPageRoute != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, backPageRoute!);
                    return;
                  }
                  // ignore: use_build_context_synchronously
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

      // Glassmorphism: blur + leve brilho translúcido seguindo o gradiente do app
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // um véu translúcido (quase invisível) p/ dar “vidro”
              color: Colors.white.withOpacity(isDark ? 0.06 : 0.10),
              // sem borda/linha!
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

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/components/notifiers.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);

class MenuDrawer extends StatefulWidget {
  final MQTTService mqtt;

  const MenuDrawer({Key? key, required this.mqtt}) : super(key: key);

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool dadosCarregados = false;
  int? cargoUsuario;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dadosCarregados) {
      carregarDadosUsuario();
      dadosCarregados = true;
    }
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    final nome = prefs.getString('nome') ?? 'Usuário';
    final contato = prefs.getString('contato') ?? 'Contato não definido';
    final fotoBase64 = prefs.getString('foto');
    final cargo = prefs.getInt('cargo');

    nomeUsuarioNotifier.value = nome;
    contatoUsuarioNotifier.value = contato;
    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      fotoUsuarioNotifier.value = fotoBase64;
    }
    cargoUsuario = cargo;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offWhite = const Color(0xFFF5F5F5);

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)]
              : const [Color(0xFFB2EBF2), Color(0xFF80DEEA), Color(0xFF64B5F6)],
    );

    return Drawer(
      backgroundColor: Colors.transparent, // sem retângulo sólido
      child: Container(
        decoration: BoxDecoration(gradient: gradient), // fundo seguindo o app
        child: SafeArea(
          child: Column(
            children: [
              // ======= Header com glassmorphism =======
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.white)
                            .withOpacity(isDark ? 0.08 : 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Foto grande
                          ValueListenableBuilder<String?>(
                            valueListenable: fotoUsuarioNotifier,
                            builder: (context, fotoBase64, _) {
                              Uint8List? fotoMemoria;
                              if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                                fotoMemoria = base64Decode(fotoBase64);
                              }
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.35),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      fotoMemoria != null
                                          ? Image.memory(
                                            fotoMemoria,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.person,
                                              color: appBlue,
                                              size: 60,
                                            ),
                                          ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Nome
                          ValueListenableBuilder<String>(
                            valueListenable: nomeUsuarioNotifier,
                            builder:
                                (context, nome, _) => Text(
                                  nome,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? offWhite : Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 6),
                          // Contato
                          ValueListenableBuilder<String>(
                            valueListenable: contatoUsuarioNotifier,
                            builder:
                                (context, contato, _) => Text(
                                  contato,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? offWhite.withOpacity(0.85)
                                            : Colors.black.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ======= Lista de ações =======
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    _DrawerItem(
                      icon: Icons.home_rounded,
                      label: 'Início',
                      onTap: () {
                        if (cargoUsuario == 0) {
                          Navigator.of(context).pushNamed('/homeProdutor');
                        } else if (cargoUsuario == 2) {
                          Navigator.of(context).pushNamed('/homeColetor');
                        }
                      },
                      isDark: isDark,
                    ),
                    _DrawerItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Perfil',
                      onTap: () => Navigator.of(context).pushNamed('/perfil'),
                      isDark: isDark,
                    ),
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Configurações',
                      onTap:
                          () =>
                              Navigator.of(context).pushNamed('/configuracoes'),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(
                        color: Colors.white.withOpacity(0.25),
                        height: 18,
                        thickness: 1,
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      label: 'Sair',
                      isDestructive: true,
                      onTap: () async {
                        await widget.mqtt.logout();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item estilizado do Drawer
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.06 : 0.10,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive ? Colors.redAccent : fg.withOpacity(0.9),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isDestructive
                              ? Colors.redAccent
                              : fg.withOpacity(0.9),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive ? Colors.redAccent : fg.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

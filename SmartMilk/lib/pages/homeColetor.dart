import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/components/home_grid.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class HomeColetorPage extends StatefulWidget {
  const HomeColetorPage({super.key});

  @override
  State<HomeColetorPage> createState() => _HomeColetorPageState();
}

class _HomeColetorPageState extends State<HomeColetorPage> {
  String nomeUsuario = '';

  final List<GridItem> items = const [
    GridItem(
      imagePath: 'lib/images/dadosCoperativa.png',
      route: '/dadosCooperativa',
      legenda: 'Dados Cooperativa',
    ),
    GridItem(
      imagePath: 'lib/images/semFuncao.png',
      route: '/page2',
      legenda: 'Sem Função',
    ),
    GridItem(
      imagePath: 'lib/images/historicoColetas.png',
      route: '/historicoColeta',
      legenda: 'Histórico Coletas',
    ),
    GridItem(
      imagePath: 'lib/images/encontrarColetas.png',
      route: '/encontrarColetas',
      legenda: 'Coletas Disponíveis',
    ),
    GridItem(
      imagePath: 'lib/images/qrCode.png',
      route: '/qrCode',
      legenda: 'Qr Code',
    ),
    GridItem(
      imagePath: 'lib/images/tanquesSelecionados.png',
      route: '/rotaTanquesSelecionados',
      legenda: 'Rota dos Tanques',
    ),
  ];

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();

    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onDadosTanque: (_) {},
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar();
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome') ?? 'Coletor';
    if (!mounted) return;
    setState(() => nomeUsuario = nome);
  }

  @override
  void dispose() {
    try {
      mqtt.client.disconnect();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)]
              : const [Color(0xFFB2EBF2), Color(0xFF80DEEA), Color(0xFF64B5F6)],
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,

        appBar: Navbar(
          title: 'Página Inicial',
          style: const TextStyle(fontSize: 20),
          showEndDrawerButton: true,
          showBackButton: false,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: Stack(
            children: [
              // blobs de fundo
              Positioned(
                top: -60,
                left: -30,
                child: _Blob(
                  size: 180,
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.22)
                          : Colors.white.withOpacity(0.12),
                ),
              ),
              Positioned(
                bottom: -50,
                right: -20,
                child: _Blob(
                  size: 160,
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.18)
                          : Colors.white.withOpacity(0.10),
                ),
              ),

              // grid central
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: (isDark ? Colors.white : Colors.white)
                                  .withOpacity(isDark ? 0.07 : 0.12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: HomeGrid(
                              items: items,
                              columns: 2,
                              onItemTap:
                                  (item) =>
                                      Navigator.pushNamed(context, item.route),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

// lib/pages/aviso_simples_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const String servidorIP = '192.168.66.11';
const String servidorPorta = '5000';
String get kApiBaseUrl => 'http://$servidorIP:$servidorPorta';

const Color appBlue = Color(0xFF0097B2);

class AvisoSimplesPage extends StatefulWidget {
  const AvisoSimplesPage({super.key});
  @override
  State<AvisoSimplesPage> createState() => _AvisoSimplesPageState();
}

class _AvisoSimplesPageState extends State<AvisoSimplesPage> {
  String? _idTanque;
  String? _idRegiao;
  bool _loading = true;

  late MQTTService mqtt;

  @override
  void initState() {
    super.initState();
    _carregarPrefs();
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

  Future<void> _carregarPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    String? readAsString(String key) {
      final dyn = prefs.get(key);
      if (dyn is String) return dyn.trim().isEmpty ? null : dyn.trim();
      if (dyn is int) return dyn.toString();
      return null;
    }

    final idTanque = readAsString('idtanque');
    final idRegiao = readAsString('idregiao');

    if (!mounted) return;
    setState(() {
      _idTanque = idTanque;
      _idRegiao = idRegiao;
      _loading = false;
    });
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

    final url =
        (_idTanque != null && _idRegiao != null)
            ? '$kApiBaseUrl/aviso?idtanque=$_idTanque&idregiao=$_idRegiao'
            : null;

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: Navbar(
          title: 'Página de Avisos',
          style: const TextStyle(fontSize: 20), // cor aplicada na Navbar
          backPageRoute: '/homeProdutor',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: Center(
            child:
                _loading
                    ? const _GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    )
                    : (url == null)
                    ? const _GlassCard(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Não encontrei idtanque/idregiao no dispositivo.\n'
                          'Faça login novamente ou confira as chaves no SharedPreferences.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.5, height: 1.35),
                        ),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(16),
                      child: _GlassCard(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: double.infinity, // ocupa toda a largura
                            height:
                                MediaQuery.of(context).size.height *
                                0.75, // 75% da tela
                            child: Image.network(
                              url,
                              // fit: BoxFit.cover, // cobre a área
                              fit:
                                  BoxFit
                                      .contain, // mantém a proporção, sem distorcer
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (ctx, err, stack) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Não foi possível carregar a imagem.\n'
                                      'Verifique se a API está rodando e os parâmetros estão corretos.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

/// Card translúcido (glassmorphism) reutilizável
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.09 : 0.15,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

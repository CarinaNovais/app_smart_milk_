import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/tanque_dinamico_visual.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

class DadosTanquePage extends StatefulWidget {
  const DadosTanquePage({super.key});

  @override
  _DadosTanquePageState createState() => _DadosTanquePageState();
}

class _DadosTanquePageState extends State<DadosTanquePage> {
  double nivel = 0.0;
  List<String> dadosLeite = ['--', '--', '--', '--', '--', '--'];
  late MQTTService mqtt;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onDadosTanque: (dados) {
        setState(() {
          nivel = (dados['nivel'] ?? 0) / 100.0;
          dadosLeite = [
            '${dados['ph']}',
            '${dados['temp']}°C',
            '${dados['amonia']}',
            '${dados['carbono']}',
            '${dados['metano']}',
            '${dados['idregiao']}/${dados['idtanque']}',
          ];
        });
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar().then((_) {
      mqtt.buscarDadosTanque();
    });
  }

  String _rotuloDoDado(int index) {
    switch (index) {
      case 0:
        return 'pH';
      case 1:
        return 'Temperatura';
      case 2:
        return 'Amônia';
      case 3:
        return 'Carbono';
      case 4:
        return 'Metano';
      case 5:
        return 'Região/Tanque';
      default:
        return 'Dado ${index + 1}';
    }
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
      // gradiente por FORA do Scaffold
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent, // sem cor sólida
        extendBody: true,

        appBar: Navbar(
          title: 'Dados do tanque',
          style: const TextStyle(fontSize: 20), // cor é aplicada pela Navbar
          backPageRoute: '/homeProdutor',
          showEndDrawerButton: true,
        ),

        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // tanque visual
                TanqueVisual(nivel: nivel),
                const SizedBox(height: 24),
                // grid de métricas
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: List.generate(6, (index) {
                      return _DadoBox(
                        titulo: _rotuloDoDado(index),
                        valor: dadosLeite[index],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DadoBox extends StatelessWidget {
  final String titulo;
  final String valor;

  const _DadoBox({required this.titulo, required this.valor});

  IconData _iconForTitulo(String t) {
    final s = t.toLowerCase();
    if (s.contains('ph')) return Icons.science_outlined;
    if (s.contains('temperatura')) return Icons.thermostat_rounded;
    if (s.contains('amônia')) return Icons.bubble_chart_outlined;
    if (s.contains('carbono')) return Icons.co2; // disponível no Material Icons
    if (s.contains('metano')) return Icons.cloud_queue_rounded;
    if (s.contains('região') || s.contains('tanque')) {
      return Icons.badge_outlined;
    }
    return Icons.analytics_outlined;
  }

  @override
  Widget build(BuildContext context) {
    const appBlue = Color(0xFF0097B2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAFE), // sólido (sem vidro/blur)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBlue.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _iconForTitulo(titulo),
            color: appBlue.withOpacity(0.9),
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: appBlue,
            ),
          ),
        ],
      ),
    );
  }
}

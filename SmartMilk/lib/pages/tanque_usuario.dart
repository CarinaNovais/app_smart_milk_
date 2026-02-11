import 'dart:async'; //  Timer
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; //  ValueNotifier
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
  // Nível reativo (0.0 a 1.0) para o TanqueVisual
  final ValueNotifier<double> nivelNotifier = ValueNotifier<double>(0.0);

  // Métricas para a grade
  List<String> dadosLeite = List.filled(9, '--');

  // Diagnóstico visual
  DateTime? _ultimaAtualizacao;

  late MQTTService mqtt;
  Timer? _pollTimer;

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
        if (!mounted) return;

        // Normaliza com segurança e loga
        const double capacidadeL = 5.0;
        final bruto = dados['nivel'];
        final n = (bruto is num ? bruto.toDouble() : 0.0);
        final normalizado = (n / capacidadeL).clamp(0.0, 1.0);

        debugPrint(
          '[MQTT] onDadosTanque: nivelBruto=$bruto '
          'nivelNormalizado=${normalizado.toStringAsFixed(3)} '
          'payload=$dados',
        );

        // ⚠️ ValueNotifier NÃO emite se valor novo == antigo.
        // Então vamos garantir repaint:
        if (nivelNotifier.value == normalizado) {
          // força notificação mesmo sem mudança
          nivelNotifier.notifyListeners();
        } else {
          nivelNotifier.value = normalizado;
        }

        // Atualiza as métricas + timestamp
        setState(() {
          _ultimaAtualizacao = DateTime.now();
          dadosLeite = [
            '${dados['ph']}',
            '${dados['temp']}°C',
            '${dados['amonia']}',
            '${dados['metano']}',
            '${dados['idregiao']}/${dados['idtanque']}',
            '${dados['condutividade']}',
            '${dados['turbidez']}',
            '${dados['co2']}',
            '${dados['status_tanque']}',
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
      // Primeira busca
      mqtt.buscarDadosTanque();
      // 🔁 Polling leve: continue pedindo dados periodicamente
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) mqtt.buscarDadosTanque();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    nivelNotifier.dispose();
    super.dispose();
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
        return 'Metano';
      case 4:
        return 'Região/Tanque';
      case 5:
        return 'Condutividade';
      case 6:
        return 'Turbidez';
      case 7:
        return 'CO2';
      case 8:
        return 'Status';
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
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,

        appBar: Navbar(
          title: 'Dados do tanque',
          style: const TextStyle(fontSize: 20),
          backPageRoute: '/homeProdutor',
          showEndDrawerButton: true,
        ),

        endDrawer: MenuDrawer(mqtt: mqtt),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            mqtt.buscarDadosTanque();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Solicitando dados do tanque...')),
            );
          },
          tooltip: 'Atualizar agora',
          child: const Icon(Icons.refresh),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                if (_ultimaAtualizacao != null)
                  Text(
                    'Última atualização: ${_ultimaAtualizacao!.toLocal()}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                const SizedBox(height: 32),

                // Tanque visual reativo
                TanqueVisual(
                  nivel: 0.0, // ignorado quando passar o listenable
                  nivelListenable: nivelNotifier,
                ),

                const SizedBox(height: 24),

                // grid de métricas
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: List.generate(dadosLeite.length, (index) {
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
    if (s.contains('metano')) return Icons.cloud_queue_rounded;
    if (s.contains('região') || s.contains('tanque')) {
      return Icons.badge_outlined;
    }
    if (s.contains('condutividade')) return Icons.electrical_services;
    if (s.contains('turbidez')) return Icons.blur_on;
    if (s.contains('co2')) return Icons.co2;
    if (s.contains('status')) return Icons.info_outline;
    return Icons.analytics_outlined;
  }

  @override
  Widget build(BuildContext context) {
    const appBlue = Color(0xFF0097B2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAFE),
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

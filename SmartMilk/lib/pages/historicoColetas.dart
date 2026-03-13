import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

const Color appBlue = Color(0xFF0097B2);

class ListaColetasPage extends StatefulWidget {
  const ListaColetasPage({Key? key}) : super(key: key);

  @override
  State<ListaColetasPage> createState() => _ListaColetasPageState();
}

class _ListaColetasPageState extends State<ListaColetasPage> {
  List<Map<String, dynamic>> _coletas = [];
  bool _carregando = true;

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
      onDadosTanque: (_) {},
      onBuscarColetas: (dados) {
        setState(() {
          _coletas = dados;
          _carregando = false;
        });
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar().then((_) {
      mqtt.buscarColetas();
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

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,

        appBar: Navbar(
          title: 'Coletas do Coletor',
          style: const TextStyle(fontSize: 20),
          backPageRoute: '/homeColetor',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _coletas.isEmpty
                ? const Center(
                  child: Text(
                    'Nenhuma coleta encontrada.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _coletas.length,
                  itemBuilder: (context, index) {
                    final c = _coletas[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.white)
                                .withOpacity(isDark ? 0.08 : 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.assignment_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Coleta #${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Infos principais
                              _InfoLine(
                                label: 'Produtor',
                                value: '${c['produtor']}',
                              ),
                              _InfoLine(
                                label: 'Coletor',
                                value: '${c['coletor']}',
                              ),
                              _InfoLine(
                                label: 'ID Tanque',
                                value: '${c['idTanque']}',
                              ),
                              _InfoLine(
                                label: 'ID Região',
                                value: '${c['idRegiao']}',
                              ),
                              _InfoLine(label: 'Placa', value: '${c['placa']}'),

                              const SizedBox(height: 12),

                              // Chips de métricas
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _InfoChip(label: 'pH', value: '${c['ph']}'),
                                  _InfoChip(
                                    label: 'Temp',
                                    value: '${c['temperatura']} °C',
                                  ),
                                  _InfoChip(
                                    label: 'Nível',
                                    value: '${c['nivel']}',
                                  ),
                                  _InfoChip(
                                    label: 'NH₃',
                                    value: '${c['amonia']}',
                                  ),
                                  _InfoChip(
                                    label: 'CO₂',
                                    value: '${c['carbono']}',
                                  ),
                                  _InfoChip(
                                    label: 'CH₄',
                                    value: '${c['metano']}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

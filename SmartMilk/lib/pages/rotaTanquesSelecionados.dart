import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

class rotaTanquesSelecionadosPage extends StatefulWidget {
  const rotaTanquesSelecionadosPage({Key? key}) : super(key: key);

  @override
  State<rotaTanquesSelecionadosPage> createState() =>
      _rotaTanquesSelecionadosPageState();
}

class _rotaTanquesSelecionadosPageState
    extends State<rotaTanquesSelecionadosPage> {
  List<Map<String, dynamic>> _tanquesSelecionados = [];
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
      onBuscarColetas: (_) {},
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onBuscarVacas: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
      onBuscarTanquesSelecionados: (dados) {
        if (!mounted) return;
        setState(() {
          _tanquesSelecionados = dados;
          _carregando = false;
        });
      },
    );

    mqtt.inicializar().then((_) => _carregarComTimeout());
  }

  Future<void> _carregarComTimeout() async {
    setState(() => _carregando = true);
    mqtt.buscarTanquesSelecionados();

    await Future.delayed(const Duration(seconds: 8));
    if (mounted && _carregando) setState(() => _carregando = false);
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
          title: 'Tanques Selecionados',
          style: const TextStyle(fontSize: 20), // cor aplicada pela Navbar
          backPageRoute: '/homeColetor',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _tanquesSelecionados.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhum tanque encontrado.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _tanquesSelecionados.length,
                  itemBuilder: (context, index) {
                    final t = _tanquesSelecionados[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
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
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.22),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.25),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.map_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Tanque #${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Linhas de info
                                _InfoRow(label: 'ID', value: '${t['id']}'),
                                _InfoRow(
                                  label: 'Região',
                                  value: '${t['idregiao']}',
                                ),
                                _InfoRow(
                                  label: 'Tanque',
                                  value: '${t['idtanque']}',
                                ),
                                _InfoRow(
                                  label: 'Produtor ID',
                                  value: '${t['produtor_id']}',
                                ),
                                _InfoRow(label: 'Nome', value: '${t['nome']}'),
                                _InfoRow(
                                  label: 'Data seleção',
                                  value: '${t['created_at']}',
                                ),
                                _InfoRow(
                                  label: 'Coletor ID',
                                  value: '${t['coletor_id']}',
                                ),
                              ],
                            ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color appBlue = Color(0xFF0097B2);

/// =============== Encontrar Tanques Disponíveis =================
class EncontrarTanquesDisponiveisPage extends StatefulWidget {
  const EncontrarTanquesDisponiveisPage({Key? key}) : super(key: key);

  @override
  State<EncontrarTanquesDisponiveisPage> createState() =>
      _EncontrarTanquesDisponiveisPageState();
}

class _EncontrarTanquesDisponiveisPageState
    extends State<EncontrarTanquesDisponiveisPage> {
  List<Map<String, dynamic>> _tanques = [];
  bool _carregando = true;
  bool _flashTratado = false;
  bool _isLoading = false;

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
      onVacaDeletada: () {},
      onBuscarVacas: (_) {},
      onBuscarDevolutivas: (_) {},
      onBuscarTanquesDisponiveis: (dados) {
        if (!mounted) return;
        debugPrint('DADOS RECEBIDOS NA PÁGINA: $dados');
        setState(() {
          _tanques = dados;
          _carregando = false;
        });
      },
      onPegandoTanqueAceito: () {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coleta selecionada com sucesso!')),
        );
        // atualizar a lista:
        mqtt.buscarTanquesDisponiveis();
      },
      onPegandoTanqueNegado: (msg) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
    mqtt.inicializar().then((_) {
      _carregarComTimeout();
    });
  }

  Future<void> _carregarComTimeout() async {
    setState(() => _carregando = true);
    mqtt.buscarTanquesDisponiveis();

    // encerra loading se nada vier
    await Future.delayed(const Duration(seconds: 8));
    if (mounted && _carregando) setState(() => _carregando = false);
  }

  Future<void> executarColeta(Map<String, dynamic> tanque) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final coletor_id = prefs.getInt('id');

    final dados = {
      "idregiao": tanque['idregiao'],
      "idtanque": tanque['idtanque'],
      "produtor_id": tanque['produtor_id'],
      "nome": tanque['nome'],
      "coletor_id": coletor_id,
    };
    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'pegandoTanque/entrada',
      MqttQos.atMostOnce,
      buffer,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args['refresh'] == true) {
        setState(() => _carregando = true);
        mqtt.buscarTanquesDisponiveis();
      }
      final flash = args['flash'];
      if (!_flashTratado && flash is String && flash.isNotEmpty) {
        _flashTratado = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(flash)));
        });
      }
    }
  }

  String _fmt(dynamic v, {String dash = '-'}) {
    if (v == null) return dash;
    final s = '$v'.trim();
    return s.isEmpty ? dash : s;
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
          title: 'Tanques disponíveis',
          style: const TextStyle(fontSize: 20), // cor aplicada na Navbar
          backPageRoute: '/homeColetor',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _tanques.isEmpty
                ? const Center(
                  child: Text(
                    'Nenhum tanque disponível no momento.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: () async => _carregarComTimeout(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _tanques.length,
                    itemBuilder: (context, index) {
                      final t = _tanques[index];

                      final idTanque = _fmt(t['idtanque']);
                      final idRegiao = _fmt(t['idregiao']);
                      final statusTanque = _fmt(t['status_tanque']);
                      final produtorId = _fmt(t['produtor_id']);
                      final produtor = _fmt(t['nome']);

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
                                // Título com ícone
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.water_drop_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tanque disponível',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Linhas de info
                                _InfoLine(label: 'Produtor', value: produtor),
                                _InfoLine(
                                  label: 'Produtor ID',
                                  value: '$produtorId',
                                ),
                                _InfoLine(
                                  label: 'ID Tanque',
                                  value: '$idTanque',
                                ),
                                _InfoLine(label: 'Região', value: '$idRegiao'),

                                const SizedBox(height: 10),

                                // Chips de status
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoChip(
                                      label: 'Status',
                                      value: '$statusTanque',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Botão ação
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () => executarColeta(t),
                                    icon: const Icon(
                                      Icons.local_shipping_rounded,
                                    ),
                                    label: const Text('Coletar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: appBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

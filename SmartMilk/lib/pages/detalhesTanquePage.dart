import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

class DetalhesTanquePage extends StatefulWidget {
  final String nome;
  final int idTanque;
  final int idRegiao;
  final double ph;
  final double temp;
  final double nivel;
  final double amonia;
  final double metano;
  final double condutividade;
  final double turbidez;
  final double co2;

  const DetalhesTanquePage({
    super.key,
    required this.nome,
    required this.idTanque,
    required this.idRegiao,
    required this.ph,
    required this.temp,
    required this.nivel,
    required this.amonia,
    required this.metano,
    required this.condutividade,
    required this.turbidez,
    required this.co2,
  });

  @override
  _DetalhesTanquePageState createState() => _DetalhesTanquePageState();
}

class _DetalhesTanquePageState extends State<DetalhesTanquePage> {
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
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar();
  }

  Future<void> executarHistoricoColeta() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final coletor = prefs.getString('nome') ?? '';
    final placa = prefs.getString('placa') ?? '';

    final dados = {
      "nome": widget.nome,
      "idtanque": widget.idTanque,
      "idregiao": widget.idRegiao,
      "ph": widget.ph,
      "temperatura": widget.temp,
      "nivel": widget.nivel,
      "amonia": widget.amonia,
      "metano": widget.metano,
      "coletor": coletor,
      "placa": placa,
      "condutividade": widget.condutividade,
      "turbidez": widget.turbidez,
      "co2": widget.co2,
    };

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'cadastroHistoricoColeta/entrada',
      MqttQos.atMostOnce,
      buffer,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coleta enviada com sucesso!')),
    );
  }

  /// Marca o tanque para análise (fora de parâmetros)
  Future<void> executarColetaForaDosParametros({
    int? idtanque,
    String campo = 'status_tanque',
    String valor = 'a_ser_analisado',
  }) async {
    try {
      setState(() => _isLoading = true);

      final dados = {
        "idtanque": idtanque ?? widget.idTanque,
        "idregiao": widget.idRegiao,
        "campo": campo,
        "valor": valor,
      };

      final mensagem = jsonEncode(dados);
      final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

      mqtt.client.publishMessage(
        'atualizarStatusTanque/entrada',
        MqttQos.atMostOnce,
        buffer,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada para análise.')),
      );
      Navigator.pushNamed(context, '/resultadoQrCode');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao descartar coleta: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          title: 'QR Code • Dados do Tanque',
          style: const TextStyle(fontSize: 20),
          backPageRoute: '/homeColetor',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 720),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.white).withOpacity(
                        isDark ? 0.08 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(22),
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
                    child: _buildConteudo(isDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConteudo(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cabeçalho
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.22),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.water_damage_outlined,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tanque ${widget.idTanque} • Região ${widget.idRegiao}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Card interno com os itens
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              _buildItem('Nome', widget.nome),
              _buildDivider(),
              _buildItem('pH', widget.ph.toStringAsFixed(2)),
              _buildItem('Temperatura (°C)', widget.temp.toStringAsFixed(2)),
              _buildItem('Nível (L)', widget.nivel.toStringAsFixed(2)),
              _buildItem('Amônia (mg/L)', widget.amonia.toStringAsFixed(2)),
              _buildItem('Metano (mg/L)', widget.metano.toStringAsFixed(2)),
              _buildItem(
                'Condutividade (mS/cm)',
                widget.condutividade.toStringAsFixed(2),
              ),
              _buildItem('Turbidez (NTU)', widget.turbidez.toStringAsFixed(2)),
              _buildItem('CO2 (mg/L)', widget.co2.toStringAsFixed(2)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ações
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          setState(() => _isLoading = true);
                          await executarHistoricoColeta();
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          Navigator.pushNamed(context, '/resultadoQrCode');
                        },
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_circle_outline),
                label: const Text('Enviar Coleta'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0097B2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          setState(() => _isLoading = true);
                          await executarColetaForaDosParametros();
                          if (!mounted) return;
                          setState(() => _isLoading = false);
                          Navigator.pushNamed(context, '/resultadoQrCode');
                        },
                icon: const Icon(Icons.report_gmailerrorred_outlined),
                label: const Text('Descartar Coleta'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        width: double.infinity,
        color: const Color(0xFFE5E7EB),
      ),
    );
  }
}

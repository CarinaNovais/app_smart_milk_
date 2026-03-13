import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

const Color appBlue = Color(0xFF0097B2);

class ListaDepositosProdutorPage extends StatefulWidget {
  const ListaDepositosProdutorPage({Key? key}) : super(key: key);

  @override
  State<ListaDepositosProdutorPage> createState() =>
      _ListaDepositosProdutorPageState();
}

class _ListaDepositosProdutorPageState
    extends State<ListaDepositosProdutorPage> {
  List<Map<String, dynamic>> _depositos = [];
  String nomeProdutor = '';
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
      onBuscarDepositosProdutor: (dados) {
        setState(() {
          _depositos = dados;
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
      mqtt.buscarDepositosProdutor();
    });
  }

  String _formatarData(String dataStr) {
    try {
      final data = DateTime.parse(dataStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(data);
    } catch (e) {
      return dataStr; // Retorna como está se der erro
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
          title: 'Depósitos',
          style: const TextStyle(fontSize: 20),
          backPageRoute: '/homeProdutor',
          showEndDrawerButton: true,
        ),

        endDrawer: MenuDrawer(mqtt: mqtt),
        body:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _depositos.isEmpty
                ? const Center(child: Text('Nenhuma deposito encontrado.'))
                : ListView.builder(
                  itemCount: _depositos.length,
                  itemBuilder: (context, index) {
                    final deposito = _depositos[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Depósito #${index + 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Produtor: ${deposito['nome']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'ID Tanque: ${deposito['idTanque']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'ID Região: ${deposito['idRegiao']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _InfoChip(
                                  label: "pH",
                                  value: deposito['ph'].toString(),
                                ),
                                _InfoChip(
                                  label: "Temp",
                                  value: "${deposito['temperatura']} °C",
                                ),
                                _InfoChip(
                                  label: "Nível",
                                  value: deposito['nivel'].toString(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Data: ${_formatarData(deposito['dataDeposito'])}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

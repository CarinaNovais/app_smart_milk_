import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

const Color appBlue = Color(0xFF0097B2);

class DetalhesTanquePage extends StatefulWidget {
  final String nome;
  final int idTanque;
  final int idRegiao;
  final double ph;
  final double temp;
  final double nivel;
  final double amonia;
  final double carbono;
  final double metano;

  DetalhesTanquePage({
    required this.nome,
    required this.idTanque,
    required this.idRegiao,
    required this.ph,
    required this.temp,
    required this.nivel,
    required this.amonia,
    required this.carbono,
    required this.metano,
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
    );

    mqtt.inicializar();
  }

  Future<void> executarHistoricoColeta() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final coletor = prefs.getString('nome');
    final placa = prefs.getString('placa');

    final dados = {
      "nome": widget.nome,
      "idtanque": widget.idTanque,
      "idregiao": widget.idRegiao,
      "ph": widget.ph,
      "temperatura": widget.temp,
      "nivel": widget.nivel,
      "amonia": widget.amonia,
      "carbono": widget.carbono,
      "metano": widget.metano,
      "coletor": coletor,
      "placa": placa,
    };

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'cadastroHistoricoColeta/entrada',
      MqttQos.atMostOnce,
      buffer,
    );

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Coleta enviada com sucesso!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Qr Code Resultado - Dados do Tanque',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/homeColetor',
        showEndDrawerButton: true,
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildItem('Nome', widget.nome),
            _buildItem('ID do Tanque', widget.idTanque.toString()),
            _buildItem('ID da Região', widget.idRegiao.toString()),
            Divider(),
            _buildItem('pH', widget.ph.toStringAsFixed(2)),
            _buildItem('Temperatura (°C)', widget.temp.toStringAsFixed(2)),
            _buildItem('Nível (L)', widget.nivel.toStringAsFixed(2)),
            _buildItem('Amônia (mg/L)', widget.amonia.toStringAsFixed(2)),
            _buildItem('Carbono (mg/L)', widget.carbono.toStringAsFixed(2)),
            _buildItem('Metano (mg/L)', widget.metano.toStringAsFixed(2)),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () async {
                        setState(() {
                          _isLoading = true;
                        });

                        await executarHistoricoColeta();

                        setState(() {
                          _isLoading = false;
                        });

                        Navigator.pushNamed(context, '/resultadoQrCode');
                      },
              child:
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Enviar Coleta'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

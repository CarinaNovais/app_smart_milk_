import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io'; // Necessário para Platform.isAndroid/iOS
import 'package:flutter/foundation.dart'; // Necessário para describeEnum
import 'package:app_smart_milk/pages/detalhesTanquePage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  late MQTTService mqtt;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();

    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (msg) {},
      onCadastroAceito: () {},
      onCadastroNegado: (msg) {},
      onDadosTanque: (dados) {
        print('🚦 Callback onDadosTanque acionado');
        print('Dados recebidos via MQTT: $dados');
        if (!_isProcessing) {
          _isProcessing = true; // bloqueia nova navegação
          if (!mounted) {
            print('⚠️ Widget não está montado. Navegação cancelada.');
            return;
          }
          print('🔄 Navegando para DetalhesTanquePage');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DetalhesTanquePage(
                    nome: dados['nome'],
                    idTanque: int.parse(dados['idtanque'].toString()),
                    idRegiao: int.parse(dados['idregiao'].toString()),
                    ph: double.parse(dados['ph'].toString()),
                    temp: double.parse(dados['temp'].toString()),
                    nivel: double.parse(dados['nivel'].toString()),
                    amonia: double.parse(dados['amonia'].toString()),
                    carbono: double.parse(dados['carbono'].toString()),
                    metano: double.parse(dados['metano'].toString()),
                  ),
            ),
          ).then((_) {
            // Ao voltar da página de detalhes, libera para novo escaneamento
            print('⬅️ Voltou da página DetalhesTanquePage');
            _isProcessing = false;
            controller?.resumeCamera();
          });
        } else {
          print('⛔ Navegação bloqueada por _isProcessing = true');
        }
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
    );

    mqtt.inicializar();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child:
                  (result != null)
                      ? Text(
                        'Barcode Type: ${describeEnum(result!.format)}\nData: ${result!.code}',
                        textAlign: TextAlign.center,
                      )
                      : Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      controller.pauseCamera(); // impede múltiplas leituras seguidas
      setState(() {
        result = scanData;
      });

      print('📱 QR code escaneado: ${result?.code}');

      final data = result?.code;
      if (data != null) {
        try {
          final Map<String, dynamic> json = jsonDecode(data);
          print('📲 Dados decodificados do QR: $json');

          final String nome = json['nome'].toString(); // Garantir string
          final String idtanque = json['idtanque'].toString();
          final String idregiao = json['idregiao'].toString();

          final prefs = await SharedPreferences.getInstance();
          final int? cargo = prefs.getInt('cargo');

          if (cargo != null) {
            mqtt.buscarDadosTanque(
              nome: nome,
              idtanque: idtanque,
              idregiao: idregiao,
              cargo: cargo,
            );
          } else {
            print('⚠️ Cargo não encontrado no SharedPreferences.');
          }
        } catch (e) {
          print('Erro ao decodificar ou buscar: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

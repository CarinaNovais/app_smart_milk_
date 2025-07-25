import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/tanque_dinamico_visual.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
//import 'package:app_smart_milk/components/notifiers.dart';

const Color appBlue = Color(0xFF0097B2);

class DadosTanquePage extends StatefulWidget {
  const DadosTanquePage({super.key});

  @override
  _DadosTanquePageState createState() => _DadosTanquePageState();
}

class _DadosTanquePageState extends State<DadosTanquePage> {
  double nivel = 0.0; // nível do leite (0.0 a 1.0)
  List<String> dadosLeite = [
    '--',
    '--',
    '--',
    '--',
    '--',
    '--',
  ]; // valores dos dados
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
    return Scaffold(
      backgroundColor: appBlue,
      appBar: const Navbar(
        title: 'Dados do Tanque',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TanqueVisual(nivel: nivel),
            const SizedBox(height: 24),
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
    );
  }
}

class _DadoBox extends StatelessWidget {
  final String titulo;
  final String valor;

  const _DadoBox({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0097B2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0097B2),
            ),
          ),
        ],
      ),
    );
  }
}

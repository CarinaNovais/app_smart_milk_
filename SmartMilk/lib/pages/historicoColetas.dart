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
  String nomeColetor = '';
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
    );
    mqtt.inicializar().then((_) {
      mqtt.buscarColetas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Coletas do Coletor',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/homeColetor',
        showEndDrawerButton: true,
      ),

      endDrawer: MenuDrawer(mqtt: mqtt),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _coletas.isEmpty
              ? const Center(child: Text('Nenhuma coleta encontrada.'))
              : ListView.builder(
                itemCount: _coletas.length,
                itemBuilder: (context, index) {
                  final coleta = _coletas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🧾 Coleta #${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Produtor: ${coleta['produtor']}'),
                          Text('Coletor: ${coleta['coletor']}'),
                          Text('pH: ${coleta['ph']}'),
                          Text('Temperatura: ${coleta['temperatura']} °C'),
                          Text('Nível: ${coleta['nivel']}'),
                          Text('Amônia: ${coleta['amonia']}'),
                          Text('Carbono: ${coleta['carbono']}'),
                          Text('Metano: ${coleta['metano']}'),
                          Text('ID Tanque: ${coleta['idTanque']}'),
                          Text('ID Região: ${coleta['idRegiao']}'),
                          Text('Placa: ${coleta['placa']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

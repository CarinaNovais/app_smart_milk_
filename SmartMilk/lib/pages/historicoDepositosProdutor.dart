import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Depositos',
        style: const TextStyle(color: Colors.white, fontSize: 20),
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
                            '🧾 Deposito #${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Produtor: ${deposito['nome']}'),
                          Text('ID Tanque: ${deposito['idTanque']}'),
                          Text('ID Região: ${deposito['idRegiao']}'),
                          Text('pH: ${deposito['ph']}'),
                          Text('Temperatura: ${deposito['temperatura']} °C'),
                          Text('Nível: ${deposito['nivel']}'),
                          Text('Amônia: ${deposito['amonia']}'),
                          Text('Carbono: ${deposito['carbono']}'),
                          Text('Metano: ${deposito['metano']}'),

                          Text(
                            'Data do Depósito: ${_formatarData(deposito['dataDeposito'])}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

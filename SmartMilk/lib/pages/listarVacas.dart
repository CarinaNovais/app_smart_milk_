import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

class EditarVacaPage extends StatefulWidget {
  final Map<String, dynamic> vaca;

  const EditarVacaPage({Key? key, required this.vaca}) : super(key: key);

  @override
  State<EditarVacaPage> createState() => _EditarVacaPageState();
}

class _EditarVacaPageState extends State<EditarVacaPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _brincoController;
  late TextEditingController _criasController;
  late TextEditingController _origemController;
  late TextEditingController _estadoController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.vaca['nome']);
    _brincoController = TextEditingController(text: widget.vaca['brinco']);
    _criasController = TextEditingController(text: widget.vaca['crias']);
    _origemController = TextEditingController(text: widget.vaca['origem']);
    _estadoController = TextEditingController(text: widget.vaca['estado']);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _brincoController.dispose();
    _criasController.dispose();
    _origemController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _salvarEdicaoVaca() {
    if (_formKey.currentState!.validate()) {
      print('Dados editados:');
      print('Nome: ${_nomeController.text}');
      print('Brinco: ${_brincoController.text}');
      print('Crias: ${_criasController.text}');
      print('Origem: ${_origemController.text}');
      print('Estado: ${_estadoController.text}');

      //volta para tela anterior após salvar
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Vaca: ${widget.vaca['nome']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe o nome'
                            : null,
              ),
              TextFormField(
                controller: _brincoController,
                decoration: const InputDecoration(labelText: 'Brinco'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Informe o brinco'
                            : null,
              ),
              TextFormField(
                controller: _criasController,
                decoration: const InputDecoration(labelText: 'Crias'),
              ),
              TextFormField(
                controller: _origemController,
                decoration: const InputDecoration(labelText: 'Origem'),
              ),
              TextFormField(
                controller: _estadoController,
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarEdicaoVaca,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListaVacasPage extends StatefulWidget {
  const ListaVacasPage({Key? key}) : super(key: key);

  @override
  State<ListaVacasPage> createState() => _ListaVacasPageState();
}

class _ListaVacasPageState extends State<ListaVacasPage> {
  List<Map<String, dynamic>> _vacas = [];
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
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onBuscarVacas: (dados) {
        setState(() {
          _vacas = dados;
          _carregando = false;
        });
      },
    );
    mqtt.inicializar().then((_) {
      mqtt.buscarVacas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(
        title: 'Listagem das Vacas',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _vacas.isEmpty
              ? const Center(child: Text('Nenhuma vaca encontrada.'))
              : ListView.builder(
                itemCount: _vacas.length,
                itemBuilder: (context, index) {
                  final vaca = _vacas[index];
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
                            '🧾 Vaca #${index + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Nome: ${vaca['nome']}'),
                          Text('Brinco: ${vaca['brinco']}'),
                          Text('Crias: ${vaca['crias']}'),
                          Text('Origem: ${vaca['origem']}'),
                          Text('Estado: ${vaca['estado']}'),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navega para a página de edição, passando os dados da vaca
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditarVacaPage(vaca: vaca),
                                  ),
                                );
                              },
                              child: const Text('Editar'),
                            ),
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

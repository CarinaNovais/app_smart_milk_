import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt_client/mqtt_client.dart';

const Color appBlue = Color(0xFF0097B2);

/// ================= Editar Vaca Page =================
class EditarVacaPage extends StatefulWidget {
  final Map<String, dynamic> vaca;

  const EditarVacaPage({Key? key, required this.vaca}) : super(key: key);

  @override
  State<EditarVacaPage> createState() => _EditarVacaPageState();
}

class _EditarVacaPageState extends State<EditarVacaPage> {
  late MQTTService mqtt;

  bool editandoNome = false;
  bool editandoBrinco = false;
  bool editandoCrias = false;
  bool editandoOrigem = false;
  bool editandoEstado = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController brincoController = TextEditingController();
  final TextEditingController criasController = TextEditingController();
  final TextEditingController origemController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onFotoEditada: () {},
      onCampoAtualizado: (campo, valor) {},
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onCampoVacaAtualizado: (campo, valor) {
        // Atualiza o controller correspondente
        setState(() {
          switch (campo) {
            case 'nome':
              nomeController.text = valor;
              break;
            case 'brinco':
              brincoController.text = valor;
              break;
            case 'crias':
              criasController.text = valor;
              break;
            case 'origem':
              origemController.text = valor;
              break;
            case 'estado':
              estadoController.text = valor;
              break;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ $campo atualizado com sucesso")),
        );
      },
      onVacaDeletada: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaca excluída com sucesso!')),
          );
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => const ListaVacasPage()),
          // );
        }
      },
    );

    mqtt.inicializar();

    // Inicializa os controllers com os dados da vaca
    nomeController.text = widget.vaca['nome'] ?? '';
    brincoController.text = widget.vaca['brinco']?.toString() ?? '';
    criasController.text = widget.vaca['crias']?.toString() ?? '';
    origemController.text = widget.vaca['origem'] ?? '';
    estadoController.text = widget.vaca['estado'] ?? '';
  }

  void atualizarVacaCampo(String campo, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    final usuario_id = prefs.getInt('id');

    if (usuario_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Dados do usuário ausentes")),
      );
      return;
    }

    final vacaId = widget.vaca['vaca_id'];

    if (vacaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ ID da vaca ausente")));
      return;
    }

    final Map<String, dynamic> dados = {
      "usuario_id": usuario_id,
      "vaca_id": vacaId,
      "campo": campo,
      "valor": valor,
    };

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'editarVaca/entrada',
      MqttQos.atMostOnce,
      buffer,
    );

    Navigator.pop(context, true);
  }

  Future<void> deletarVaca() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario_id = prefs.getInt('id');

    if (usuario_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Dados do usuário ausentes")),
      );
      return;
    }

    final vacaId = widget.vaca['vaca_id'];

    if (vacaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ ID da vaca ausente")));
      return;
    }

    final Map<String, dynamic> dados = {
      "usuario_id": usuario_id,
      "vaca_id": widget.vaca['vaca_id'],
    };

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'deletarVaca/entrada',
      MqttQos.atMostOnce,
      buffer,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Vaca excluída com sucesso!")));
  }

  Future<void> salvarVacaCampo({
    required String campo,
    required String valor,
    required VoidCallback? onNotifierUpdate,
  }) async {
    atualizarVacaCampo(campo, valor);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(campo, valor);

    if (onNotifierUpdate != null) {
      onNotifierUpdate();
    }
  }

  Widget buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool editando,
    required VoidCallback onPressed,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: editando,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(editando ? 'Salvar' : 'Editar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(
        title: 'Editar Vaca: ${widget.vaca['nome']}',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/listagemVacas',
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildEditableField(
              controller: nomeController,
              label: 'Nome',
              editando: editandoNome,
              onPressed: () {
                setState(() {
                  if (editandoNome)
                    salvarVacaCampo(
                      campo: 'nome',
                      valor: nomeController.text,
                      onNotifierUpdate: null,
                    );
                  editandoNome = !editandoNome;
                });
              },
            ),
            buildEditableField(
              controller: brincoController,
              label: 'Brinco',
              editando: editandoBrinco,
              onPressed: () {
                setState(() {
                  if (editandoBrinco)
                    salvarVacaCampo(
                      campo: 'brinco',
                      valor: brincoController.text,
                      onNotifierUpdate: null,
                    );
                  editandoBrinco = !editandoBrinco;
                });
              },
            ),
            buildEditableField(
              controller: criasController,
              label: 'Crias',
              editando: editandoCrias,
              onPressed: () {
                setState(() {
                  if (editandoCrias)
                    salvarVacaCampo(
                      campo: 'crias',
                      valor: criasController.text,
                      onNotifierUpdate: null,
                    );
                  editandoCrias = !editandoCrias;
                });
              },
            ),
            buildEditableField(
              controller: origemController,
              label: 'Origem',
              editando: editandoOrigem,
              onPressed: () {
                setState(() {
                  if (editandoOrigem)
                    salvarVacaCampo(
                      campo: 'origem',
                      valor: origemController.text,
                      onNotifierUpdate: null,
                    );
                  editandoOrigem = !editandoOrigem;
                });
              },
            ),
            buildEditableField(
              controller: estadoController,
              label: 'Estado',
              editando: editandoEstado,
              onPressed: () {
                setState(() {
                  if (editandoEstado)
                    salvarVacaCampo(
                      campo: 'estado',
                      valor: estadoController.text,
                      onNotifierUpdate: null,
                    );
                  editandoEstado = !editandoEstado;
                });
              },
            ), // Botão de excluir separado, fora dos campos
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Confirmar exclusão"),
                        content: const Text(
                          "Deseja realmente excluir esta vaca?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Fecha o diálogo
                              await deletarVaca(); // Apenas envia a mensagem MQTT
                              if (mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/listagemVacas',
                                );
                              }
                            },
                            child: const Text(
                              "Excluir",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
              child: const Text("Excluir Vaca"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    brincoController.dispose();
    criasController.dispose();
    origemController.dispose();
    estadoController.dispose();
    super.dispose();
  }
}

/// ================= Lista Vacas Page =================
class ListaVacasPage extends StatefulWidget {
  const ListaVacasPage({Key? key}) : super(key: key);

  @override
  State<ListaVacasPage> createState() => _ListaVacasPageState();
}

class _ListaVacasPageState extends State<ListaVacasPage> {
  List<Map<String, dynamic>> _vacas = [];
  String nomeProdutor = '';
  bool _carregando = true;
  bool _flashTratado = false;

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
        if (!mounted) return;
        setState(() {
          _vacas = dados;
          _carregando = false;
        });
      },

      onVacaDeletada: () {
        if (!mounted) return;
        setState(() => _carregando = true);
        mqtt.buscarVacas();
      },
    );
    mqtt.inicializar().then((_) {
      _carregarComTimeout();
    });
  }

  Future<void> _carregarComTimeout() async {
    setState(() => _carregando = true);
    mqtt.buscarVacas();

    // ✅ encerra loading se nada vier
    await Future.delayed(const Duration(seconds: 8));
    if (mounted && _carregando) {
      setState(() => _carregando = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Declare só uma vez
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      // 1) Recarrega lista se veio com refresh
      if (args['refresh'] == true) {
        setState(() => _carregando = true);
        mqtt.buscarVacas();
      }

      // 2) Mostra flash UMA VEZ e limpa
      final flash = args['flash'];
      if (!_flashTratado && flash is String && flash.isNotEmpty) {
        _flashTratado = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(flash)));
          // Navigator.pushReplacementNamed(context, '/listagemVacas');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Listagem das Vacas',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/monitoramentoVacas',
        showEndDrawerButton: true,
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                              onPressed: () async {
                                final atualizado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditarVacaPage(vaca: vaca),
                                  ),
                                );

                                if (atualizado == true) {
                                  setState(() {
                                    _carregando = true;
                                  });
                                  mqtt.buscarVacas();
                                }
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

  // @override
  // void dispose() {
  //   mqtt.client.disconnect();
  //   super.dispose();
  // }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

import 'dart:ui';

const Color appBlue = Color(0xFF0097B2);

/// ================= Editar Vaca =================
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vaca excluída com sucesso!')),
        );
      },
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar();

    // carrega valores iniciais nos controllers
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

    final dados = {
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

    final dados = {"usuario_id": usuario_id, "vaca_id": vacaId};
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
    onNotifierUpdate?.call();
  }

  Widget _editableField({
    required TextEditingController controller,
    required String label,
    required bool editando,
    required VoidCallback onPressed,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassSection(
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: editando,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Color(0xFFF5F5F5)),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF5F5F5)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF5F5F5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: appBlue,
              ),
              child: Text(editando ? 'Salvar' : 'Editar'),
            ),
          ],
        ),
      ),
    );
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
          title: 'Editar Vaca: ${widget.vaca['nome']}',
          style: const TextStyle(fontSize: 20),
          backPageRoute: '/listagemVacas',
          showEndDrawerButton: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _editableField(
                controller: nomeController,
                label: 'Nome',
                editando: editandoNome,
                onPressed: () {
                  setState(() {
                    if (editandoNome) {
                      salvarVacaCampo(
                        campo: 'nome',
                        valor: nomeController.text,
                        onNotifierUpdate: null,
                      );
                    }
                    editandoNome = !editandoNome;
                  });
                },
              ),
              _editableField(
                controller: brincoController,
                label: 'Brinco',
                editando: editandoBrinco,
                onPressed: () {
                  setState(() {
                    if (editandoBrinco) {
                      salvarVacaCampo(
                        campo: 'brinco',
                        valor: brincoController.text,
                        onNotifierUpdate: null,
                      );
                    }
                    editandoBrinco = !editandoBrinco;
                  });
                },
              ),
              _editableField(
                controller: criasController,
                label: 'Crias',
                editando: editandoCrias,
                onPressed: () {
                  setState(() {
                    if (editandoCrias) {
                      salvarVacaCampo(
                        campo: 'crias',
                        valor: criasController.text,
                        onNotifierUpdate: null,
                      );
                    }
                    editandoCrias = !editandoCrias;
                  });
                },
              ),
              _editableField(
                controller: origemController,
                label: 'Origem',
                editando: editandoOrigem,
                onPressed: () {
                  setState(() {
                    if (editandoOrigem) {
                      salvarVacaCampo(
                        campo: 'origem',
                        valor: origemController.text,
                        onNotifierUpdate: null,
                      );
                    }
                    editandoOrigem = !editandoOrigem;
                  });
                },
              ),
              _editableField(
                controller: estadoController,
                label: 'Estado',
                editando: editandoEstado,
                onPressed: () {
                  setState(() {
                    if (editandoEstado) {
                      salvarVacaCampo(
                        campo: 'estado',
                        valor: estadoController.text,
                        onNotifierUpdate: null,
                      );
                    }
                    editandoEstado = !editandoEstado;
                  });
                },
              ),
              const SizedBox(height: 12),
              _GlassSection(
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
                                        Navigator.pop(context);
                                        await deletarVaca();
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
                    ),
                  ],
                ),
              ),
            ],
          ),
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

/// ================= Lista Vacas =================
class ListaVacasPage extends StatefulWidget {
  const ListaVacasPage({Key? key}) : super(key: key);

  @override
  State<ListaVacasPage> createState() => _ListaVacasPageState();
}

class _ListaVacasPageState extends State<ListaVacasPage> {
  List<Map<String, dynamic>> _vacas = [];
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
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar().then((_) => _carregarComTimeout());
  }

  Future<void> _carregarComTimeout() async {
    setState(() => _carregando = true);
    mqtt.buscarVacas();
    await Future.delayed(const Duration(seconds: 8));
    if (mounted && _carregando) setState(() => _carregando = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args['refresh'] == true) {
        setState(() => _carregando = true);
        mqtt.buscarVacas();
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
          title: 'Listagem das Vacas',
          style: const TextStyle(fontSize: 20),
          backPageRoute: '/monitoramentoVacas',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _vacas.isEmpty
                ? const Center(
                  child: Text(
                    'Nenhuma vaca encontrada.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _vacas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vaca = _vacas[index];
                    return _GlassSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vaca #${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _kv('Nome', '${vaca['nome']}'),
                          _kv('Brinco', '${vaca['brinco']}'),
                          _kv('Crias', '${vaca['crias']}'),
                          _kv('Origem', '${vaca['origem']}'),
                          _kv('Estado', '${vaca['estado']}'),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: appBlue,
                              ),
                              onPressed: () async {
                                final atualizado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditarVacaPage(vaca: vaca),
                                  ),
                                );
                                if (atualizado == true) {
                                  setState(() => _carregando = true);
                                  mqtt.buscarVacas();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$k:',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(v, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/// ======= Glass section reutilizável =======
class _GlassSection extends StatelessWidget {
  final Widget child;
  const _GlassSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.08 : 0.14,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

const Color appBlue = Color(0xFF0097B2);

/// =============== Encontrar Tanques Disponíveis =================
class EncontrarTanquesDisponiveisPage extends StatefulWidget {
  const EncontrarTanquesDisponiveisPage({Key? key}) : super(key: key);

  @override
  State<EncontrarTanquesDisponiveisPage> createState() =>
      _EncontrarTanquesDisponiveisPageState();
}

class _EncontrarTanquesDisponiveisPageState
    extends State<EncontrarTanquesDisponiveisPage> {
  List<Map<String, dynamic>> _tanques = [];
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
      onVacaDeletada: () {},
      onBuscarVacas: (_) {},
      onBuscarDevolutivas: (_) {},
      onBuscarTanquesDisponiveis: (dados) {
        if (!mounted) return;
        debugPrint('DADOS RECEBIDOS NA PÁGINA: $dados');
        setState(() {
          _tanques = dados;
          _carregando = false;
        });
      },
    );
    mqtt.inicializar().then((_) {
      _carregarComTimeout();
    });
  }

  Future<void> _carregarComTimeout() async {
    setState(() => _carregando = true);
    mqtt.buscarTanquesDisponiveis();

    // encerra loading se nada vier
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
        mqtt.buscarTanquesDisponiveis();
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

  String _fmt(dynamic v, {String dash = '-'}) {
    if (v == null) return dash;
    final s = '$v'.trim();
    return s.isEmpty ? dash : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Tanques disponíveis',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/homeColetor',
        showEndDrawerButton: true,
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _tanques.isEmpty
              ? const Center(
                child: Text(
                  'Nenhum tanque disponível no momento.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async => _carregarComTimeout(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _tanques.length,
                  itemBuilder: (context, index) {
                    final t = _tanques[index];

                    // Campos comuns esperados do backend (ajuste se necessário)

                    final idTanque = _fmt(t['idtanque']);
                    final idRegiao = _fmt(t['idregiao']);
                    final status_tanque = _fmt(t['status_tanque']);
                    final produtor_id = _fmt(t['produtor_id']);
                    final produtor = _fmt(t['nome']);

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
                              '🧪 Tanque #${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 16,
                              runSpacing: 4,
                              children: [
                                Text('ID Tanque: $idTanque'),
                                Text('Região: $idRegiao'),
                                Text('Status: $status_tanque'),
                                Text('Produtor ID: $produtor_id'),
                                Text('Produtor: $produtor'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // ação de coleta
                                      // mqtt.iniciarColeta(
                                      //   idTanque: '$idTanque',
                                      //   idRegiao: '$idRegiao',
                                      // );
                                    },
                                    icon: const Icon(Icons.local_shipping),
                                    label: const Text('Coletar'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
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

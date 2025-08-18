import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt_client/mqtt_client.dart';

const Color appBlue = Color(0xFF0097B2);

/// ================= Lista Devolutiva do Lab dos Leites =================
class ListaDevolutivaLaboratorioPage extends StatefulWidget {
  const ListaDevolutivaLaboratorioPage({Key? key}) : super(key: key);

  @override
  State<ListaDevolutivaLaboratorioPage> createState() =>
      _ListaDevolutivaLaboratorioPageState();
}

class _ListaDevolutivaLaboratorioPageState
    extends State<ListaDevolutivaLaboratorioPage> {
  List<Map<String, dynamic>> _devolutivas = [];
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
      onBuscarVacas: (dados) {},
      onVacaDeletada: () {},
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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Listagem das devolutivas do Laboratorio',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/homeProdutor',
        showEndDrawerButton: true,
      ),

      endDrawer: MenuDrawer(mqtt: mqtt),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _devolutivas.isEmpty
              ? const Center(child: Text('Nenhuma devolutiva encontrada.'))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionPanelList.radio(
                    elevation: 2,
                    expandedHeaderPadding: EdgeInsets.zero,
                    children: List.generate(_devolutivas.length, (index) {
                      final d = _devolutivas[index];
                      final value = d['id'] ?? index;

                      return ExpansionPanelRadio(
                        value: value,
                        headerBuilder:
                            (ctx, isExpanded) => ListTile(
                              title: Text(
                                '🧾 Devolutiva #${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                        body: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white, // fundo branco
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${d['id']}'),
                              Text('Coleta ID: ${d['coleta_id']}'),
                              Text('Gordura: ${d['gordura']}'),
                              Text('Proteína: ${d['proteina']}'),
                              Text('Lactose: ${d['lactose']}'),
                              Text('Sólidos Totais: ${d['solidos_totais']}'),
                              Text(
                                'Sólidos Não Gordurosos: ${d['solidos_nao_gord']}',
                              ),
                              Text('Densidade: ${d['densidade']}'),
                              Text('Crioscopia: ${d['crioscopia']}'),
                              Text('pH: ${d['ph']}'),
                              Text('CBT: ${d['cbt']}'),
                              Text('CCS: ${d['ccs']}'),
                              Text('Patógenos: ${d['patogenos']}'),
                              Text(
                                'Antibióticos (positivo): ${d['antibioticos_pos']}',
                              ),
                              Text(
                                'Antibióticos (descrição): ${d['antibioticos_desc']}',
                              ),
                              Text(
                                'Resíduos Químicos: ${d['residuos_quimicos']}',
                              ),
                              Text('Aflatoxina M1: ${d['aflatoxina_m1']}'),
                              Text(
                                'Estabilidade ao Álcool: ${d['estabilidade_alc']}',
                              ),
                              Text('Índice de Acidez: ${d['indice_acidez']}'),
                              Text(
                                'Tempo de Redução Azul: ${d['tempo_reduc_azul']}',
                              ),
                              Text('Valor por Litro: ${d['valor_litro']}'),
                              Text('Laboratório: ${d['laboratorio']}'),
                              Text('Data do Laudo: ${d['laudo_data']}'),
                              Text('Observações: ${d['observacoes']}'),
                              Text('Criado em: ${d['created_at']}'),
                              Text('Atualizado em: ${d['updated_at']}'),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
    );
  }
}

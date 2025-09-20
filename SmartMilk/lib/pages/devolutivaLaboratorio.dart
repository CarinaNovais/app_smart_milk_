import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

const Color appBlue = Color(0xFF0097B2);

class ListaDevolutivaLaboratorioPage extends StatefulWidget {
  const ListaDevolutivaLaboratorioPage({Key? key}) : super(key: key);

  @override
  State<ListaDevolutivaLaboratorioPage> createState() =>
      _ListaDevolutivaLaboratorioPageState();
}

class _ListaDevolutivaLaboratorioPageState
    extends State<ListaDevolutivaLaboratorioPage> {
  List<Map<String, dynamic>> _devolutivas = [];
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
      onBuscarDevolutivas: (List<Map<String, dynamic>> dados) {
        if (!mounted) return;
        setState(() {
          _devolutivas = dados;
          _carregando = false;
        });
      },
      onPegandoTanqueAceito: () {},
    );

    mqtt.inicializar().then((_) {
      _carregarComTimeout();
    });
  }

  Future<void> _carregarComTimeout() async {
    setState(() => _carregando = true);
    mqtt.buscarDevolutivas();

    await Future.delayed(const Duration(seconds: 8));
    if (mounted && _carregando) {
      setState(() => _carregando = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      if (args['refresh'] == true) {
        setState(() => _carregando = true);
        mqtt.buscarDevolutivas();
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
          title: 'Devolutivas do Laboratório',
          style: const TextStyle(fontSize: 20), // cor tratada dentro da Navbar
          backPageRoute: '/homeProdutor',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _devolutivas.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhuma devolutiva encontrada.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: _GlassCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: ExpansionPanelList.radio(
                        elevation: 0,
                        expandedHeaderPadding: EdgeInsets.zero,
                        children: List.generate(_devolutivas.length, (index) {
                          final d = _devolutivas[index];
                          final value = d['id'] ?? index;

                          return ExpansionPanelRadio(
                            value: value,
                            canTapOnHeader: true,
                            headerBuilder:
                                (ctx, isExpanded) => ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  leading: Icon(
                                    Icons.science_outlined,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF0B7D95),
                                  ),
                                  title: Text(
                                    'Devolutiva #${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : const Color(0xFF0B7D95),
                                    ),
                                  ),
                                  subtitle:
                                      d['laudo_data'] != null
                                          ? Text(
                                            'Laudo: ${d['laudo_data']}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.85,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                            body: _DevolutivaBody(dados: d),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.08 : 0.14,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DevolutivaBody extends StatelessWidget {
  final Map<String, dynamic> dados;
  const _DevolutivaBody({required this.dados});

  Widget _row(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color.fromARGB(255, 0, 151, 178),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              '${value ?? '-'}',
              style: const TextStyle(color: Color.fromARGB(255, 0, 151, 178)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _InnerGlass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('ID', dados['id']),
          _row('Coleta ID', dados['coleta_id']),
          _row('Gordura', dados['gordura']),
          _row('Proteína', dados['proteina']),
          _row('Lactose', dados['lactose']),
          _row('Sólidos Totais', dados['solidos_totais']),
          _row('Sólidos Não Gordurosos', dados['solidos_nao_gord']),
          _row('Densidade', dados['densidade']),
          _row('Crioscopia', dados['crioscopia']),
          _row('pH', dados['ph']),
          _row('CBT', dados['cbt']),
          _row('CCS', dados['ccs']),
          _row('Patógenos', dados['patogenos']),
          _row('Antibióticos (positivo)', dados['antibioticos_pos']),
          _row('Antibióticos (descrição)', dados['antibioticos_desc']),
          _row('Resíduos Químicos', dados['residuos_quimicos']),
          _row('Aflatoxina M1', dados['aflatoxina_m1']),
          _row('Estabilidade ao Álcool', dados['estabilidade_alc']),
          _row('Índice de Acidez', dados['indice_acidez']),
          _row('Tempo de Redução Azul', dados['tempo_reduc_azul']),
          _row('Valor por Litro', dados['valor_litro']),
          _row('Laboratório', dados['laboratorio']),
          _row('Data do Laudo', dados['laudo_data']),
          _row('Observações', dados['observacoes']),
          _row('Criado em', dados['created_at']),
          _row('Atualizado em', dados['updated_at']),
        ],
      ),
    );
  }
}

class _InnerGlass extends StatelessWidget {
  final Widget child;
  const _InnerGlass({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: child,
      ),
    );
  }
}

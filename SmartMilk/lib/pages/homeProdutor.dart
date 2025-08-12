import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/components/home_grid.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/notifiers.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class HomeProdutorPage extends StatefulWidget {
  const HomeProdutorPage({super.key});

  @override
  State<HomeProdutorPage> createState() => _HomeProdutorPageState();
}

class _HomeProdutorPageState extends State<HomeProdutorPage> {
  String nomeUsuario = '';

  final List<GridItem> items = [
    GridItem(
      imagePath: 'lib/images/dadosCoperativa.png',
      route: '/page1',
      legenda: 'Dados Cooperativa',
    ),
    GridItem(
      imagePath: 'lib/images/paginaAvisos.png',
      route: '/page2',
      legenda: 'Avisos',
    ),
    GridItem(
      imagePath: 'lib/images/historicoDepositos.png',
      route: '/depositosProdutor',
      legenda: 'Histórico Depósitos',
    ),
    GridItem(
      imagePath: 'lib/images/statusTanque.png',
      route: '/dadosTanque',
      legenda: 'Status Tanque',
    ),
    GridItem(
      imagePath: 'lib/images/semFuncao.png',
      route: '/',
      legenda: 'Sem Função',
    ),
    GridItem(
      imagePath: 'lib/images/monitoramentoVacas.png',
      route: '/monitoramentoVacas',
      legenda: 'Monitoramento Vacas',
    ),
  ];

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();
    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onDadosTanque: (_) {},
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
    );
    mqtt.inicializar();
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('nome') ?? 'Usuário';
    });
    //Atualiza o notifier para refletir no MenuDrawer
    nomeUsuarioNotifier.value = nomeUsuario;

    if (nomeUsuario == 'Usuário') {
      print('⚠️ Nenhum nome encontrado na sessão.');
    } else {
      print('✅ Nome do usuário carregado: $nomeUsuario');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: const Navbar(
        title: 'Bem-vindo!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HomeGrid(
          items: items,
          onItemTap: (item) => Navigator.pushNamed(context, item.route),
        ),
      ),
    );
  }
}

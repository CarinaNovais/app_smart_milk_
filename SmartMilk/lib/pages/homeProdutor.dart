import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/components/home_grid.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

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
      route: '/page3',
      legenda: 'Histórico Depósitos',
    ),
    GridItem(
      imagePath: 'lib/images/statusTanque.png',
      route: '/dadosTanque',
      legenda: 'Status Tanque',
    ),
    GridItem(
      imagePath: 'lib/images/qrCode.png',
      route: '/page5',
      legenda: 'Qr Code',
    ),
    GridItem(
      imagePath: 'lib/images/monitoramentoVacas.png',
      route: '/page6',
      legenda: 'Monitoramento Vacas',
    ),
  ];

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();

    mqtt = MQTTService(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onDadosTanque: (_) {},
    );
    mqtt.inicializar();
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeUsuario = prefs.getString('nome') ?? 'Usuário';
    });

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
      endDrawer: const MenuDrawer(),
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

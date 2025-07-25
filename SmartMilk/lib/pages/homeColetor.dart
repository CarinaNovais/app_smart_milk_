import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/components/home_grid.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class HomeColetorPage extends StatefulWidget {
  const HomeColetorPage({super.key});

  @override
  State<HomeColetorPage> createState() => _HomeColetorPageState();
}

class _HomeColetorPageState extends State<HomeColetorPage> {
  String nomeUsuario = '';
  String? contatoUsuario = '';
  String fotoBase64 = '';
  int? cargoUsuario;

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
      imagePath: 'lib/images/historicoColetas.png',
      route: '/page3',
      legenda: 'Histórico Coletas',
    ),
    GridItem(
      imagePath: 'lib/images/semFuncao.png',
      route: '/dadosTanque',
      legenda: 'Sem Funcao',
    ),
    GridItem(
      imagePath: 'lib/images/qrCode.png',
      route: '/qrCode',
      legenda: 'Qr Code',
    ),
    GridItem(
      imagePath: 'lib/images/semFuncao.png',
      route: '/page6',
      legenda: 'Sem Funcao',
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
    );
    mqtt.inicializar();
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome') ?? 'Usuário';

    setState(() {
      nomeUsuario = nome;
    });

    if (nome == 'Usuário') {
      print('⚠️ Nenhum nome encontrado na sessão.');
    } else {
      print('✅ Nome do usuário carregado: $nome');
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

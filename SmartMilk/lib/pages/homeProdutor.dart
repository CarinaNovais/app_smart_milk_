import 'package:app_smart_milk/components/home_grid.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'dart:convert'; // para base64Decode

late MQTTService mqtt;

const Color appBlue = Color(0xFF0097B2);

class HomeProdutorPage extends StatefulWidget {
  const HomeProdutorPage({super.key});

  @override
  _HomeProdutorPageState createState() => _HomeProdutorPageState();
}

class _HomeProdutorPageState extends State<HomeProdutorPage> {
  String nomeUsuario = '';

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

  //fazer essa funcao ficar universal
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
      appBar: Navbar(
        title: 'Bem-vindo!',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        onNotificationPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notificações zeradas')));
        },
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(nomeUsuario),
              accountEmail: const Text('Email'),
              currentAccountPicture: FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: appBlue, size: 40),
                    );
                  }

                  final fotoBase64 = snapshot.data!.getString('foto');
                  if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                    final imageBytes = base64Decode(fotoBase64);
                    return CircleAvatar(
                      backgroundImage: MemoryImage(imageBytes),
                    );
                  } else {
                    return const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: appBlue, size: 40),
                    );
                  }
                },
              ),

              decoration: const BoxDecoration(color: appBlue),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () => Navigator.of(context).pushNamed('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () => Navigator.of(context).pushNamed('/perfil'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () => Navigator.of(context).pushNamed('/configuracoes'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                await mqtt.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HomeGrid(
          items: items,
          onItemTap: (item) {
            Navigator.pushNamed(context, item.route);
          },
        ),
      ),
    );
  }
}

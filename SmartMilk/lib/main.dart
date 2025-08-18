//gerais
import 'package:app_smart_milk/pages/historicoDepositosProdutor.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/cadastro_page.dart';
import 'package:app_smart_milk/pages/index.dart';
import 'package:app_smart_milk/pages/login_page.dart';
import 'package:app_smart_milk/pages/perfil.dart';
import 'package:app_smart_milk/pages/configuracoes.dart';
import 'package:app_smart_milk/pages/resultadoQrCode.dart';
import 'package:app_smart_milk/pages/dadosCooperativa.dart';
import 'package:app_smart_milk/pages/listarVacas.dart';
//produtor
import 'package:app_smart_milk/pages/homeProdutor.dart';
import 'package:app_smart_milk/pages/tanque_usuario.dart';
import 'package:app_smart_milk/pages/monitoramentoVacas.dart';

//coletor
import 'package:app_smart_milk/pages/qrCode_page.dart';
import 'package:app_smart_milk/pages/homeColetor.dart';
import 'package:app_smart_milk/pages/historicoColetas.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MQTTService mqttService = MQTTService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Define a página inicial
      routes: {
        '/': (context) => IndexPage(), // Página inicial
        '/login': (context) => LoginPage(cargo: 1),
        '/homeProdutor': (context) => HomeProdutorPage(),
        '/cadastro': (context) => CadastroPage(),
        '/dadosTanque': (context) => DadosTanquePage(),
        '/perfil': (context) => PerfilPage(),
        '/configuracoes': (context) => ConfiguracoesPage(),
        '/depositosProdutor':
            (context) =>
                ListaDepositosProdutorPage(), //historico depositos produtor
        '/historicoColeta':
            (context) => ListaColetasPage(), // historico coletas coletor
        '/qrCode': (context) => QRViewExample(),
        '/homeColetor': (context) => HomeColetorPage(),
        '/resultadoQrCode': (context) => ResultadoQrCodePage(mqtt: mqttService),
        '/monitoramentoVacas':
            (context) => monitoramentoVacasPage(mqtt: mqttService),
        '/dadosCooperativa': (context) => DadoscooperativaPage(),
        '/listagemVacas': (context) => ListaVacasPage(),
      },
    );
  }
}

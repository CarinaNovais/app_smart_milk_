import 'package:app_smart_milk/pages/cadastro_page.dart';
import 'package:app_smart_milk/pages/homeProdutor.dart';
import 'package:app_smart_milk/pages/tanque_usuario.dart';
import 'package:flutter/material.dart';
//import 'pages/index.dart';
//import 'package:app_smart_milk/pages/login_page.dart';
//import 'package:app_smart_milk/pages/qrCode_page.dart';
//import 'package:http/http.dart' as http;
//import 'dart:convert';
//import 'package:app_smart_milk/pages/mqtt_service.dart';
//import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/index.dart';
import 'package:app_smart_milk/pages/login_page.dart';
//import 'package:app_smart_milk/pages/homeProdutor.dart';

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
        // '/': (context) => QRViewExample(), // Página inicial
        '/': (context) => IndexPage(), // Página inicial
        '/login': (context) => LoginPage(cargo: 1), // Página de login
        '/homeProdutor': (context) => HomeProdutorPage(),
        '/cadastro': (context) => CadastroPage(),
        '/dadosTanque': (context) => DadosTanquePage(),
      },
    );
  }
}

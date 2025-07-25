import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

const Color appBlue = Color(0xFF0097B2);

class DepositosprodutorPage extends StatefulWidget {
  const DepositosprodutorPage({super.key});

  @override
  State<DepositosprodutorPage> createState() => _DepositosprodutorPage();
}

class _DepositosprodutorPage extends State<DepositosprodutorPage> {
  final mqtt = MQTTService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: const Navbar(
        title: 'Depósitos',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: const Center(
        child: Text(
          'Conteúdo da tela de depósitos será exibido aqui',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

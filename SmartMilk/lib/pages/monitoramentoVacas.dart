import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/pages/listarVacas.dart';
import 'package:app_smart_milk/pages/cadastroVacas.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);

class monitoramentoVacasPage extends StatelessWidget {
  final MQTTService mqtt;

  const monitoramentoVacasPage({super.key, required this.mqtt});

  void acaoBotaoListarVacas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ListaVacasPage()),
    );
  }

  void acaoBotaoCadastrarVacas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CadastroVacasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Monitoramento das Vacas',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/homeProdutor',
        showEndDrawerButton: true,
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Conteúdo central
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botão Listar Vacas
                  MyButton(
                    onTap: () => acaoBotaoListarVacas(context),
                    text: 'Listar Vacas',
                  ),
                  const SizedBox(height: 20),

                  // Botão Cadastrar Vaca
                  MyButton(
                    onTap: () => acaoBotaoCadastrarVacas(context),
                    text: 'Cadastrar Nova Vaca',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

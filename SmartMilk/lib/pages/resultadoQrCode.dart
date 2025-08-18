import 'package:app_smart_milk/pages/qrCode_page.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);

class ResultadoQrCodePage extends StatelessWidget {
  final MQTTService mqtt;
  const ResultadoQrCodePage({super.key, required this.mqtt});

  void acaoBotaoNovaColeta(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => QRViewExample()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Coleta Enviada',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/homeColetor', // seta vai direto para esta página
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
                  // Logo
                  Image.asset(
                    'lib/images/VACALOGO.jpg',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 40),

                  // Texto informativo
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Coleta enviada com sucesso!\nSe quiser fazer outra coleta, é só clicar no botão abaixo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),

                  const SizedBox(height: 40),
                  // Botão Produtor
                  MyButton(
                    onTap: () => acaoBotaoNovaColeta(context),
                    text: 'Nova Coleta',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

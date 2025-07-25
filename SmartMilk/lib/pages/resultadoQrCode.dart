import 'package:app_smart_milk/pages/qrCode_page.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';

class ResultadoQrCodePage extends StatelessWidget {
  const ResultadoQrCodePage({super.key});

  void acaoBotaoNovaColeta(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => QRViewExample()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
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

import 'package:app_smart_milk/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  void acaoBotaoProdutor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(idCargo: 0),
      ), // identifica que é produtor
    );
  }

  void acaoBotaoColetor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(idCargo: 1),
      ), // identifica que é coletor
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Espaço para logo
              Image.asset('lib/images/VACALOGO.jpg', height: 100, width: 100),
              const SizedBox(height: 40),

              // Botão 1
              MyButton(
                onTap: () => acaoBotaoProdutor(context),
                text: 'Produtor',
              ),
              const SizedBox(height: 20),

              // Botão 2
              MyButton(onTap: () => acaoBotaoColetor(context), text: 'Coletor'),
            ],
          ),
        ),
      ),
    );
  }
}

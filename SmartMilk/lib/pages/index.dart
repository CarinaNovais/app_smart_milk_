import 'package:app_smart_milk/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  void acaoBotaoProdutor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(cargo: 0)),
    );
  }

  void acaoBotaoColetor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(cargo: 1)),
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

                  // Botão Produtor
                  MyButton(
                    onTap: () => acaoBotaoProdutor(context),
                    text: 'Produtor',
                  ),
                  const SizedBox(height: 20),

                  // Botão Coletor
                  MyButton(
                    onTap: () => acaoBotaoColetor(context),
                    text: 'Coletor',
                  ),
                ],
              ),
            ),

            // Linha inferior com o link de cadastro
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Primeira vez?',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/cadastro',
                        arguments: {
                          'cargo': 0,
                        }, // ou altere conforme necessário
                      );
                    },
                    child: const Text(
                      'Cadastre-se agora',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

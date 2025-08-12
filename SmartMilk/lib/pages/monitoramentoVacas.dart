import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/pages/listarVacas.dart';
import 'package:app_smart_milk/pages/cadastroVacas.dart';

class monitoramentoVacasPage extends StatelessWidget {
  const monitoramentoVacasPage({super.key});

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

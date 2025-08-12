import 'package:flutter/material.dart';
import 'my_textField.dart';

class CadastroVacaForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController brincoController;
  final TextEditingController criasController;
  final TextEditingController origemController;
  final TextEditingController estadoController;

  const CadastroVacaForm({
    super.key,
    required this.nomeController,
    required this.brincoController,
    required this.criasController,
    required this.origemController,
    required this.estadoController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyTextField(
          controller: nomeController,
          hintText: 'Nome da Vaca',
          obscureText: false,
        ),
        MyTextField(
          controller: brincoController,
          hintText: 'Brinco',
          obscureText: false,
        ),
        MyTextField(
          controller: criasController,
          hintText: 'Quantidade de Crias',
          obscureText: false,
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: origemController,
          hintText: 'Origem',
          obscureText: false,
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: estadoController,
          hintText: 'Estado',
          obscureText: false,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'my_textField.dart';

class CadastroComplementarForm extends StatelessWidget {
  final TextEditingController outroUsuarioNomeController;

  const CadastroComplementarForm({
    super.key,
    required this.outroUsuarioNomeController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        MyTextField(
          controller: outroUsuarioNomeController,
          hintText: 'Nome do outro Usuário',
          obscureText: false,
        ),
      ],
    );
  }
}

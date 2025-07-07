import 'package:flutter/material.dart';
import 'my_textField.dart';

class CadastroForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController idregiaoController;
  final TextEditingController idtanqueController;
  final TextEditingController contatoController;
  final TextEditingController senhaController;
  final TextEditingController confirmarSenhaController;

  const CadastroForm({
    super.key,
    required this.nomeController,
    required this.idregiaoController,
    required this.idtanqueController,
    required this.contatoController,
    required this.senhaController,
    required this.confirmarSenhaController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyTextField(
          controller: nomeController,
          hintText: 'Nome completo',
          obscureText: false,
        ),
        MyTextField(
          controller: idregiaoController,
          hintText: 'ID Região',
          obscureText: false,
        ),
        MyTextField(
          controller: idtanqueController,
          hintText: 'ID Tanque',
          obscureText: false,
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: contatoController,
          hintText: 'Telefone',
          obscureText: false,
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: senhaController,
          hintText: 'Senha',
          obscureText: true,
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: confirmarSenhaController,
          hintText: 'Confirmar senha',
          obscureText: true,
        ),
      ],
    );
  }
}

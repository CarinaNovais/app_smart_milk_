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
        const SizedBox(height: 12),
        MyTextField(
          controller: nomeController,
          hintText: 'Nome completo',
          obscureText: false,
        ),
        const SizedBox(height: 12),
        MyTextField(
          controller: idregiaoController,
          hintText: 'ID Região',
          obscureText: false,
        ),
        const SizedBox(height: 12),
        MyTextField(
          controller: idtanqueController,
          hintText: 'ID Tanque',
          obscureText: false,
        ),
        const SizedBox(height: 12),
        MyTextField(
          controller: contatoController,
          hintText: 'Telefone',
          obscureText: false,
        ),
        const SizedBox(height: 12),
        MyTextField(
          controller: senhaController,
          hintText: 'Senha',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        MyTextField(
          controller: confirmarSenhaController,
          hintText: 'Confirmar senha',
          obscureText: true,
        ),
      ],
    );
  }
}

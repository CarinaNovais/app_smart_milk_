import 'package:flutter/material.dart';
import 'my_textField.dart';

class CadastroForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController regiaoController;
  final TextEditingController idTanqueController;
  final TextEditingController telefoneController;
  final TextEditingController enderecoController;
  final TextEditingController emailController;
  final TextEditingController senhaController;
  final TextEditingController confirmarSenhaController;

  const CadastroForm({
    super.key,
    required this.nomeController,
    required this.regiaoController,
    required this.idTanqueController,
    required this.telefoneController,
    required this.enderecoController,
    required this.emailController,
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
          controller: regiaoController,
          hintText: 'Região',
          obscureText: false,
        ),
        MyTextField(
          controller: idTanqueController,
          hintText: 'ID Tanque',
          obscureText: false,
        ),
        MyTextField(
          controller: telefoneController,
          hintText: 'Telefone',
          obscureText: false,
        ),
        MyTextField(
          controller: enderecoController,
          hintText: 'Endereço',
          obscureText: false,
        ),
        const SizedBox(height: 10),
        MyTextField(
          controller: emailController,
          hintText: 'E-mail',
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

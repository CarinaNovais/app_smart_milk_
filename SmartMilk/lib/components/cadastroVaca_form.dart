import 'package:flutter/material.dart';

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
          keyboardType: TextInputType.number,
        ),
        MyTextField(
          controller: criasController,
          hintText: 'Quantidade de Crias',
          obscureText: false,
          keyboardType: TextInputType.number,
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

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(isDark ? 0.08 : 0.14),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    );
  }
}

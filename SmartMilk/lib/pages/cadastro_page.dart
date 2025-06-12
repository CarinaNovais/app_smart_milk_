import 'package:app_smart_milk/components/cadastro_complementar.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/cadastro_form.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  bool mostrarFormularioAdicional = false;

  final nomeController = TextEditingController();
  final regiaoController = TextEditingController();
  final idTanqueController = TextEditingController();
  final telefoneController = TextEditingController();
  final enderecoController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final outroUsuarioNomeController = TextEditingController();

  void cadastrarUsuario() {
    //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // logo
                Image.asset('lib/images/VACALOGO.jpg', height: 80, width: 80),

                const SizedBox(height: 30),

                // título
                const Text(
                  'Criar Conta',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),

                const SizedBox(height: 20),

                // campos de entrada
                CadastroForm(
                  nomeController: nomeController,
                  regiaoController: regiaoController,
                  idTanqueController: idTanqueController,
                  telefoneController: telefoneController,
                  enderecoController: enderecoController,
                  emailController: emailController,
                  senhaController: senhaController,
                  confirmarSenhaController: confirmarSenhaController,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: mostrarFormularioAdicional,
                      onChanged: (value) {
                        setState(() {
                          mostrarFormularioAdicional = value!;
                        });
                      },
                    ),
                    const Text(
                      'Outra pessoa divide o tanque comigo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                if (mostrarFormularioAdicional)
                  CadastroComplementarForm(
                    outroUsuarioNomeController: outroUsuarioNomeController,
                  ),

                const SizedBox(height: 25),

                // botão cadastrar
                MyButton(onTap: cadastrarUsuario, text: 'Cadastrar'),

                const SizedBox(height: 20),

                // voltar ao login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem uma conta?',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

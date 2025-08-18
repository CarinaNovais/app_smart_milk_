import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/cadastro_form.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:app_smart_milk/components/navbar.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  bool _isLoading = false;

  final nomeController = TextEditingController();
  final idtanqueController = TextEditingController();
  final idregiaoController = TextEditingController();
  final contatoController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  late MQTTService mqtt;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      },
      onCadastroNegado: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
    );
    mqtt.inicializar();
  }

  Future<void> executarCadastro() async {
    final nome = nomeController.text.trim();
    final idregiao = idregiaoController.text.trim();
    final idtanque = idtanqueController.text.trim();
    final contato = contatoController.text.trim();
    final senha = senhaController.text.trim();
    final confirmarSenha = confirmarSenhaController.text.trim();

    if (nome.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty ||
        idregiao.isEmpty ||
        idtanque.isEmpty ||
        contato.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos")),
      );
      return;
    }
    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("As senhas não coincidem")));
      return;
    }

    setState(() => _isLoading = true);

    final dados = {
      "nome": nome,
      "senha": senha,
      "cargo": null,
      "idtanque": int.tryParse(idtanque) ?? 0,
      "idregiao": int.tryParse(idregiao) ?? 0,
      "contato": contato,
      "foto": null,
    };

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage('cadastro/entrada', MqttQos.atMostOnce, buffer);

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    nomeController.dispose();
    idregiaoController.dispose();
    idtanqueController.dispose();
    contatoController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Cadastro',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/',
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset('lib/images/VACALOGO.jpg', height: 80, width: 80),
                const SizedBox(height: 30),
                const Text(
                  'Criar Conta',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 20),
                CadastroForm(
                  nomeController: nomeController,
                  idregiaoController: idregiaoController,
                  idtanqueController: idtanqueController,
                  contatoController: contatoController,
                  senhaController: senhaController,
                  confirmarSenhaController: confirmarSenhaController,
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : MyButton(onTap: executarCadastro, text: 'Cadastrar'),
                const SizedBox(height: 20),
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

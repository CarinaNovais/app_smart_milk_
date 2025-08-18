import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/cadastroVaca_form.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';

const Color appBlue = Color(0xFF0097B2);

class CadastroVacasPage extends StatefulWidget {
  const CadastroVacasPage({super.key});

  @override
  State<CadastroVacasPage> createState() => _CadastroVacasPageState();
}

//route é /cadastroVacas
class _CadastroVacasPageState extends State<CadastroVacasPage> {
  bool _isLoading = false;
  bool _navegou = false;

  final nomeController = TextEditingController();
  final brincoController = TextEditingController();
  final criasController = TextEditingController();
  final origemController = TextEditingController();
  final estadoController = TextEditingController();

  late MQTTService mqtt;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: (_) {},
      onCadastroNegado: (_) {},
      onCadastroVacaAceito: () {
        if (!mounted || _navegou) return;
        _navegou = true;
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(
          context,
          '/listagemVacas',
          arguments: {"refresh": true, "flash": "Vaca cadastrada com sucesso!"},
        );
      },
      onCadastroVacaNegado: (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Falha ao cadastrar vaca")),
        );
      },
      onVacaDeletada: () {},
    );
    mqtt.inicializar();
  }

  Future<void> executarCadastroVaca() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario_id = prefs.getInt('id');

    if (usuario_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro: usuário não identificado")),
      );
      return;
    }

    final nome = nomeController.text.trim();
    final brinco = brincoController.text.trim();
    final crias = criasController.text.trim();
    final origem = origemController.text.trim();
    final estado = estadoController.text.trim();

    if (nome.isEmpty ||
        brinco.isEmpty ||
        crias.isEmpty ||
        origem.isEmpty ||
        estado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dados = {
      "usuario_id": usuario_id,
      "nome": nome,
      "brinco": int.tryParse(brinco) ?? 0,
      "crias": int.tryParse(crias) ?? 0,
      "origem": origem,
      "estado": estado,
    };

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'cadastroVaca/entrada',
      MqttQos.atMostOnce,
      buffer,
    );
  }

  @override
  void dispose() {
    nomeController.dispose();
    brincoController.dispose();
    criasController.dispose();
    origemController.dispose();
    estadoController.dispose();
    // mqtt.client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Cadastrar Vaca',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoute: '/listagemVacas', // define a página que a seta leva
        showEndDrawerButton: true,
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset('lib/images/VACALOGO.png', height: 80, width: 80),
                const SizedBox(height: 30),
                const Text(
                  'Cadastrar Vaca',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 20),
                CadastroVacaForm(
                  nomeController: nomeController,
                  brincoController: brincoController,
                  criasController: criasController,
                  origemController: origemController,
                  estadoController: estadoController,
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : MyButton(
                      onTap: executarCadastroVaca,
                      text: 'Cadastrar Vaca',
                    ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

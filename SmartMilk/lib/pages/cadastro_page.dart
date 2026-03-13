import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';

import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/cadastro_form.dart';
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        Navigator.pushReplacementNamed(context, '/');
      },
      onCadastroNegado: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
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
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? const [
                Color(0xFF0F172A), // slate-900
                Color(0xFF1E293B), // slate-800
                Color(0xFF334155), // slate-700
              ]
              : const [
                Color(0xFFB2EBF2), // cyan-100
                Color(0xFF80DEEA), // cyan-200
                Color(0xFF64B5F6), // blue-300
              ],
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient), // gradiente por fora
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        resizeToAvoidBottomInset: false,

        appBar: Navbar(
          title: 'Cadastro',
          style: const TextStyle(color: Colors.white, fontSize: 20),
          backPageRoute: '/',
        ),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    Image.asset(
                      'lib/images/VACALOGO.png',
                      height: 80,
                      width: 80,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Criar conta',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Form
                    CadastroForm(
                      nomeController: nomeController,
                      idregiaoController: idregiaoController,
                      idtanqueController: idtanqueController,
                      contatoController: contatoController,
                      senhaController: senhaController,
                      confirmarSenhaController: confirmarSenhaController,
                    ),

                    const SizedBox(height: 16),

                    // Botão full-width igual aos inputs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: SizedBox(
                        width: double.infinity,
                        child: MyButton(
                          onTap:
                              _isLoading
                                  ? null
                                  : () {
                                    HapticFeedback.lightImpact();
                                    executarCadastro();
                                  },
                          text: _isLoading ? 'Carregando...' : 'Cadastrar',
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Já tem uma conta?',
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Entrar',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card translúcido
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.09 : 0.14,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

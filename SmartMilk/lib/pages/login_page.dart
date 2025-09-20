import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/pages/envio_service.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/my_textField.dart';
import 'package:app_smart_milk/components/quadrado_img.dart';

class LoginPage extends StatefulWidget {
  final int cargo; // 0 = Produtor, 2 = Coletor
  const LoginPage({super.key, required this.cargo});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String? _tokenRecebido;
  bool _isLoading = false;
  bool loginValidadoNoBanco = false;

  late MQTTService mqtt;

  String get _cargoLabel {
    switch (widget.cargo) {
      case 0:
        return 'Produtor';
      case 2:
        return 'Coletor';
      default:
        return 'Usuário';
    }
  }

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();

    mqtt.configurarCallbacks(
      onLoginAceito: () async {
        HapticFeedback.lightImpact();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (!mounted) return;

        if (token != null) {
          setState(() => _tokenRecebido = token);
          if (widget.cargo == 0) {
            Navigator.pushReplacementNamed(context, '/homeProdutor');
          } else {
            Navigator.pushReplacementNamed(context, '/homeColetor');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Token não encontrado. Tente novamente.'),
            ),
          );
        }
      },
      onLoginNegado: (msg) {
        if (!mounted) return;
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      onCadastroAceito: () {},
      onCadastroNegado: (msg) {},
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );

    mqtt.inicializar();
  }

  Future<void> executarLogin() async {
    final nome = usernameController.text.trim();
    final senha = passwordController.text.trim();
    final cargo = widget.cargo;

    if (nome.isEmpty || senha.isEmpty) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha nome e senha.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final resultado = await enviarLogin(nome: nome, senha: senha, cargo: cargo);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultado.mensagem)));
    setState(() => _isLoading = false);
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

    return Scaffold(
      // impede o body de subir com o teclado
      resizeToAvoidBottomInset: false,

      // RODAPÉ FIXO (fora do Stack!)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          alignment: Alignment.center,
          height: 32,
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.6,
            child: Text(
              '© ${DateTime.now().year} app_smart_milk',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),

      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // blobs decorativos
              Positioned(
                top: -60,
                left: -30,
                child: _Blob(size: 180, color: Colors.white.withOpacity(0.25)),
              ),
              Positioned(
                bottom: -50,
                right: -20,
                child: _Blob(size: 160, color: Colors.white.withOpacity(0.18)),
              ),

              // conteúdo
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Image.asset(
                          'lib/images/VACALOGO.png',
                          height: 110,
                          width: 110,
                        ),
                        const SizedBox(height: 10),

                        // Título
                        Text(
                          'Entrar como $_cargoLabel',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bem-vindo de volta!',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campos
                        MyTextField(
                          controller: usernameController,
                          hintText: 'Usuário',
                          obscureText: false,
                        ),
                        const SizedBox(height: 10),
                        MyTextField(
                          controller: passwordController,
                          hintText: 'Senha',
                          obscureText: true,
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
                                        executarLogin();
                                      },
                              text: _isLoading ? 'Carregando...' : 'Entrar',
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Social (mantive sua UI)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            QuadradoImg(imagePath: 'lib/images/google.png'),
                            SizedBox(width: 25),
                            QuadradoImg(imagePath: 'lib/images/apple.png'),
                          ],
                        ),

                        if (_tokenRecebido != null) ...[
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: 0.8,
                            child: Text(
                              'Token:\n${_tokenRecebido!}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card translúcido (glassmorphism)
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

/// Blob decorativo
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

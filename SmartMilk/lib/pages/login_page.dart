import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/pages/envio_service.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/my_textField.dart';
import 'package:app_smart_milk/components/quadrado_img.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final int cargo;
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

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();

    mqtt.configurarCallbacks(
      onLoginAceito: () async {
        print('Callback onLoginAceito chamado');

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token != null) {
          print('Token encontrado no callback: $token');
          if (mounted) {
            setState(() {
              _tokenRecebido = token;
            });
            //Faz o redirecionamento após login aceito
            if (widget.cargo == 0) {
              Navigator.pushReplacementNamed(context, '/homeProdutor');
            } else {
              Navigator.pushReplacementNamed(context, '/homeColetor');
            }
          }
        } else {
          print('⚠️ Token não encontrado no SharedPreferences');
        }
      },
      onLoginNegado: (msg) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
      onCadastroAceito: () {},
      onCadastroNegado: (msg) {},
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
    );
    mqtt.inicializar();
  }

  Future<void> executarLogin() async {
    final nome = usernameController.text.trim();
    final senha = passwordController.text.trim();
    final cargo = widget.cargo;

    if (nome.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha nome e senha.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await enviarLogin(nome: nome, senha: senha, cargo: cargo);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultado.mensagem)));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // para evitar overflow com teclado aberto
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset('lib/images/VACALOGO.png', height: 200, width: 200),
                const SizedBox(height: 50),
                const Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 25),
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
                const SizedBox(height: 10),
                MyButton(
                  onTap: _isLoading ? null : executarLogin,
                  text: _isLoading ? 'Carregando...' : 'Entrar',
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    QuadradoImg(imagePath: 'lib/images/google.png'),
                    SizedBox(width: 25),
                    QuadradoImg(imagePath: 'lib/images/apple.png'),
                  ],
                ),
                const SizedBox(height: 50),
                if (_tokenRecebido != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Token recebido:\n${_tokenRecebido!}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/components/my_textField.dart';
import 'package:app_smart_milk/components/quadrado_img.dart';
import 'package:app_smart_milk/pages/cadastro_page.dart';

class LoginPage extends StatefulWidget {
  final int idCargo;
  const LoginPage({super.key, required this.idCargo});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> enviarLogin() async {
    final nome = usernameController.text.trim();
    final senha = passwordController.text.trim();

    if (nome.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha nome e senha.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uri = Uri.parse(
      'http://192.168.66.15:5000/login',
    ); // ajuste seu IP/porta
    final body = jsonEncode({
      "nome": nome,
      "senha": senha,
      "idCargo": widget.idCargo,
    });

    try {
      final resposta = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final jsonResponse = jsonDecode(resposta.body);

      if (resposta.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonResponse["status"] ?? "Login publicado com sucesso!",
            ),
          ),
        );
        // Aqui você pode navegar para outra página, se quiser.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse["erro"] ?? "Erro no login.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao conectar ao servidor.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                Image.asset('lib/images/VACALOGO.jpg', height: 70, width: 70),
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
                  onTap: _isLoading ? null : enviarLogin,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Primeira vez?',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CadastroPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Cadastre-se agora',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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

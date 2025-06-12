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

  Future<void> loginUser() async {
    var url = Uri.parse('http://192.168.66.16:5000/login');

    try {
      var response = await http.post(
        url,
        body: jsonEncode({
          'usuario': usernameController.text,
          'senha': passwordController.text,
          'idCargo': widget.idCargo,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        var respostaJson = jsonDecode(response.body);
        print('✅ Servidor respondeu: ${respostaJson['mensagem']}');
      } else {
        print('❌ Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Erro ao chamar servidor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset('lib/images/VACALOGO.jpg', height: 70, width: 70),
              const SizedBox(height: 50),
              Text(
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
              MyButton(onTap: loginUser, text: 'Entrar'),
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
                  Text('Primeira vez?', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CadastroPage()),
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
            ],
          ),
        ),
      ),
    );
  }
}

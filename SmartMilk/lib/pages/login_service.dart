import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginResultado {
  final bool sucesso;
  final String mensagem;

  LoginResultado({required this.sucesso, required this.mensagem});
}

Future<LoginResultado> enviarLogin({
  required String nome,
  required String senha,
  required int cargo,
}) async {
  final uri = Uri.parse('http://192.168.66.15:5000/login');
  final body = jsonEncode({"nome": nome, "senha": senha, "cargo": cargo});

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return LoginResultado(
        sucesso: true,
        mensagem: dados["status"] ?? "Login publicado com sucesso!",
      );
    } else {
      return LoginResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao fazer login.",
      );
    }
  } catch (e) {
    return LoginResultado(
      sucesso: false,
      mensagem: "Erro ao conectar ao servidor.",
    );
  }
}

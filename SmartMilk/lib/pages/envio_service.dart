import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginResultado {
  final bool sucesso;
  final String mensagem;

  LoginResultado({required this.sucesso, required this.mensagem});
}

class CadastroResultado {
  final bool sucesso;
  final String mensagem;

  CadastroResultado({required this.sucesso, required this.mensagem});
}

Future<LoginResultado> enviarLogin({
  required String nome,
  required String senha,
  required int cargo,
}) async {
  final uri = Uri.parse('http://192.168.66.11:5000/login'); //ip meu notebook
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

class FotoPerfilResultado {
  final bool sucesso;
  final String mensagem;

  FotoPerfilResultado({required this.sucesso, required this.mensagem});
}

Future<FotoPerfilResultado> enviarFotoPerfil({
  required String nome,
  required int idtanque,
  required String fotoBase64,
}) async {
  final uri = Uri.parse('http://192.168.66.11:5000/perfil/editar_foto');
  final body = jsonEncode({
    "nome": nome,
    "idtanque": idtanque,
    "foto": fotoBase64,
  });

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return FotoPerfilResultado(
        sucesso: true,
        mensagem: dados["status"] ?? "Foto publicada com sucesso!",
      );
    } else {
      return FotoPerfilResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao atualizar foto.",
      );
    }
  } catch (e) {
    return FotoPerfilResultado(
      sucesso: false,
      mensagem: "Erro ao conectar ao servidor.",
    );
  }
}

Future<CadastroResultado> enviarCadastro({
  required String nome,
  required String senha,
  int? cargo,
  required int idtanque,
  required int idregiao,
  required String contato,
  String? foto,
}) async {
  final uri = Uri.parse('http://192.168.66.11:5000/cadastro'); //ip meu notebook
  final body = jsonEncode({
    "nome": nome,
    "senha": senha,
    "cargo": cargo,
    "idtanque": idtanque,
    "idregiao": idregiao,
    "contato": contato,
    "foto": foto,
  });

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return CadastroResultado(
        sucesso: true,
        mensagem: dados["status"] ?? "Cadastro publicado com sucesso!",
      );
    } else {
      return CadastroResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao publicar cadastro.",
      );
    }
  } catch (e) {
    return CadastroResultado(
      sucesso: false,
      mensagem: "Erro ao conectar ao servidor.",
    );
  }
}

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

class EnviarFotoResultado {
  final bool sucesso;
  final String mensagem;

  EnviarFotoResultado({required this.sucesso, required this.mensagem});
}

class AtualizacaoResultado {
  final bool sucesso;
  final String mensagem;

  AtualizacaoResultado({required this.sucesso, required this.mensagem});
}

Future<AtualizacaoResultado> enviarAtualizacao({
  required String nome,
  required String idtanque,
  required String campo,
  required String valor,
}) async {
  final uri = Uri.parse('http://192.168.66.16:5000/atualizar');
  final body = jsonEncode({
    "nome": nome,
    "idtanque": idtanque,
    "campo": campo,
    "valor": valor,
  });

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return AtualizacaoResultado(
        sucesso: true,
        mensagem: dados["mensagem"] ?? "Campo atualizado com sucesso!",
      );
    } else {
      return AtualizacaoResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao atualizar campo.",
      );
    }
  } catch (e) {
    return AtualizacaoResultado(
      sucesso: false,
      mensagem: "Erro ao conectar ao servidor.",
    );
  }
}

Future<LoginResultado> enviarLogin({
  required String nome,
  required String senha,
  required int cargo,
}) async {
  final uri = Uri.parse('http://192.168.66.16:5000/login'); //ip meu notebook
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

Future<EnviarFotoResultado> enviarFoto({
  required String nome,
  required String fotoBase64,
}) async {
  final uri = Uri.parse(
    'http://192.168.66.16:5000/fotoAtualizada',
  ); //ip mei notebook
  final body = jsonEncode({"nome": nome, "foto": fotoBase64});

  print('📤 Enviando foto para $uri');
  print('👤 Nome: $nome');
  print('🖼️ Foto base64 (início): ${fotoBase64.substring(0, 100)}');
  print('📦 Tamanho total da base64: ${fotoBase64.length} caracteres');

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('✅ Resposta recebida com status: ${resposta.statusCode}');
    print('💬 Corpo da resposta: ${resposta.body}');

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return EnviarFotoResultado(
        sucesso: true,
        mensagem: dados["status"] ?? "Foto atualizada com sucesso!",
      );
    } else {
      return EnviarFotoResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao atualizar foto",
      );
    }
  } catch (e) {
    print('❌ Exceção durante envio da foto: $e');
    return EnviarFotoResultado(
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
  final uri = Uri.parse('http://192.168.66.16:5000/cadastro'); //ip meu notebook
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

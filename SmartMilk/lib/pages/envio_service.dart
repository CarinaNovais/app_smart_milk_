import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String servidorIP = '192.168.66.15'; // ipmeunotebook
const String servidorPorta = '5000';

String get baseURL => 'http://$servidorIP:$servidorPorta';

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

class CadastroVacaResultado {
  final bool sucesso;
  final String mensagem;

  CadastroVacaResultado({required this.sucesso, required this.mensagem});
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

class AtualizacaoVacaResultado {
  final bool sucesso;
  final String mensagem;

  AtualizacaoVacaResultado({required this.sucesso, required this.mensagem});
}

class CadastroHistoricoColetaResultado {
  final bool sucesso;
  final String mensagem;

  CadastroHistoricoColetaResultado({
    required this.sucesso,
    required this.mensagem,
  });
}

Future<AtualizacaoVacaResultado> enviarVacaAtualizacao({
  required String campo,
  required String valor,
  required int vaca_id,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final usuario_id = prefs.getInt('id');

  final uri = Uri.parse('${baseURL}/editarVaca');
  final body = jsonEncode({
    "usuario_id": usuario_id,
    "vaca_id": vaca_id,
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
      return AtualizacaoVacaResultado(
        sucesso: true,
        mensagem: dados["mensagem"] ?? "Campo atualizado com sucesso!",
      );
    } else {
      return AtualizacaoVacaResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao atualizar campo.",
      );
    }
  } catch (e) {
    return AtualizacaoVacaResultado(
      sucesso: false,
      mensagem: "Erro ao conectar ao servidor.",
    );
  }
}

Future<AtualizacaoResultado> enviarAtualizacao({
  required String nome,
  required String campo,
  required String valor,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt('id');

  final cargo = prefs.getInt('cargo');

  if (id == null || cargo == null) {
    return AtualizacaoResultado(
      sucesso: false,
      mensagem: "ID ou cargo ausente no dispositivo.",
    );
  }

  final uri = Uri.parse('${baseURL}/editarUsuario');
  final body = jsonEncode({
    "nome": nome,
    "id": id,
    "campo": campo,
    "valor": valor,
    "cargo": cargo,
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
  final uri = Uri.parse('${baseURL}/login');
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
  required String idusuario,
  required String fotoBase64,
}) async {
  final uri = Uri.parse('${baseURL}/fotoAtualizada');

  final body = jsonEncode({
    "nome": nome,
    "id": int.parse(idusuario),
    "foto": fotoBase64,
  });

  print('📤 Enviando foto para $uri');
  print('👤 Nome: $nome');
  String preview =
      fotoBase64.length > 100 ? fotoBase64.substring(0, 100) : fotoBase64;
  print('🖼️ Foto base64 (início): $preview');

  //print('🖼️ Foto base64 (início): ${fotoBase64.substring(0, 100)}');
  //print('📦 Tamanho total da base64: ${fotoBase64.length} caracteres');

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

Future<CadastroHistoricoColetaResultado> enviarHistoricoColeta({
  required String nome,
  required int idtanque,
  required int idregiao,
  required double ph,
  required double temperatura,
  required double nivel,
  required double amonia,
  required double carbono,
  required double metano,
  required String coletor,
  required String placa,
}) async {
  final uri = Uri.parse('${baseURL}/cadastroHistoricoColeta');
  final body = jsonEncode({
    "nome": nome,
    "idtanque": idtanque,
    "idregiao": idregiao,
    "ph": ph,
    "temperatura": temperatura,
    "nivel": nivel,
    "amonia": amonia,
    "carbono": carbono,
    "metano": metano,
    "coletor": coletor,
    "placa": placa,
  });

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final dados = jsonDecode(resposta.body);
    if (resposta.statusCode == 200) {
      return CadastroHistoricoColetaResultado(
        sucesso: true,
        mensagem: dados["status"] ?? "Histórico de coleta enviado com sucesso!",
      );
    } else {
      return CadastroHistoricoColetaResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao enviar histórico de coleta.",
      );
    }
  } catch (e) {
    return CadastroHistoricoColetaResultado(
      sucesso: false,
      mensagem: "Erro ao conectar ao servidor.",
    );
  }
}

////////////////////////////////////////////fazer future cadastrovacasresultado
Future<CadastroVacaResultado> enviarCadastroVaca({
  required int usuario_id,
  required String nome,
  required int brinco,
  required int crias,
  required String origem,
  required String estado,
}) async {
  final uri = Uri.parse('${baseURL}/cadastroVaca');
  final body = jsonEncode({
    "usuario_id": usuario_id,
    "nome": nome,
    "brinco": brinco,
    "crias": crias,
    "origem": origem,
    "estado": estado,
  });

  try {
    final resposta = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    final dados = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      return CadastroVacaResultado(
        sucesso: true,
        mensagem: dados["status"] ?? "Cadastro da vaca publicado com sucesso!",
      );
    } else {
      return CadastroVacaResultado(
        sucesso: false,
        mensagem: dados["erro"] ?? "Erro ao publicar cadastro da vaca.",
      );
    }
  } catch (e) {
    return CadastroVacaResultado(
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
  final uri = Uri.parse('${baseURL}/cadastro');
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

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

Future<String> salvarImagemLocal(String base64Image, String nomeArquivo) async {
  final bytes = base64Decode(base64Image);

  final diretorio = await getApplicationDocumentsDirectory();
  final caminho = '${diretorio.path}/$nomeArquivo';

  final arquivo = File(caminho);
  await arquivo.writeAsBytes(bytes);

  return caminho;
}

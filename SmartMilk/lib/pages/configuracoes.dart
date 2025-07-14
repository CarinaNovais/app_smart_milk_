import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_data/typed_buffers.dart';

import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPage();
}

class _ConfiguracoesPage extends State<ConfiguracoesPage> {
  bool editandoNome = false;
  bool editandoSenha = false;
  bool editandoIdTanque = false;
  bool editandoIdRegiao = false;
  bool editandoContato = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController idTanqueController = TextEditingController();
  final TextEditingController idRegiaoController = TextEditingController();
  final TextEditingController contatoController = TextEditingController();

  bool senhaVisivel = false;
  File? imagemPerfil;
  Uint8List? imagemMemoria;
  String? binarioImagem;

  @override
  void initState() {
    super.initState();

    mqtt = MQTTService(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onFotoEditada: () async {
        final prefs = await SharedPreferences.getInstance();
        final fotoBase64 = prefs.getString('foto');
        if (fotoBase64 != null) {
          setState(() {
            imagemMemoria = base64Decode(fotoBase64);
            imagemPerfil = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Foto atualizada com sucesso!')),
        );
      },
      onErroFoto: (erro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao atualizar foto: $erro')),
        );
      },
    );
    mqtt.inicializar();
    carregarDadosUsuario();
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nomeController.text = prefs.getString('nome') ?? '';
      senhaController.text = prefs.getString('senha') ?? '';
      idTanqueController.text = prefs.getString('idtanque') ?? '';
      idRegiaoController.text = prefs.getString('idregiao') ?? '';
      contatoController.text = prefs.getString('contato') ?? '';
    });
  }

  Future<void> selecionarEenviarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        binarioImagem = base64Image;
      });

      final prefs = await SharedPreferences.getInstance();
      final nome = prefs.getString('nome');
      final idtanque = prefs.getString('idtanque');

      if (nome == null || idtanque == null || binarioImagem == null) return;

      final dados = {"foto": binarioImagem, "nome": nome, "idtanque": idtanque};
      final mensagem = jsonEncode(dados);
      final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

      mqtt.client.publishMessage(
        'fotoAtualizada/entrada',
        MqttQos.atMostOnce,
        buffer,
      );
    }
  }

  void atualizarCampo(String campo, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    final idtanque = prefs.getString('idtanque');

    if (nome == null || idtanque == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Dados do usuário ausentes")),
      );
      return;
    }

    final dados = {
      "nome": nome,
      "idtanque": idtanque,
      "campo": campo,
      "valor": valor,
    };
    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'editarUsuario/entrada',
      MqttQos.atMostOnce,
      buffer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlue,
      appBar: const Navbar(
        title: 'Configurações',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      endDrawer: const MenuDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: selecionarEenviarImagem,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage:
                    imagemPerfil != null
                        ? FileImage(imagemPerfil!)
                        : (imagemMemoria != null
                            ? MemoryImage(imagemMemoria!)
                            : null),
                child:
                    (imagemPerfil == null && imagemMemoria == null)
                        ? const Icon(Icons.person, size: 50, color: appBlue)
                        : null,
              ),
            ),
            const SizedBox(height: 16),

            // Nome
            buildEditableField(
              controller: nomeController,
              label: 'Nome',
              editando: editandoNome,
              onPressed: () {
                setState(() {
                  if (editandoNome) {
                    atualizarCampo("nome", nomeController.text);
                  }
                  editandoNome = !editandoNome;
                });
              },
            ),

            // ID Tanque
            buildEditableField(
              controller: idTanqueController,
              label: 'ID do Tanque',
              editando: editandoIdTanque,
              onPressed: () {
                setState(() {
                  if (editandoIdTanque) {
                    atualizarCampo("idtanque", idTanqueController.text);
                  }
                  editandoIdTanque = !editandoIdTanque;
                });
              },
            ),

            // ID Região
            buildEditableField(
              controller: idRegiaoController,
              label: 'ID da Região',
              editando: editandoIdRegiao,
              onPressed: () {
                setState(() {
                  if (editandoIdRegiao) {
                    atualizarCampo("idregiao", idRegiaoController.text);
                  }
                  editandoIdRegiao = !editandoIdRegiao;
                });
              },
            ),

            // Contato
            buildEditableField(
              controller: contatoController,
              label: 'Contato',
              keyboardType: TextInputType.phone,
              editando: editandoContato,
              onPressed: () {
                setState(() {
                  if (editandoContato) {
                    atualizarCampo("contato", contatoController.text);
                  }
                  editandoContato = !editandoContato;
                });
              },
            ),

            // Senha
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: senhaController,
                    enabled: editandoSenha,
                    obscureText: !senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: Icon(
                          senhaVisivel
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            senhaVisivel = !senhaVisivel;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (editandoSenha) {
                        atualizarCampo("senha", senhaController.text);
                      }
                      editandoSenha = !editandoSenha;
                    });
                  },
                  child: Text(editandoSenha ? 'Salvar' : 'Editar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool editando,
    required VoidCallback onPressed,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: editando,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(editando ? 'Salvar' : 'Editar'),
          ),
        ],
      ),
    );
  }
}

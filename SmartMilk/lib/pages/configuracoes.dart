import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:flutter/foundation.dart';
import 'package:app_smart_milk/components/notifiers.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

import 'package:path_provider/path_provider.dart';

const Color appBlue = Color(0xFF0097B2);

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
  bool editandoPlaca = false;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController idTanqueController = TextEditingController();
  final TextEditingController idRegiaoController = TextEditingController();
  final TextEditingController contatoController = TextEditingController();
  final TextEditingController placaController = TextEditingController();

  bool senhaVisivel = false;
  File? imagemPerfil;
  Uint8List? imagemMemoria;
  String? binarioImagem;

  int? cargo;
  String nomeUsuario = '';
  late MQTTService mqtt;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();
    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onFotoEditada: () async {
        final prefs = await SharedPreferences.getInstance();

        final fotoBase64 = prefs.getString('foto');
        final userId = prefs.getInt('id');

        if (fotoBase64 != null && fotoBase64.isNotEmpty && userId != null) {
          // Salva a imagem local usando nome único por usuário
          final nomeArquivo = 'foto_usuario_$userId.png';
          final caminho = await salvarImagemLocal(fotoBase64, nomeArquivo);

          // Salva o caminho no prefs com chave específica do usuário
          await prefs.setString('caminho_foto_$userId', caminho);

          setState(() {
            imagemPerfil = File(caminho);
            imagemMemoria = null;
          });

          //Atualiza o notifier
          fotoUsuarioNotifier.value = caminho;
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
      onCampoAtualizado: (campo, valor) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(campo, valor);

        switch (campo) {
          case 'nome':
            nomeUsuarioNotifier.value = valor;
            break;
          case 'contato':
            contatoUsuarioNotifier.value = valor;
            break;
          case 'idtanque':
            idtanqueUsuarioNotifier.value = valor;
            break;
          case 'idregiao':
            idRegiaoUsuarioNotifier.value = valor;
            break;
          case 'placa':
            placaUsuarioNotifier.value = valor;
            break;
          case 'senha':
            senhaUsuarioNotifier.value = valor;
            break;
        }
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
    );

    mqtt.inicializar();
    carregarDadosUsuario();
  }

  // Função para salvar base64 como arquivo local e retornar o caminho
  Future<String> salvarImagemLocal(
    String base64Image,
    String nomeArquivo,
  ) async {
    final bytes = base64Decode(base64Image);
    final diretorio = await getApplicationDocumentsDirectory();
    final caminho = '${diretorio.path}/$nomeArquivo';

    final arquivo = File(caminho);
    await arquivo.writeAsBytes(bytes);

    return caminho;
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id');

    setState(() {
      nomeController.text = prefs.getString('nome') ?? '';
      senhaController.text = prefs.getString('senha') ?? '';
      idTanqueController.text = prefs.getString('idtanque') ?? '';
      idRegiaoController.text = prefs.getString('idregiao') ?? '';
      contatoController.text = prefs.getString('contato') ?? '';
      placaController.text = prefs.getString('placa') ?? '';
      cargo = prefs.getInt('cargo');
      //
      if (userId != null) {
        final caminhoFoto = prefs.getString('caminho_foto_$userId');
        if (caminhoFoto != null && caminhoFoto.isNotEmpty) {
          imagemPerfil = File(caminhoFoto);
          imagemMemoria = null;
          fotoCaminhoNotifier.value = caminhoFoto;
        }
      }
    });
    // Atualiza os notifiers
    nomeUsuarioNotifier.value = nomeController.text;
    contatoUsuarioNotifier.value = contatoController.text;
  }

  Future<void> selecionarEenviarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      final nome = prefs.getString('nome');
      final id = prefs.getInt('id');

      if (nome == null || id == null || binarioImagem == null) return;

      final nomeArquivo = 'foto_usuario_$id.png';
      // Salva localmente a foto selecionada
      final caminho = await salvarImagemLocal(binarioImagem!, nomeArquivo);

      setState(() {
        imagemPerfil = File(caminho);
        imagemMemoria = null;
        binarioImagem = base64Image;
      });

      final dados = {"foto": binarioImagem, "nome": nome, "id": id};
      final mensagem = jsonEncode(dados);
      final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

      mqtt.client.publishMessage(
        'fotoAtualizada/entrada',
        MqttQos.atMostOnce,
        buffer,
      );
      await prefs.setString('caminho_foto_$id', caminho);
      fotoUsuarioNotifier.value = caminho;
    }
  }

  void atualizarCampo(String campo, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    final id = prefs.getInt('id');
    final cargo = prefs.getInt('cargo');

    if (nome == null || cargo == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Dados do usuário ausentes")),
      );
      return;
    }

    Map<String, dynamic> dados;

    if (cargo == 0) {
      dados = {
        "nome": nome,
        "id": id,
        "campo": campo,
        "valor": valor,
        "cargo": cargo,
      };
    } else if (cargo == 2) {
      dados = {"nome": nome, "campo": campo, "valor": valor, "cargo": cargo};
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Cargo não suportado")));
      return;
    }

    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));

    mqtt.client.publishMessage(
      'editarUsuario/entrada',
      MqttQos.atMostOnce,
      buffer,
    );
  }

  Future<void> salvarCampo({
    required String campo,
    required String valor,
    required VoidCallback? onNotifierUpdate,
  }) async {
    atualizarCampo(campo, valor);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(campo, valor);

    if (onNotifierUpdate != null) {
      onNotifierUpdate();
    }
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
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: fotoUsuarioNotifier,
              builder: (context, caminhoFoto, _) {
                File? imagemArquivo;
                if (caminhoFoto != null && caminhoFoto.isNotEmpty) {
                  imagemArquivo = File(caminhoFoto);
                }

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          imagemPerfil != null
                              ? FileImage(imagemPerfil!)
                              : (imagemArquivo != null
                                  ? FileImage(imagemArquivo)
                                  : null),
                      child:
                          (imagemPerfil == null && imagemArquivo == null)
                              ? const Icon(
                                Icons.person,
                                size: 50,
                                color: appBlue,
                              )
                              : null,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: selecionarEenviarImagem,
                      child: const Text('alterar foto'),
                    ),
                  ],
                );
              },
            ),

            // Nome
            buildEditableField(
              controller: nomeController,
              label: 'Nome',
              editando: editandoNome,
              onPressed: () {
                setState(() {
                  if (editandoNome) {
                    salvarCampo(
                      campo: "nome",
                      valor: nomeController.text,
                      onNotifierUpdate:
                          () => nomeUsuarioNotifier.value = nomeController.text,
                    );
                  }
                  editandoNome = !editandoNome;
                });
              },
            ),

            //campos condicionais
            //tanque
            if (cargo == 0) ...[
              buildEditableField(
                controller: idTanqueController,
                label: 'ID do Tanque',
                editando: editandoIdTanque,
                onPressed: () {
                  setState(() {
                    if (editandoIdTanque) {
                      salvarCampo(
                        campo: "idtanque",
                        valor: idTanqueController.text,
                        onNotifierUpdate:
                            () =>
                                idtanqueUsuarioNotifier.value =
                                    idTanqueController.text,
                      );
                    }
                    editandoIdTanque = !editandoIdTanque;
                  });
                },
              ),
              //regiao
              buildEditableField(
                controller: idRegiaoController,
                label: 'ID da Região',
                editando: editandoIdRegiao,
                onPressed: () {
                  setState(() {
                    if (editandoIdRegiao) {
                      salvarCampo(
                        campo: "idregiao",
                        valor: idRegiaoController.text,
                        onNotifierUpdate:
                            () =>
                                idRegiaoUsuarioNotifier.value =
                                    idRegiaoController.text,
                      );
                    }
                    editandoIdRegiao = !editandoIdRegiao;
                  });
                },
              ),
              //placa
            ] else if (cargo == 2) ...[
              buildEditableField(
                controller: placaController,
                label: 'Placa do Veículo',
                editando: editandoPlaca,
                onPressed: () {
                  setState(() {
                    if (editandoPlaca) {
                      salvarCampo(
                        campo: "placa",
                        valor: placaController.text,
                        onNotifierUpdate:
                            () =>
                                placaUsuarioNotifier.value =
                                    placaController.text,
                      );
                    }
                    editandoPlaca = !editandoPlaca;
                  });
                },
              ),
            ],

            // Contato
            buildEditableField(
              controller: contatoController,
              label: 'Contato',
              keyboardType: TextInputType.phone,
              editando: editandoContato,
              onPressed: () {
                setState(() {
                  if (editandoContato) {
                    salvarCampo(
                      campo: "contato",
                      valor: contatoController.text,
                      onNotifierUpdate:
                          () =>
                              contatoUsuarioNotifier.value =
                                  contatoController.text,
                    );
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
                        salvarCampo(
                          campo: "senha",
                          valor: senhaController.text,
                          onNotifierUpdate:
                              () =>
                                  senhaUsuarioNotifier.value =
                                      senhaController.text,
                        );
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

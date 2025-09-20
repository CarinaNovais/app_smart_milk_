import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
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
        final userId = prefs.getInt('id');
        // priorize o que acabou de ser enviado
        final fotoBase64 = binarioImagem ?? prefs.getString('foto');

        if (fotoBase64 != null && fotoBase64.isNotEmpty && userId != null) {
          final nomeArquivo = 'foto_usuario_$userId.png';
          final caminho = await salvarImagemLocal(fotoBase64, nomeArquivo);
          await prefs.setString('caminho_foto_$userId', caminho);
          setState(() {
            imagemPerfil = File(caminho);
            imagemMemoria = null;
          });
          // padronize notifier (ver ponto 3) — recomendo caminho
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
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
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
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes); // fonte da verdade aqui

    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    final id = prefs.getInt('id');
    if (nome == null || id == null) return;

    // 1) atualize binarioImagem ANTES de usar
    binarioImagem = base64Image;

    // 2) opcional: persista a foto em base64 para outras telas que ainda usam base64
    await prefs.setString('foto', base64Image);

    // 3) salve também como arquivo local (mais leve para UI)
    final nomeArquivo = 'foto_usuario_$id.png';
    final caminho = await salvarImagemLocal(base64Image, nomeArquivo);

    setState(() {
      imagemPerfil = File(caminho);
      imagemMemoria = null;
    });

    // 4) publique no MQTT com o MESMO base64 que você acabou de gerar
    final dados = {"foto": base64Image, "nome": nome, "id": id};
    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));
    mqtt.client.publishMessage(
      'fotoAtualizada/entrada',
      MqttQos.atMostOnce,
      buffer,
    );

    // 5) guarde o caminho local para reusar
    await prefs.setString('caminho_foto_$id', caminho);
    // ver ponto 3 para padronização do notifier
    fotoUsuarioNotifier.value = caminho; // se padronizar por caminho
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
      dados = {
        "nome": nome,
        "id": id,
        "campo": campo,
        "valor": valor,
        "cargo": cargo,
      };
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
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)]
              : const [Color(0xFFB2EBF2), Color(0xFF80DEEA), Color(0xFF64B5F6)],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ), // gradiente FORA do Scaffold
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,

        appBar: Navbar(
          title: 'Configurações',
          style: const TextStyle(fontSize: 20), // cor é aplicada na Navbar
          backPageRoutePorCargo: {0: '/homeProdutor', 2: '/homeColetor'},
          backPageRoute: '/homeDefault',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GlassSection(
                child: Center(
                  child: GestureDetector(
                    onTap: selecionarEenviarImagem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          (MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark)
                              ? 0.10
                              : 0.16,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Mudar foto de perfil',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card: dados (nome, contato e condicionais)
              _GlassSection(
                child: Column(
                  children: [
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
                                  () =>
                                      nomeUsuarioNotifier.value =
                                          nomeController.text,
                            );
                          }
                          editandoNome = !editandoNome;
                        });
                      },
                    ),

                    // Campos condicionais
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card: senha
              _GlassSection(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: senhaController,
                        enabled: editandoSenha,
                        obscureText: !senhaVisivel,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          labelStyle: const TextStyle(color: Color(0xFFF5F5F5)),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF5F5F5)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFF5F5F5)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              senhaVisivel
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed:
                                () => setState(
                                  () => senhaVisivel = !senhaVisivel,
                                ),
                          ),
                        ),
                        keyboardType: TextInputType.visiblePassword,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _EditSaveButton(
                      isEditing: editandoSenha,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassSection(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: editando,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF5F5F5)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF5F5F5)),
                  ),
                  hintText: '',
                  hintStyle: TextStyle(color: Color(0xFFF5F5F5)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _EditSaveButton(isEditing: editando, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final Widget child;
  const _GlassSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.08 : 0.14,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EditSaveButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onPressed;
  const _EditSaveButton({required this.isEditing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: appBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(isEditing ? 'Salvar' : 'Editar'),
    );
  }
}

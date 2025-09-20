import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:app_smart_milk/components/notifiers.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:ui';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  _PerfilPage createState() => _PerfilPage();
}

class _PerfilPage extends State<PerfilPage> {
  String nomeUsuario = '';
  String idtanque = '';
  String idregiao = '';
  String senha = '';
  int? cargo;
  String placa = '';
  bool senhaVisivel = false;
  File? imagemPerfil;
  Uint8List? imagemMemoria;
  String? binarioImagem;
  late final MQTTService mqtt;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();

    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (erro) {},
      onCadastroAceito: () {},
      onCadastroNegado: (erro) {},

      onFotoEditada: () async {
        final prefs = await SharedPreferences.getInstance();
        nomeUsuarioNotifier.value = nomeUsuario;

        final fotoBase64 = prefs.getString('foto');

        if (fotoBase64 != null) {
          setState(() {
            imagemMemoria = base64Decode(fotoBase64);
            imagemPerfil = null;
          });
        }

        if (fotoBase64 != null && fotoBase64.isNotEmpty) {
          fotoUsuarioNotifier.value = fotoBase64;
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
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );
    mqtt.inicializar();

    carregarDadosUsuario();
  }

  Future<String> compactarImagem(File imagemOriginal) async {
    final bytes = await FlutterImageCompress.compressWithFile(
      imagemOriginal.absolute.path,
      quality: 60, // Reduz a qualidade para ~60%
      minWidth: 600, // Reduz resolução
      minHeight: 600,
      format: CompressFormat.jpeg,
    );

    if (bytes == null) throw Exception("Falha na compactação da imagem");

    return base64Encode(bytes);
  }

  Future<void> selecionarEenviarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      print('⚠️ Nenhuma imagem selecionada.');
      return;
    }

    final file = File(pickedFile.path);
    final bytes = await file.readAsBytes();

    const maxSizeInBytes = 20 * 1024 * 1024; // 20MB

    if (bytes.length > maxSizeInBytes) {
      print("Arquivo muito grande, escolha outra imagem menor.");
      // Mostra diálogo de alerta para o usuário
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Imagem muito grande'),
                content: const Text(
                  'A imagem selecionada é muito grande. Por favor, escolha uma imagem com até 20 MB.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
      return;
    }

    // Compactar a imagem e enviar
    final base64Image = await compactarImagem(file);

    //salva no sharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto', base64Image);

    setState(() {
      binarioImagem = base64Image;
    });

    if (binarioImagem != null) {
      String preview =
          binarioImagem!.length > 100
              ? binarioImagem!.substring(0, 100)
              : binarioImagem!;
      print("🧪 Foto base64 (início): $preview");
    }
    print('🖼️ Imagem convertida para base64!');

    final nome = prefs.getString('nome');
    final id = prefs.getInt('id');
    final caminhoLocal =
        id != null ? prefs.getString('caminho_foto_$id') : null;

    if (caminhoLocal != null &&
        caminhoLocal.isNotEmpty &&
        File(caminhoLocal).existsSync()) {
      imagemPerfil = File(caminhoLocal);
      imagemMemoria = null;
    } else {
      final fotoBase64 = prefs.getString('foto');
      imagemMemoria =
          (fotoBase64 != null && fotoBase64.isNotEmpty)
              ? base64Decode(fotoBase64)
              : null;
      imagemPerfil = null;
    }

    if (nome == null || id == null || binarioImagem == null) {
      print("⚠️ Dados ausentes para envio da imagem.");
      return;
    }

    final dados = {"foto": binarioImagem, "nome": nome, "id": id};
    final mensagem = jsonEncode(dados);
    final buffer = Uint8Buffer()..addAll(utf8.encode(mensagem));
    print("📤 Enviando mensagem MQTT com dados: $mensagem");

    mqtt.client.publishMessage(
      'fotoAtualizada/entrada',
      MqttQos.atMostOnce,
      buffer,
    );
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nomeUsuario = prefs.getString('nome') ?? 'Usuário';
      senha = prefs.getString('senha') ?? '--';
      cargo = prefs.getInt('cargo');
      idregiao = (cargo == 0) ? (prefs.getString('idregiao') ?? '--') : '--';
      idtanque = (cargo == 0) ? (prefs.getString('idtanque') ?? '--') : '--';
      placa =
          (cargo == 2)
              ? (prefs.getString('placa') ?? 'Sem Placa')
              : 'Sem Placa';

      final fotoBase64 = prefs.getString('foto');

      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
        imagemMemoria = base64Decode(fotoBase64);
      } else {
        imagemMemoria = null;
      }
    });
  }

  Widget _infoTile(String titulo, String valor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _tileSenha() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'Senha',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      subtitle: Text(
        senhaVisivel ? senha : '••••••••',
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      trailing: IconButton(
        icon: Icon(
          senhaVisivel ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
        ),
        onPressed: () => setState(() => senhaVisivel = !senhaVisivel),
      ),
    );
  }

  Widget _perfilComum() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Avatar grande com borda translúcida
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 3),
          ),
          child: ClipOval(
            child:
                imagemPerfil != null
                    ? Image.file(imagemPerfil!, fit: BoxFit.cover)
                    : (imagemMemoria != null
                        ? Image.memory(imagemMemoria!, fit: BoxFit.cover)
                        : Container(
                          color: Colors.white,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: appBlue,
                          ),
                        )),
          ),
        ),

        const SizedBox(height: 12),

        // Nome (off-white)
        Text(
          nomeUsuario.isEmpty ? 'Usuário' : nomeUsuario,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 12),

        // // Botão de mudar foto (estilizado, chama sua função existente)
        // GestureDetector(
        //   onTap: selecionarEenviarImagem,
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        //     decoration: BoxDecoration(
        //       color: (isDark ? Colors.white : Colors.white).withOpacity(
        //         isDark ? 0.10 : 0.16,
        //       ),
        //       borderRadius: BorderRadius.circular(24),
        //       border: Border.all(
        //         color: Colors.white.withOpacity(0.22),
        //         width: 1,
        //       ),
        //     ),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       children: [
        //         const Icon(
        //           Icons.photo_camera_outlined,
        //           size: 18,
        //           color: Colors.white,
        //         ),
        //         const SizedBox(width: 8),
        //         const Text(
        //           'Mudar foto de perfil',
        //           style: TextStyle(
        //             color: Colors.white,
        //             fontWeight: FontWeight.w600,
        //             fontSize: 14,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _perfilProdutor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile('Nome', nomeUsuario),
        _infoTile('ID do Tanque', idtanque),
        _infoTile('ID da Região', idregiao),
        _tileSenha(),
      ],
    );
  }

  Widget _perfilColetor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile('Nome do Coletor', nomeUsuario),
        _infoTile('Placa do Caminhão', placa),
        _tileSenha(),
      ],
    );
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
          title: 'Perfil',
          style: const TextStyle(fontSize: 20), // cor é aplicada na Navbar
          backPageRoutePorCargo: {0: '/homeProdutor', 2: '/homeColetor'},
          backPageRoute: '/homeDefault',
          showEndDrawerButton: true,
        ),

        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // card de perfil (glass)
                _GlassCard(
                  child: Column(
                    children: [
                      _perfilComum(), // avatar + botão "mudar foto"
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.24), height: 1),
                      const SizedBox(height: 16),

                      // blocos de info por cargo
                      if (cargo == 0) _perfilProdutor(),
                      if (cargo == 2) _perfilColetor(),
                      if (cargo != 0 && cargo != 2)
                        const Text(
                          "⚠️ Cargo não reconhecido.",
                          style: TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.09 : 0.14,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

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
      // Mostrar diálogo de alerta para o usuário
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

    // setState(() {
    //   binarioImagem = base64Image; // guarda para envio
    // });

    if (binarioImagem != null) {
      String preview =
          binarioImagem!.length > 100
              ? binarioImagem!.substring(0, 100)
              : binarioImagem!;
      print("🧪 Foto base64 (início): $preview");
    }
    print('🖼️ Imagem convertida para base64!');

    //final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    // final idtanque = prefs.getString('idtanque');
    final id = prefs.getInt('id');

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
    return Column(
      children: [
        CircleAvatar(
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
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: selecionarEenviarImagem,
          icon: const Icon(Icons.photo_camera),
          label: const Text('Mudar foto de perfil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: appBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Perfil',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        onNotificationPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notificações zeradas')));
        },
      ),
      endDrawer: MenuDrawer(mqtt: mqtt),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _perfilComum(),
            const SizedBox(height: 24),
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
    );
  }
}
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: const Color(0xFF0097B2),
  //     appBar: Navbar(
  //       title: 'Perfil',
  //       style: const TextStyle(
  //         color: Colors.white,
  //         fontSize: 20,
  //         fontWeight: FontWeight.bold,
  //       ),
  //       onNotificationPressed: () {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Notificações zeradas')));
  //       },
  //     ),
  //     endDrawer: MenuDrawer(mqtt: mqtt),
      /*child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(nomeUsuario),
              accountEmail: const Text('Email'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage:
                    imagemMemoria != null ? MemoryImage(imagemMemoria!) : null,
                child:
                    imagemMemoria == null
                        ? const Icon(Icons.person, size: 50, color: appBlue)
                        : null,
              ),
              decoration: const BoxDecoration(color: appBlue),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () => Navigator.of(context).pushNamed('/home'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () => Navigator.of(context).pushNamed('/perfil'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () => Navigator.of(context).pushNamed('/configuracoes'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                await mqtt.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),*/
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.white,
//               backgroundImage:
//                   imagemPerfil != null
//                       ? FileImage(imagemPerfil!)
//                       : (imagemMemoria != null
//                           ? MemoryImage(imagemMemoria!)
//                           : null),
//               child:
//                   (imagemPerfil == null && imagemMemoria == null)
//                       ? const Icon(Icons.person, size: 50, color: appBlue)
//                       : null,
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               onPressed: selecionarEenviarImagem,
//               icon: const Icon(Icons.photo_camera),
//               label: const Text('Mudar foto de perfil'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: appBlue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),
//             if (binarioImagem != null) ...[
//               const SizedBox(height: 20),
//               const Text(
//                 'Imagem em Binário:',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: SelectableText(
//                     binarioImagem!,
//                     style: const TextStyle(
//                       fontFamily: 'Courier',
//                       color: Colors.white,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//               ),
//             ],

//             const SizedBox(height: 24),

//             _infoTile('Nome', nomeUsuario),
//             _infoTile('ID do Tanque', idtanque),
//             _infoTile('ID da Região', idregiao),
//             ListTile(
//               contentPadding: EdgeInsets.zero,
//               title: const Text(
//                 'Senha',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               subtitle: Text(
//                 senhaVisivel ? senha : '••••••••',
//                 style: const TextStyle(fontSize: 16, color: Colors.white),
//               ),
//               trailing: IconButton(
//                 icon: Icon(
//                   senhaVisivel ? Icons.visibility_off : Icons.visibility,
//                   color: Colors.white,
//                 ),
//                 onPressed: () => setState(() => senhaVisivel = !senhaVisivel),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

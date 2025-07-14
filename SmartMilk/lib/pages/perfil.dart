import 'package:app_smart_milk/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:typed_data/typed_buffers.dart';

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
  bool senhaVisivel = false;
  File? imagemPerfil;
  Uint8List? imagemMemoria;
  String? binarioImagem;

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService(
      onLoginAceito: () {},
      onLoginNegado: (erro) {},
      onCadastroAceito: () {},
      onCadastroNegado: (erro) {},

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

  Future<void> selecionarEenviarImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      setState(() {
        binarioImagem = base64Image; //guarda para envio
      });

      print("🧪 Foto base64 (início): ${binarioImagem?.substring(0, 100)}");

      print('🖼️ Imagem convertida para base64!');
    } else {
      print('⚠️ Nenhuma imagem selecionada.');
    }

    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    final idtanque = prefs.getString('idtanque');

    if (nome == null || idtanque == null || binarioImagem == null) {
      print("⚠️ Dados ausentes para envio da imagem.");
      return;
    }

    final dados = {"foto": binarioImagem, "nome": nome, "idtanque": idtanque};
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
      idtanque = prefs.getString('idtanque') ?? '--';
      idregiao = prefs.getString('idregiao') ?? '--';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0097B2),
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
      endDrawer: Drawer(
        child: ListView(
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            if (binarioImagem != null) ...[
              const SizedBox(height: 20),
              const Text(
                'Imagem em Binário:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    binarioImagem!,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            _infoTile('Nome', nomeUsuario),
            _infoTile('ID do Tanque', idtanque),
            _infoTile('ID da Região', idregiao),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Senha',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}

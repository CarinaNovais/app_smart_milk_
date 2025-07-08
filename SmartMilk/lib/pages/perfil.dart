import 'package:app_smart_milk/components/navbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      nomeUsuario = prefs.getString('nome') ?? 'Usuário';
      senha = prefs.getString('senha') ?? '--';
      idtanque = prefs.getString('idtanque') ?? '--';
      idregiao = prefs.getString('idregiao') ?? '--';

      final fotoBase64 = prefs.getString('foto');
      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
        imagemMemoria = base64Decode(fotoBase64);
      }
    });
  }

  Future<void> selecionarImagem() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickAndSaveImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Câmera'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickAndSaveImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      final fotoBase64 = base64Encode(bytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('foto', fotoBase64);

      await mqtt.enviarNovaFoto(fotoBase64);

      setState(() {
        imagemPerfil = File(pickedImage.path);
        imagemMemoria = bytes;
      });
    }
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
              onPressed: selecionarImagem,
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

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome') ?? 'Usuário';
    final contato = prefs.getString('contato') ?? 'Contato não definido';
    final fotoBase64 = prefs.getString('foto');

    Uint8List? imagem;
    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      imagem = base64Decode(fotoBase64);
    }

    return {'nome': nome, 'contato': contato, 'foto': imagem};
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder(
        future: _getUserData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final nome = data['nome'] ?? 'Usuário';
          final contato = data['contato'] ?? '';
          final foto = data['foto'] as Uint8List?;

          return ListView(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(nome),
                accountEmail: Text(contato),
                currentAccountPicture:
                    foto != null
                        ? CircleAvatar(backgroundImage: MemoryImage(foto))
                        : const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: appBlue, size: 40),
                        ),
                decoration: const BoxDecoration(color: appBlue),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Início'),
                onTap: () => Navigator.of(context).pushNamed('/homeProdutor'),
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
          );
        },
      ),
    );
  }
}

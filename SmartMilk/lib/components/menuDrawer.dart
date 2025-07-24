import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_smart_milk/components/notifiers.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool dadosCarregados = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!dadosCarregados) {
      carregarDadosUsuario();
      dadosCarregados = true;
    }
  }

  Future<void> carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    final nome = prefs.getString('nome') ?? 'Usuário';
    final contato = prefs.getString('contato') ?? 'Contato não definido';
    final fotoBase64 = prefs.getString('foto');

    nomeUsuarioNotifier.value = nome;
    contatoUsuarioNotifier.value = contato;
    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      fotoUsuarioNotifier.value = fotoBase64;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: nomeUsuarioNotifier,
            builder: (context, nome, _) {
              return ValueListenableBuilder<String>(
                valueListenable: contatoUsuarioNotifier,
                builder: (context, contato, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: fotoUsuarioNotifier,
                    builder: (context, fotoBase64, _) {
                      Uint8List? fotoMemoria;
                      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
                        fotoMemoria = base64Decode(fotoBase64);
                      }

                      return UserAccountsDrawerHeader(
                        accountName: Text(nome),
                        accountEmail: Text(contato),
                        currentAccountPicture:
                            fotoMemoria != null
                                ? CircleAvatar(
                                  backgroundImage: MemoryImage(fotoMemoria),
                                )
                                : const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    color: appBlue,
                                    size: 40,
                                  ),
                                ),
                        decoration: const BoxDecoration(color: appBlue),
                      );
                    },
                  );
                },
              );
            },
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}

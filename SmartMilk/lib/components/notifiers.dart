import 'package:flutter/foundation.dart';

/// Notificador da foto do usuário em base64
final fotoUsuarioNotifier = ValueNotifier<String?>(null);

/// Notificador do nome do usuário
final nomeUsuarioNotifier = ValueNotifier<String>('Usuário');

/// Notificador do contato do usuário
final contatoUsuarioNotifier = ValueNotifier<String>('Contato não definido');

final idtanqueUsuarioNotifier = ValueNotifier<String>('id tanque nao definido');

final idRegiaoUsuarioNotifier = ValueNotifier<String>('id regiao nao definido');

final placaUsuarioNotifier = ValueNotifier<String>('placa nao definida');

final senhaUsuarioNotifier = ValueNotifier<String>('senha nao definida');

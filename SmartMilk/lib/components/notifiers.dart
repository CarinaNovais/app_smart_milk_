import 'package:flutter/foundation.dart';

/// Notificador da foto do usuário em base64
final fotoUsuarioNotifier = ValueNotifier<String?>(null);

/// Notificador do nome do usuário
final nomeUsuarioNotifier = ValueNotifier<String>('Usuário');

/// Notificador do contato do usuário
final contatoUsuarioNotifier = ValueNotifier<String>('Contato não definido');

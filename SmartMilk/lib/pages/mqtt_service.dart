import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final Function onLoginAceito;
  final Function(String) onLoginNegado;

  MQTTService({required this.onLoginAceito, required this.onLoginNegado});

  late MqttClient client;

  Future<void> inicializar() async {
    client = MqttServerClient('192.168.66.50', 'app_smart_milk_cliente01');
    client.logging(on: true);
    client.keepAlivePeriod = 20;

    client.onConnected = () {
      print('✅ Conectado ao broker MQTT');
    };

    client.onDisconnected = () {
      print('🔴 Desconectado do broker MQTT');
    };

    client.onSubscribed = (topic) {
      print('📡 Inscrito no tópico: $topic');
    };

    //client.updates!.listen(_onMessageReceived);

    //  try {
    //    await client.connect('csilab', 'WhoAmI#2023');
    //    print('Conectou ao broker, inscrevendo no tópico...');
    //   client.subscribe('login/resultado', MqttQos.atMostOnce);
    //  } catch (e) {
    //    print('Erro ao conectar no MQTT: $e');
    //      client.disconnect();
    //   }
    // }

    try {
      final connectionStatus = await client.connect('csilab', 'WhoAmI#2023');

      if (connectionStatus != null &&
          connectionStatus.state == MqttConnectionState.connected) {
        print('Conectado ao broker, inscrevendo no tópico...');
        client.subscribe('login/resultado', MqttQos.atMostOnce);

        client.updates?.listen(_onMessageReceived);
      } else {
        print('❌ Falha ao conectar ao broker: ${connectionStatus?.state}');
        client.disconnect();
      }
    } catch (e) {
      print('❌ Exceção ao conectar: $e');
      client.disconnect();
    }
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> c) async {
    // Pega a mensagem MQTT recebida
    final recMess = c[0].payload as MqttPublishMessage;
    // Converte os bytes recebidos em texto
    print('📥 Mensagem MQTT recebida!');
    final payload = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );
    print('💬 Conteúdo da mensagem: $payload');

    try {
      // Tenta transformar o texto em um mapa/dicionário (JSON → Map)
      final dados = jsonDecode(payload);

      // Verifica se o JSON tem a estrutura esperada
      if (dados is Map && dados['status'] != null) {
        if (dados['status'] == 'aceito') {
          print('🔄 Recebendo token: ${dados['token']}');
          final prefs =
              await SharedPreferences.getInstance(); // Salva os dados da sessão localmente
          await prefs.setString('token', dados['token']);
          await prefs.setString('expira_em', dados['expira_em']);
          await prefs.setString('nome', dados['nome']);
          print('✅ Token e dados do usuário salvos com sucesso.');
          //
          onLoginAceito();
        } else {
          onLoginNegado(dados['mensagem'] ?? 'Credenciais inválidas');
        }
      } else {
        print('⚠️ Payload inesperado: $payload');
      }
    } catch (e) {
      print('❌ Erro ao processar mensagem: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    client.disconnect();
    print('🔓 Sessão encerrada');
  }
}

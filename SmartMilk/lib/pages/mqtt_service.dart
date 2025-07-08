import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final Function onLoginAceito;
  final Function(String) onLoginNegado;
  final Function onCadastroAceito;
  final Function(String) onCadastroNegado;
  final Function(Map<String, dynamic>)? onDadosTanque;
  final Function()? onFotoEditada;
  final Function(String)? onErroFoto;

  MQTTService({
    required this.onLoginAceito,
    required this.onLoginNegado,
    required this.onCadastroAceito,
    required this.onCadastroNegado,
    this.onDadosTanque,
    this.onFotoEditada,
    this.onErroFoto,
  });

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

    try {
      final connectionStatus = await client.connect('csilab', 'WhoAmI#2023');

      if (connectionStatus != null &&
          connectionStatus.state == MqttConnectionState.connected) {
        print('Conectado ao broker, inscrevendo nos tópicos...');

        client.subscribe('login/resultado', MqttQos.atMostOnce);
        client.subscribe('cadastro/resultado', MqttQos.atMostOnce);
        client.subscribe('tanque/resposta', MqttQos.atMostOnce);
        client.subscribe('perfil/editar_foto/resultado', MqttQos.atMostOnce);
        //client.subscribe('editar_foto/resultado', MqttQos.atMostOnce);
        //client.subscribe("perfil/editar_foto")

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
    final topic = c[0].topic;
    final recMess = c[0].payload as MqttPublishMessage;
    final payload = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );
    print('📥 Mensagem MQTT recebida no tópico "$topic"');
    print('💬 Conteúdo da mensagem: $payload');

    try {
      final dados = jsonDecode(payload);

      if (dados is Map && dados['status'] != null) {
        if (topic == 'login/resultado') {
          if (dados['status'] == 'aceito') {
            print('🔄 Recebendo token: ${dados['token']}');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', dados['token']);
            await prefs.setString('expira_em', dados['expira_em']);
            await prefs.setString('nome', dados['nome']);
            await prefs.setString('senha', dados['senha'].toString());
            await prefs.setString('idtanque', dados['idtanque'].toString());
            await prefs.setString('idregiao', dados['idregiao'].toString());

            print('✅ Token e dados do usuário salvos com sucesso.');
            onLoginAceito();
          } else {
            onLoginNegado(dados['mensagem'] ?? 'Credenciais inválidas');
          }
        } else if (topic == 'cadastro/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ Cadastro aceito!');
            onCadastroAceito();
          } else {
            print('❌ Cadastro negado!');
            onCadastroNegado(dados['mensagem'] ?? 'Erro ao cadastrar');
          }
        } else if (topic == 'tanque/resposta') {
          if (dados['status'] == 'ok') {
            onDadosTanque?.call(dados['dados']);
          } else {
            print('❌ Erro ao buscar dados do tanque: ${dados['mensagem']}');
          }
        } else if (topic == 'perfil/editar_foto/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ Foto atualizada com sucesso no servidor.');
            onFotoEditada?.call();
          } else {
            print('❌ Erro ao atualizar foto: ${dados['mensagem']}');
            onErroFoto?.call(dados['mensagem']);
          }
        }
      } else {
        print('⚠️ Payload inesperado: $payload');
      }
    } catch (e) {
      print('❌ Erro ao processar mensagem: $e');
    }
  }

  Future<void> buscarDadosTanque() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');

    if (nome == null) {
      print('⚠️ Nome do usuário não encontrado no SharedPreferences');
      return;
    }

    final msg = jsonEncode({"nome": nome});
    final builder = MqttClientPayloadBuilder()..addString(msg);
    client.publishMessage(
      "tanque/buscar",
      MqttQos.atMostOnce,
      builder.payload!,
    );
    client.subscribe("tanque/resposta", MqttQos.atMostOnce);

    print('📤 Mensagem enviada para "tanque/buscar": $msg');
  }

  Future<void> enviarNovaFoto(String base64Foto) async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nome');
    final idtanque = prefs.getString('idtanque');

    if (nome == null || idtanque == null) {
      print('⚠️ Dados da sessão ausentes');
      return;
    }

    final msg = jsonEncode({
      "nome": nome,
      "idtanque": int.parse(idtanque),
      "foto": base64Foto,
    });

    final builder = MqttClientPayloadBuilder()..addString(msg);
    client.publishMessage(
      "perfil/editar_foto/entrada",
      MqttQos.atMostOnce,
      builder.payload!,
    );

    print("📤 Nova foto enviada para edição de perfil via MQTT");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    client.disconnect();
    print('🔓 Sessão encerrada');
  }
}

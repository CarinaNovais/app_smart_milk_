import 'dart:convert';
//import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
//import 'package:app_smart_milk/pages/envio_service.dart';

class MQTTService {
  // final Function onLoginAceito;
  // final Function(String) onLoginNegado;
  // final Function onCadastroAceito;
  // final Function(String) onCadastroNegado;
  // final Function(Map<String, dynamic>)? onDadosTanque;
  // final Function()? onFotoEditada;
  // final Function(String)? onErroFoto;

  // MQTTService({
  //   required this.onLoginAceito,
  //   required this.onLoginNegado,
  //   required this.onCadastroAceito,
  //   required this.onCadastroNegado,
  //   this.onDadosTanque,
  //   this.onFotoEditada,
  //   this.onErroFoto,

  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;

  MQTTService._internal();

  late Function onLoginAceito;
  late Function(String) onLoginNegado;
  late Function onCadastroAceito;
  late Function(String) onCadastroNegado;
  Function(Map<String, dynamic>)? onDadosTanque;
  Function()? onFotoEditada;
  Function(String)? onErroFoto;

  late MqttClient client;
  late Function(String campo, String valor) onCampoAtualizado;

  void configurarCallbacks({
    required Function onLoginAceito,
    required Function(String) onLoginNegado,
    required Function onCadastroAceito,
    required Function(String) onCadastroNegado,
    Function(Map<String, dynamic>)? onDadosTanque,
    Function()? onFotoEditada,
    Function(String)? onErroFoto,
    Function(String campo, String valor)? onCampoAtualizado,
  }) {
    this.onLoginAceito = onLoginAceito;
    this.onLoginNegado = onLoginNegado;
    this.onCadastroAceito = onCadastroAceito;
    this.onCadastroNegado = onCadastroNegado;
    this.onDadosTanque = onDadosTanque;
    this.onFotoEditada = onFotoEditada;
    this.onErroFoto = onErroFoto;
    if (onCampoAtualizado != null) this.onCampoAtualizado = onCampoAtualizado;
  }

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
        client.subscribe('fotoAtualizada/resultado', MqttQos.atMostOnce);
        client.subscribe('editarUsuario/resultado', MqttQos.atMostOnce);
        client.subscribe(
          'tanqueIdentificado/resultado',
          MqttQos.atMostOnce,
        ); //qrcode
        client.subscribe('historicoColeta/resultado', MqttQos.atMostOnce);

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
    String preview = payload.length > 120 ? payload.substring(0, 120) : payload;
    print('🧾 [MQTT] Payload recebido (início): $preview');

    //print('🧾 [MQTT] Payload recebido (início): ${payload.substring(0, 120)}');

    try {
      final dados = jsonDecode(payload);
      print('🔍 [MQTT] JSON decodificado: $dados');
      if (dados is Map && dados['status'] != null) {
        if (topic == 'login/resultado') {
          if (dados['status'] == 'aceito') {
            print('🔄 Recebendo token: ${dados['token']}');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', dados['token']);
            await prefs.setString('expira_em', dados['expira_em']);
            await prefs.setString('nome', dados['nome']);
            await prefs.setString('senha', dados['senha'].toString());

            if (dados.containsKey('cargo') && dados['cargo'] != null) {
              final cargo = dados['cargo'];
              await prefs.setInt('cargo', cargo);

              if (cargo == 0) {
                await prefs.setString('idtanque', dados['idtanque'].toString());
                await prefs.setString('idregiao', dados['idregiao'].toString());
              } else if (cargo == 2) {
                await prefs.setString('placa', dados['placa'] ?? 'Sem Placa');
              }
            } else {
              print('⚠️ Campo "cargo" ausente no JSON. Login parcial.');
              await prefs.setInt('cargo', -1);
            }

            print('✅ Token e dados do usuário salvos com sucesso.');
            onLoginAceito();
          } else {
            print('❌ Login negado: ${dados['mensagem']}');
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
        } else if (topic == 'fotoAtualizada/resultado') {
          print('🖼️ Resultado da atualização de foto recebido!');
          if (dados['status'] == 'aceito') {
            print('✅ Foto Aceita');
            onFotoEditada?.call();
          } else {
            print('❌ Foto Negada');
            onErroFoto?.call(dados['mensagem'] ?? 'Erro');
          }
        } else if (topic == 'editarUsuario/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ Campo atualizado com sucesso');
            final campo = dados['campo'] ?? '';
            final valor = dados['valor'] ?? '';
            if (campo.isNotEmpty && valor.isNotEmpty) {
              onCampoAtualizado(campo, valor);
            } else {
              print('⚠️ Resposta de atualização sem campo ou valor.');
            }
          } else {
            print('❌ Falha ao atualizar campo: ${dados['mensagem']}');
            // Ou onErroCampo?.call(dados['mensagem']);
          }
        } else if (topic == 'tanqueIdentificado/resultado') {
          if (dados['status'] == 'ok') {
            print('📷 QR Code identificado com sucesso!');
            //onTanqueIdentificado?.call(dados['dados']);
            onDadosTanque?.call(dados['dados']);
          } else {
            print('❌ Falha ao identificar o QR Code: ${dados['mensagem']}');
          }
        } else if (topic == 'historicoColeta/resultado') {
          //arrumar
          if (dados['status'] == 'aceito') {
            print('✅ coleta enviada');
          } else {
            print('❌ coleta nao enviada!');
          }
        }
      } else {
        print('⚠️ Payload inesperado: $payload');
      }
    } catch (e) {
      print('❌ Erro ao processar mensagem: $e');
    }
  }

  Future<void> buscarDadosTanque({
    String? nome,
    String? idtanque,
    String? idregiao,
    int? cargo,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    nome ??= prefs.getString('nome') ?? '';
    cargo ??= prefs.getInt('cargo');
    idtanque ??= prefs.getString('idtanque') ?? '';
    idregiao ??= prefs.getString('idregiao') ?? '';

    final dados = {
      "nome": nome,
      "idtanque": idtanque,
      "idregiao": idregiao,
      "cargo": cargo,
    };

    if (cargo == 0) {
      // 👨‍🌾 Produtor
      client.publishMessage(
        'tanque/buscar',
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
      );
    } else if (cargo == 2) {
      // 🚛 Coletor
      client.publishMessage(
        'tanqueIdentificado/entrada',
        MqttQos.atLeastOnce,
        MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
      );
    } else {
      print("⚠️ Cargo não reconhecido: $cargo");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    client.disconnect();
    print('🔓 Sessão encerrada');
  }
}

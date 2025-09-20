import 'dart:async';
import 'dart:convert';
// import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:app_smart_milk/components/notifiers.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;

  MQTTService._internal();

  Function()? onPegandoTanqueAceito;
  Function(String msg)? onPegandoTanqueNegado;

  Function(List<Map<String, dynamic>>)? onBuscarColetas;
  Function(List<Map<String, dynamic>>)? onBuscarVacas;
  Function(List<Map<String, dynamic>>)? onBuscarDepositosProdutor;
  Function(List<Map<String, dynamic>>)? onBuscarDevolutivas;
  Function(List<Map<String, dynamic>>)? onBuscarTanquesSelecionados;
  Function(String idtanque, String campo, String valor)?
  onStatusTanqueAtualizado;
  Function(List<Map<String, dynamic>>)? onBuscarTanquesDisponiveis;
  late Function onLoginAceito;
  late Function(String) onLoginNegado;
  late Function onCadastroAceito;
  late Function(String) onCadastroNegado;
  Function(Map<String, dynamic>)? onDadosTanque;
  Function()? onFotoEditada;
  Function(String)? onErroFoto;
  late Function onCadastroVacaAceito;
  late Function(String) onCadastroVacaNegado;
  late Function onVacaDeletada;

  late MqttClient client;
  late Function(String campo, String valor) onCampoAtualizado;
  late Function(String campo, String valor) onCampoVacaAtualizado;

  void configurarCallbacks({
    required Function onLoginAceito,
    required Function(String) onLoginNegado,
    required Function onCadastroAceito,
    required Function(String) onCadastroNegado,
    Function(Map<String, dynamic>)? onDadosTanque,
    Function()? onFotoEditada,
    Function(String)? onErroFoto,
    Function(String campo, String valor)? onCampoAtualizado,
    Function(String campo, String valor)? onCampoVacaAtualizado,
    Function(List<Map<String, dynamic>>)? onBuscarVacas,
    Function(List<Map<String, dynamic>>)? onBuscarColetas,
    Function(List<Map<String, dynamic>>)? onBuscarDepositosProdutor,
    required Function onCadastroVacaAceito,
    required Function(String) onCadastroVacaNegado,
    required Function onVacaDeletada,
    Function(List<Map<String, dynamic>>)? onBuscarDevolutivas,
    Function(List<Map<String, dynamic>>)? onBuscarTanquesSelecionados,
    Function(String idtanque, String campo, String valor)?
    onStatusTanqueAtualizado,
    Function(List<Map<String, dynamic>>)? onBuscarTanquesDisponiveis,

    required void Function() onPegandoTanqueAceito,
    void Function(String msg)? onPegandoTanqueNegado,
  }) {
    this.onLoginAceito = onLoginAceito;
    this.onLoginNegado = onLoginNegado;
    this.onCadastroAceito = onCadastroAceito;
    this.onCadastroNegado = onCadastroNegado;

    this.onPegandoTanqueAceito = onPegandoTanqueAceito;
    this.onPegandoTanqueNegado = onPegandoTanqueNegado;

    this.onPegandoTanqueAceito = onPegandoTanqueAceito;
    if (onPegandoTanqueNegado != null)
      this.onPegandoTanqueNegado = onPegandoTanqueNegado;

    if (onBuscarTanquesDisponiveis != null) {
      this.onBuscarTanquesDisponiveis = onBuscarTanquesDisponiveis;
    }
    if (onStatusTanqueAtualizado != null) {
      this.onStatusTanqueAtualizado = onStatusTanqueAtualizado;
    }
    if (onDadosTanque != null) this.onDadosTanque = onDadosTanque;
    if (onFotoEditada != null) this.onFotoEditada = onFotoEditada;
    if (onErroFoto != null) this.onErroFoto = onErroFoto;

    if (onCampoAtualizado != null) this.onCampoAtualizado = onCampoAtualizado;
    if (onCampoVacaAtualizado != null)
      this.onCampoVacaAtualizado = onCampoVacaAtualizado;

    if (onBuscarColetas != null) this.onBuscarColetas = onBuscarColetas;
    if (onBuscarVacas != null) this.onBuscarVacas = onBuscarVacas;
    if (onBuscarDepositosProdutor != null) {
      this.onBuscarDepositosProdutor = onBuscarDepositosProdutor;
    }
    if (onBuscarDevolutivas != null) {
      this.onBuscarDevolutivas = onBuscarDevolutivas;
    }
    if (onBuscarTanquesSelecionados != null) {
      this.onBuscarTanquesSelecionados = onBuscarTanquesSelecionados;
    }

    this.onCadastroVacaAceito = onCadastroVacaAceito;
    this.onCadastroVacaNegado = onCadastroVacaNegado;
    this.onVacaDeletada = onVacaDeletada;
  }

  bool _isInitialized = false;
  bool _isConnecting = false;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;

  Future<void> inicializar() async {
    // client = MqttServerClient('192.168.66.50', 'app_smart_milk_cliente01');
    // client = MqttServerClient(
    //   '192.168.66.50',
    //   'app_smart_milk_cliente01_${DateTime.now().millisecondsSinceEpoch}',
    // );

    if (_isInitialized &&
        client.connectionStatus?.state == MqttConnectionState.connected) {
      return; // já conectado
    }
    if (_isConnecting) return;
    _isConnecting = true;

    client = MqttServerClient(
      '192.168.66.50',
      'app_smart_milk_cliente01_${DateTime.now().millisecondsSinceEpoch}',
    );

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
        //qrcode
        client.subscribe('tanqueIdentificado/resultado', MqttQos.atMostOnce);
        client.subscribe(
          'cadastroHistoricoColeta/resultado',
          MqttQos.atMostOnce,
        );
        client.subscribe('buscarColetas/resultado', MqttQos.atMostOnce);
        client.subscribe(
          'buscarDepositosProdutor/resultado',
          MqttQos.atMostOnce,
        );
        client.subscribe('cadastroVaca/resultado', MqttQos.atMostOnce);
        client.subscribe('buscarVacas/resultado', MqttQos.atMostOnce);
        client.subscribe('editarVaca/resultado', MqttQos.atMostOnce);
        client.subscribe('deletarVaca/resultado', MqttQos.atMostOnce);
        client.subscribe('buscarDevolutivas/resultado', MqttQos.atMostOnce);
        client.subscribe('atualizarStatusTanque/resultado', MqttQos.atMostOnce);
        client.subscribe(
          'buscarTanquesDisponiveis/resultado',
          MqttQos.atMostOnce,
        );
        client.subscribe('pegandoTanque/resultado', MqttQos.atMostOnce);
        client.subscribe(
          'buscarTanquesSelecionados/resultado',
          MqttQos.atMostOnce,
        );

        // ❗️cancela listener anterior e cria apenas UM
        await _updatesSub?.cancel();
        _updatesSub = client.updates?.listen(_onMessageReceived);

        _isInitialized = true;
      } else {
        print('❌ Falha ao conectar ao broker: ${connectionStatus?.state}');
        client.disconnect();
      }
    } catch (e) {
      print('❌ Exceção ao conectar: $e');
      client.disconnect();
    } finally {
      _isConnecting = false;
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
            await prefs.setInt('id', dados['id']);
            await prefs.setString('nome', dados['nome']);
            await prefs.setString('senha', dados['senha'].toString());
            await prefs.setString('contato', dados['contato'].toString());

            if (dados.containsKey('cargo') && dados['cargo'] != null) {
              final cargo = dados['cargo'];
              await prefs.setInt('cargo', cargo);

              if (cargo == 0) {
                await prefs.setString('idtanque', dados['idtanque'].toString());
                await prefs.setString('idregiao', dados['idregiao'].toString());
              } else if (cargo == 2) {
                await prefs.setString(
                  'idregiao',
                  (dados['idregiao'] ?? 'Sem Região').toString(),
                );
                await prefs.setString('placa', dados['placa'] ?? 'Sem Placa');
              }
            } else {
              print('⚠️ Campo "cargo" ausente no JSON. Login parcial.');
              await prefs.setInt('cargo', -1);
            }

            if (dados.containsKey('foto') && dados['foto'] != null) {
              await prefs.setString('foto', dados['foto']);
              fotoUsuarioNotifier.value = dados['foto'];
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
        } else if (topic == 'cadastroHistoricoColeta/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ coleta enviada');
          } else {
            print('❌ coleta nao enviada!');
          }
        } else if (topic == 'buscarColetas/resultado') {
          if (dados['status'] == 'ok') {
            final coletas = dados['dados'];
            if (coletas is List) {
              final List<Map<String, dynamic>> listaColetas =
                  List<Map<String, dynamic>>.from(coletas);
              onBuscarColetas?.call(listaColetas);
            } else {
              print('⚠️ "dados" não é uma lista.');
            }
          } else {
            print('❌ Erro: ${dados['mensagem']}');
            onBuscarColetas?.call([]);
          }
        } else if (topic == 'buscarDepositosProdutor/resultado') {
          if (dados['status'] == 'ok') {
            final depositos = dados['dados'];
            if (depositos is List) {
              final List<Map<String, dynamic>> listaDepositos =
                  List<Map<String, dynamic>>.from(depositos);
              onBuscarDepositosProdutor?.call(listaDepositos);
            } else {
              print('⚠️ "dados" não é uma lista.');
            }
          } else {
            print(
              '❌ Erro topico buscardepositosprodutor: ${dados['mensagem']}',
            );
            onBuscarDepositosProdutor?.call([]);
          }
        } else if (topic == 'cadastroVaca/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ Cadastro aceito!');
            // unawaited(buscarVacas());
            onCadastroVacaAceito();
          } else {
            print('❌ Cadastro de Vaca negado!');
            onCadastroVacaNegado(dados['mensagem'] ?? 'Erro ao cadastrar Vaca');
          }
        } else if (topic == 'buscarVacas/resultado') {
          if (dados['status'] == 'ok') {
            final vacas = dados['dados'];
            if (vacas is List) {
              final List<Map<String, dynamic>> listaVacas =
                  List<Map<String, dynamic>>.from(vacas);
              onBuscarVacas?.call(listaVacas);
            } else {
              print('⚠️ "dados" não é uma lista.');
              onBuscarVacas?.call(
                [],
              ); // garante que callback é chamado mesmo com erro
            }
          } else {
            print('❌ Erro topico buscarVacas/resultado: ${dados['mensagem']}');
            onBuscarVacas?.call([]);
          }
        } else if (topic == 'editarVaca/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ Campo atualizado com sucesso');
            final campo = dados['campo'] ?? '';
            final valor = dados['valor'] ?? '';
            if (campo.isNotEmpty && valor.isNotEmpty) {
              onCampoVacaAtualizado(campo, valor);
            } else {
              print('⚠️ Resposta de atualização sem campo ou valor.');
            }
          } else {
            print('❌ Falha ao atualizar campo: ${dados['mensagem']}');
          }
        } else if (topic == 'deletarVaca/resultado') {
          if (dados['status'] == 'aceito') {
            print('✅ Vaca deletada com sucesso');
            onVacaDeletada();
          } else {
            print('❌ Falha ao deletar vaca: ${dados['mensagem']}');
          }
        } else if (topic == 'buscarDevolutivas/resultado') {
          if (dados['status'] == 'ok') {
            final devolutivas = dados['dados'];
            if (devolutivas is List) {
              final List<Map<String, dynamic>> listaDevolutivas =
                  List<Map<String, dynamic>>.from(devolutivas);
              onBuscarDevolutivas?.call(listaDevolutivas);
            } else {
              print('⚠️ "dados" não é uma lista.');
            }
          } else {
            print(
              '❌ Erro topico buscarDevolutivas/resultado: ${dados['mensagem']}',
            );
            onBuscarDevolutivas?.call([]);
          }
        } else if (topic == 'atualizarStatusTanque/resultado') {
          if (dados['status'] == 'ok') {
            onStatusTanqueAtualizado?.call(
              dados['idtanque'],
              dados['campo'],
              dados['valor'],
            );
            print('✅ Status do tanque atualizado com sucesso');
          } else {
            print(
              '❌ Falha ao atualizar status do tanque: ${dados['mensagem']}',
            );
          }
        } else if (topic == 'buscarTanquesDisponiveis/resultado') {
          if (dados['status'] == 'ok') {
            final tanques = dados['dados'];
            if (tanques is List) {
              final List<Map<String, dynamic>> listaTanques =
                  List<Map<String, dynamic>>.from(tanques);
              onBuscarTanquesDisponiveis?.call(listaTanques);
            } else {
              print('⚠️ "dados" não é uma lista.');
            }
          } else {
            print(
              '❌ Erro topico buscarTanquesDisponiveis/resultado: ${dados['mensagem']}',
            );
            onBuscarTanquesDisponiveis?.call([]);
          }
        } else if (topic == 'pegandoTanque/resultado') {
          final status = dados['status'];
          if (status == 'ok') {
            print('✅ Coleta selecionada com sucesso');
            onPegandoTanqueAceito?.call();
          } else {
            final msg =
                dados['mensagem']?.toString() ?? 'Falha ao selecionar o tanque';
            print('❌ $msg');
            onPegandoTanqueNegado?.call(msg);
          }
        } else if (topic == 'buscarTanquesSelecionados/resultado') {
          if (dados['status'] == 'ok') {
            final tanques = dados['dados'];
            if (tanques is List) {
              final List<Map<String, dynamic>> listaTanques =
                  List<Map<String, dynamic>>.from(tanques);
              onBuscarTanquesSelecionados?.call(listaTanques);
            } else {
              print('⚠️ "dados" não é uma lista.');
            }
          } else {
            print(
              '❌ Erro topico buscarTanquesSelecionados/resultado: ${dados['mensagem']}',
            );
            onBuscarTanquesSelecionados?.call([]);
          }
        } else {
          print('⚠️ Payload inesperado: $payload');
        }
      }
    } catch (e) {
      print('❌ Erro ao processar mensagem: $e');
    }
  }

  Future<void> buscarTanquesSelecionados() async {
    final prefs = await SharedPreferences.getInstance();
    final coletor_id = prefs.getInt('id'); // id do coletor
    if (coletor_id == null) {
      print('ID do usuario nao encontrado nos SharedPreferences');
      return;
    }
    final dados = {"coletor_id": coletor_id};

    client.publishMessage(
      'buscarTanquesSelecionados/entrada',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
    );
  }

  Future<void> buscarTanquesDisponiveis({String? idregiao}) async {
    final prefs = await SharedPreferences.getInstance();

    idregiao ??= prefs.getString('idregiao');
    if (idregiao == null) {
      print('ID da regiao do usuario nao encontrado nos SharedPreferences');
      return;
    }
    final dados = {"idregiao": idregiao};

    client.publishMessage(
      'buscarTanquesDisponiveis/entrada',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
    );
  }

  Future<void> buscarDevolutivas() async {
    final prefs = await SharedPreferences.getInstance();
    // final int? usuarioId = prefs.getInt('id');
    /// ID do tanque do usuário obtido dos SharedPreferences.
    final idtanque = prefs.getString('idtanque');

    if (idtanque == null) {
      print('ID do tanque do usuário não encontrado nos SharedPreferences');
      return;
    }

    /// Dados a serem enviados ao broker.
    final dados = {"idtanque": idtanque};

    /// Publica a mensagem no tópico `buscarDevolutivas/entrada`.
    client.publishMessage(
      'buscarDevolutivas/entrada',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
    );
  }

  Future<void> buscarVacas() async {
    final prefs = await SharedPreferences.getInstance();
    final int? usuarioId = prefs.getInt('id');

    if (usuarioId == null) {
      print('ID do usuário não encontrado nos SharedPreferences');
      return;
    }

    final dados = {"usuario_id": usuarioId};

    client.publishMessage(
      'buscarVacas/entrada',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
    );
  }

  Future<void> buscarColetas({String? nome}) async {
    final prefs = await SharedPreferences.getInstance();
    nome ??= prefs.getString('nome') ?? '';

    final dados = {"nome": nome};

    client.publishMessage(
      'buscarColetas/entrada',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
    );
  }

  Future<void> buscarDepositosProdutor({int? id}) async {
    final prefs = await SharedPreferences.getInstance();

    id ??= prefs.getInt('id');
    print('idusuario: $id');

    if (id == null) {
      print('Erro: usuario_id não encontrado.');
      return;
    }

    final dados = {"usuario_id": id};

    client.publishMessage(
      'buscarDepositosProdutor/entrada',
      MqttQos.atLeastOnce,
      MqttClientPayloadBuilder().addString(jsonEncode(dados)).payload!,
    );
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

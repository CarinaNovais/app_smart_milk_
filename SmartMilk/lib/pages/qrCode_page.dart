import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_smart_milk/pages/mqtt_service.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/detalhesTanquePage.dart';

const Color appBlue = Color(0xFF0097B2);

String _decodeHtmlEntities(String s) {
  return s
      .replaceAll('&#34;', '"')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

String _fixWeirdQr(String s) {
  var out = _decodeHtmlEntities(s.trim());

  // Corrige caso venha com ; grudado no nome da chave: "idtanque;":5
  out = out.replaceAll(RegExp(r'"([a-zA-Z_]+);"\s*:'), r'"\1":');

  return out;
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  late MQTTService mqtt;
  bool _isProcessing = false;
  bool _flashOn = false;
  bool _hasPermission = true;

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();

    mqtt.configurarCallbacks(
      onLoginAceito: () {},
      onLoginNegado: (_) {},
      onCadastroAceito: () {},
      onCadastroNegado: (_) {},
      onDadosTanque: (dados) {
        if (_isProcessing) return;
        _isProcessing = true;
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => DetalhesTanquePage(
                  nome: dados['nome'],
                  idTanque: int.parse(dados['idtanque'].toString()),
                  idRegiao: int.parse(dados['idregiao'].toString()),
                  ph: _toDouble(dados['ph']),
                  temp: _toDouble(dados['temp']),
                  nivel: _toDouble(dados['nivel']),
                  amonia: _toDouble(dados['amonia']),
                  metano: _toDouble(dados['metano']),
                  condutividade: _toDouble(dados['condutividade']),
                  turbidez: _toDouble(dados['turbidez']),
                  co2: _toDouble(dados['co2']),
                ),
          ),
        ).then((_) {
          _isProcessing = false;
          controller?.resumeCamera();
        });
      },
      onCadastroVacaAceito: () {},
      onCadastroVacaNegado: (_) {},
      onVacaDeletada: () {},
      onBuscarDevolutivas: (_) {},
      onPegandoTanqueAceito: () {},
    );

    mqtt.inicializar();
  }

  @override
  void reassemble() {
    super.reassemble();
    // hot reload camera handling
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)]
              : const [Color(0xFFB2EBF2), Color(0xFF80DEEA), Color(0xFF64B5F6)],
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,

        appBar: Navbar(
          title: 'Scanner QR',
          style: const TextStyle(fontSize: 20),
          backPageRoute:
              '/homeColetor', // ajuste se quiser voltar para outra rota
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: Stack(
            children: [
              // Área do scanner com bordas arredondadas
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.white,
                      borderRadius: 12,
                      borderLength: 32,
                      borderWidth: 6,
                      cutOutSize: MediaQuery.of(context).size.width * 0.72,
                    ),
                    onPermissionSet: (ctrl, p) {
                      setState(() => _hasPermission = p);
                      if (!p && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sem permissão de câmera. Verifique as permissões do app.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),

              // Caixa glass inferior com status e botões
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.white)
                            .withOpacity(isDark ? 0.09 : 0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _hasPermission
                                    ? Icons.qr_code_scanner
                                    : Icons.lock,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  !_hasPermission
                                      ? 'Permissão de câmera negada.'
                                      : (result?.code != null
                                          ? 'Lido: ${result!.code}'
                                          : 'Aponte a câmera para o QR Code'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Botões de ação (flash, trocar câmera, pausar/resumir)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionButton(
                                icon:
                                    _flashOn
                                        ? Icons.flash_on_rounded
                                        : Icons.flash_off_rounded,
                                label: _flashOn ? 'Flash ON' : 'Flash OFF',
                                onTap: () async {
                                  await controller?.toggleFlash();
                                  final status =
                                      await controller?.getFlashStatus();
                                  setState(() => _flashOn = status ?? false);
                                },
                              ),
                              _ActionButton(
                                icon: Icons.cameraswitch_rounded,
                                label: 'Trocar',
                                onTap: () async {
                                  await controller?.flipCamera();
                                },
                              ),
                              _ActionButton(
                                icon: Icons.pause_circle_filled_rounded,
                                label: 'Pausar',
                                onTap: () async {
                                  await controller?.pauseCamera();
                                },
                              ),
                              _ActionButton(
                                icon: Icons.play_circle_fill_rounded,
                                label: 'Retomar',
                                onTap: () async {
                                  await controller?.resumeCamera();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    // tenta sincronizar o estado do flash ao iniciar
    controller.getFlashStatus().then(
      (v) => setState(() => _flashOn = v ?? false),
    );

    controller.scannedDataStream.listen((scanData) async {
      // evita flood de leituras
      await controller.pauseCamera();
      setState(() => result = scanData);

      final data = result?.code;
      if (data == null) {
        controller.resumeCamera();
        return;
      }

      try {
        //final Map<String, dynamic> json = jsonDecode(data);
        final fixed = _fixWeirdQr(data);
        final Map<String, dynamic> json = jsonDecode(fixed);

        final String nome = json['nome'].toString();
        final String idtanque = json['idtanque'].toString();
        final String idregiao = json['idregiao'].toString();

        final prefs = await SharedPreferences.getInstance();
        final int? cargo = prefs.getInt('cargo');

        if (cargo != null) {
          mqtt.buscarDadosTanque(
            nome: nome,
            idtanque: idtanque,
            idregiao: idregiao,
            cargo: cargo,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cargo não encontrado no dispositivo.'),
              ),
            );
          }
          controller.resumeCamera();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('QR inválido: $e')));
        }
        controller.resumeCamera();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

/// Botão pequeno para a barra de ações
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

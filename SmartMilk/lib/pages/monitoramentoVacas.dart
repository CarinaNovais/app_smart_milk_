import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/my_button.dart';
import 'package:app_smart_milk/pages/listarVacas.dart';
import 'package:app_smart_milk/pages/cadastroVacas.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);

class monitoramentoVacasPage extends StatelessWidget {
  final MQTTService mqtt;

  const monitoramentoVacasPage({super.key, required this.mqtt});

  void acaoBotaoListarVacas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ListaVacasPage()),
    );
  }

  void acaoBotaoCadastrarVacas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CadastroVacasPage()),
    );
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
          title: 'Monitoramento das Vacas',
          style: const TextStyle(fontSize: 20), // cor é da Navbar
          backPageRoute: '/homeProdutor',
          showEndDrawerButton: true,
        ),

        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // título da seção
                    Row(
                      children: [
                        Icon(
                          Icons.pets_rounded,
                          size: 22,
                          color: isDark ? Colors.white : appBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ações rápidas',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : appBlue,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: 0.85,
                      child: Text(
                        'Gerencie facilmente o rebanho: liste animais cadastrados ou inclua uma nova vaca.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Botões
                    MyButton(
                      onTap: () => acaoBotaoListarVacas(context),
                      text: 'Listar Vacas',
                    ),
                    const SizedBox(height: 14),
                    MyButton(
                      onTap: () => acaoBotaoCadastrarVacas(context),
                      text: 'Cadastrar Nova Vaca',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.09 : 0.15,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

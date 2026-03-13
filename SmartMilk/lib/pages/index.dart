import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_smart_milk/pages/login_page.dart';
import 'package:app_smart_milk/components/my_button.dart';

class IndexPage extends StatelessWidget {
  const IndexPage({super.key});

  void _acaoBotaoProdutor(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(cargo: 0)),
    );
  }

  void _acaoBotaoColetor(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(cargo: 2)),
    );
  }

  void _acaoCadastro(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(context, '/cadastro', arguments: {'cargo': 0});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? const [
                Color(0xFF0F172A), // slate-900
                Color(0xFF1E293B), // slate-800
                Color(0xFF334155), // slate-700
              ]
              : const [
                Color(0xFFB2EBF2), // cyan-100
                Color(0xFF80DEEA), // cyan-200
                Color(0xFF64B5F6), // blue-300
              ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Stack(
            children: [
              // blobs decorativos
              Positioned(
                top: -60,
                left: -30,
                child: _Blob(size: 180, color: Colors.white.withOpacity(0.25)),
              ),
              Positioned(
                bottom: -50,
                right: -20,
                child: _Blob(size: 160, color: Colors.white.withOpacity(0.18)),
              ),

              // conteúdo
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // logo
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Image.asset(
                            'lib/images/VACALOGO.png',
                            height: 120,
                            width: 120,
                            filterQuality: FilterQuality.high,
                          ),
                        ),

                        const Text(
                          'Smart Milk',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Qualidade e coleta inteligente de leite',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black.withOpacity(0.6),
                          ),
                        ),

                        const SizedBox(height: 22),

                        MyButton(
                          onTap: () => _acaoBotaoProdutor(context),
                          text: 'Entrar como Produtor',
                        ),
                        const SizedBox(height: 12),
                        MyButton(
                          onTap: () => _acaoBotaoColetor(context),
                          text: 'Entrar como Coletor',
                        ),

                        const SizedBox(height: 16),

                        // link de cadastro
                        GestureDetector(
                          onTap: () => _acaoCadastro(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black)
                                  .withOpacity(0.06),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person_add_alt_1, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Primeira vez? Cadastre-se',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              // rodapé sutil
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: 0.6,
                    child: Text(
                      '© ${DateTime.now().year} app_smart_milk',
                      style: const TextStyle(fontSize: 12),
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
}

// card translúcido com blur
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(
              isDark ? 0.09 : 0.14,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 2,
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

// blob decorativo
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

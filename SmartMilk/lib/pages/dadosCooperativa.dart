import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:app_smart_milk/components/navbar.dart';
import 'package:app_smart_milk/components/menuDrawer.dart';
import 'package:app_smart_milk/pages/mqtt_service.dart';

const Color appBlue = Color(0xFF0097B2);
late MQTTService mqtt;

class DadoscooperativaPage extends StatefulWidget {
  const DadoscooperativaPage({super.key});

  @override
  State<DadoscooperativaPage> createState() => _SobreCooperRitaPageState();
}

class _SobreCooperRitaPageState extends State<DadoscooperativaPage> {
  @override
  void initState() {
    super.initState();
    mqtt = MQTTService();
    mqtt.inicializar();
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
          title: 'Sobre Cooperativa',
          style: const TextStyle(fontSize: 20),
          backPageRoutePorCargo: {0: '/homeProdutor', 2: '/homeColetor'},
          backPageRoute: '/homeDefault',
          showEndDrawerButton: true,
        ),
        endDrawer: MenuDrawer(mqtt: mqtt),

        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LOGO + TÍTULO
              _GlassCard(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/images/cooperativaLogo.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CooperRita: Tradição e Qualidade desde 1957',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : appBlue,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        'Fundada em 29 de dezembro de 1957, a CooperRita nasceu da união de 63 produtores rurais de Santa Rita do Sapucaí, no Sul de Minas Gerais. Com o objetivo de valorizar a atividade rural local, a cooperativa cresceu e se consolidou como uma das mais importantes do estado.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ÁREAS DE ATUAÇÃO
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.grid_view_rounded,
                      title: 'Áreas de Atuação',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Pill(text: 'Leite', icon: Icons.local_drink_outlined),
                        _Pill(text: 'Café', icon: Icons.coffee_outlined),
                        _Pill(text: 'Lácteos', icon: Icons.icecream_outlined),
                        _Pill(
                          text: 'Nutrição Animal',
                          icon: Icons.pets_outlined,
                        ),
                        _Pill(
                          text: 'Agropecuária',
                          icon: Icons.agriculture_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // MISSÃO
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.flag_rounded,
                      title: 'Missão',
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.9,
                      child: Text(
                        'Promover o desenvolvimento sustentável e colaborativo do setor agropecuário, oferecendo produtos e serviços de qualidade aos seus cooperados.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // LOCALIZAÇÃO + CONTATO
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SectionTitle(
                      icon: Icons.place_rounded,
                      title: 'Localização & Contato',
                    ),
                    SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text:
                          'Rua Cel. João Euzébio de Almeida, 528 – Centro\nSanta Rita do Sapucaí - MG',
                    ),
                    SizedBox(height: 8),
                    _InfoRow(icon: Icons.call_outlined, text: '(35) 3473-3500'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // CTA
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Saiba mais'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: appBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

/// Card translúcido
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF0097B2),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0097B2),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            ' ',
            style: TextStyle(fontSize: 0), // espaçador safe
          ),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white : const Color(0xFF0097B2),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

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
    return Scaffold(
      backgroundColor: appBlue,
      appBar: Navbar(
        title: 'Sobre Cooperativa',
        style: const TextStyle(color: Colors.white, fontSize: 20),
        backPageRoutePorCargo: {
          0: '/homeProdutor', // se cargo == 0
          2: '/homeColetor', // se cargo == 2
        },
        backPageRoute: '/homeDefault', // fallback caso cargo não esteja no mapa
        showEndDrawerButton: true,
      ),

      endDrawer: MenuDrawer(mqtt: mqtt),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo da CooperRita
            Center(
              child: Image.asset('lib/images/cooperativaLogo.png', height: 120),
            ),
            const SizedBox(height: 16),
            Text(
              'CooperRita: Tradição e Qualidade desde 1957',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fundada em 29 de dezembro de 1957, a CooperRita nasceu da união de 63 produtores rurais de Santa Rita do Sapucaí, no Sul de Minas Gerais. Com o objetivo de valorizar a atividade rural local, a cooperativa cresceu e se consolidou como uma das mais importantes do estado.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            Text(
              'Áreas de Atuação:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Leite\n• Café\n• Indústria de Lácteos\n• Nutrição Animal\n• Agropecuária',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Missão:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Promover o desenvolvimento sustentável e colaborativo do setor agropecuário, oferecendo produtos e serviços de qualidade aos seus cooperados.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 16),
            Text(
              'Localização:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rua Cel. João Euzébio de Almeida, 528 – Centro\nSanta Rita do Sapucaí - MG\nTelefone: (35) 3473-3500',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Aqui você pode colocar a ação do botão, por exemplo abrir o site
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: appBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Saiba Mais',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

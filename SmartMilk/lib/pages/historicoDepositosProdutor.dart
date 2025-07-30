// import 'package:app_smart_milk/pages/mqtt_service.dart';
// import 'package:flutter/material.dart';
// import 'package:app_smart_milk/components/navbar.dart';
// import 'package:app_smart_milk/components/menuDrawer.dart';
// import 'package:app_smart_milk/pages/envio_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const Color appBlue = Color(0xFF0097B2);

// class DepositosprodutorPage extends StatefulWidget {
//   const DepositosprodutorPage({super.key});

//   @override
//   State<DepositosprodutorPage> createState() => _DepositosprodutorPage();
// }

// class _DepositosprodutorPage extends State<DepositosprodutorPage> {
//   final mqtt = MQTTService();
//   String nome = '';
//   String idtanque = '';
//   String idregiao = '';

//   Future<List<dynamic>>? futureColetas;

//   @override
//   void initState() {
//     super.initState();
//     _carregarPreferencias();
//   }

//   Future<void> _carregarPreferencias() async {
//     final prefs = await SharedPreferences.getInstance();

//     setState(() {
//       nome = prefs.getString('nome') ?? '';
//       idtanque = prefs.getString('idtanque') ?? '';
//       idregiao = prefs.getString('idregiao') ?? '';

//       // Após carregar os dados, dispara a busca de coletas
//       futureColetas = buscarColetas(
//         nome: nome,
//         idtanque: idtanque,
//         idregiao: idregiao,
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: appBlue,
//       appBar: const Navbar(
//         title: 'Depósitos',
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       endDrawer: MenuDrawer(mqtt: mqtt),
//       body:
//           futureColetas == null
//               ? const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               )
//               : FutureBuilder<List<dynamic>>(
//                 future: futureColetas!,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(
//                       child: CircularProgressIndicator(color: Colors.white),
//                     );
//                   } else if (snapshot.hasError) {
//                     return const Center(
//                       child: Text(
//                         'Erro ao carregar dados',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     );
//                   } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return const Center(
//                       child: Text(
//                         'Nenhum dado encontrado',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     );
//                   } else {
//                     final coletas = snapshot.data!;
//                     return ListView.builder(
//                       itemCount: coletas.length,
//                       itemBuilder: (context, index) {
//                         final coleta = coletas[index];
//                         return Card(
//                           margin: const EdgeInsets.all(10),
//                           child: ListTile(
//                             title: Text(
//                               'Tanque ${coleta["idTanque"]} - Região ${coleta["idRegiao"]}',
//                             ),
//                             subtitle: Text(
//                               'pH: ${coleta["ph"]} | Temp: ${coleta["temperatura"]}°C | Amônia: ${coleta["amonia"]}',
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   }
//                 },
//               ),
//     );
//   }
// }

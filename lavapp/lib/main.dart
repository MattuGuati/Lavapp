import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/ticket_list_screen.dart';
import 'screens/preferences_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Abrir todos los boxes necesarios
  await Hive.openBox<Map>('ticketsBox'); // Para tickets
  await Hive.openBox('preferences');     // Para costo por bolsa
  await Hive.openBox('users');           // Para login
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LavApp',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TicketListScreen(),
      routes: {
        '/preferences': (context) => const PreferencesScreen(),
      },
    );
  }
}
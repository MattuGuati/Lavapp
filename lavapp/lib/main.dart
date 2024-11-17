import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/ticket_list_screen.dart';
import 'screens/preferences_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService().initializeHive(); // Inicializa Hive y la base de datos

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LavApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TicketListScreen(),
      routes: {
        '/preferences': (context) => const PreferencesScreen(),
      },
    );
  }
}

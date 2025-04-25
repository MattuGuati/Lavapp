import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lavapp/screens/ticket_list_screen.dart';
import 'package:lavapp/screens/new_ticket_screen.dart';
import 'package:lavapp/screens/edit_ticket_screen.dart';
import 'package:lavapp/screens/consult_tickets_screen.dart';
import 'package:lavapp/screens/reports_screen.dart';
import 'package:lavapp/screens/cost_screen.dart';
import 'package:lavapp/screens/clients_screen.dart';
import 'package:lavapp/screens/preferences_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const TicketListScreen(),
        '/new': (context) => const NewTicketScreen(),
        '/consult': (context) => const ConsultTicketsScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/cost': (context) => const CostScreen(),
        '/clients': (context) => const ClientsScreen(),
        '/preferences': (context) => const PreferencesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args.containsKey('ticket')) {
            return MaterialPageRoute(
              builder: (context) => EditTicketScreen(ticket: args['ticket']),
            );
          }
          return null;
        }
        return null;
      },
    );
  }
}
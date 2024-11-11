import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String boxName = 'ticketsBox';
  late Box<Map> ticketsBox;

  Future<void> initializeHive() async {
    await Hive.initFlutter();
    ticketsBox = await Hive.openBox<Map>(boxName);
  }

  // Método para obtener todos los tickets
  List<Map<String, dynamic>> getAllTickets() {
    return ticketsBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Método para insertar un nuevo ticket
  Future<void> insertTicket(Map<String, dynamic> ticket) async {
    await ticketsBox.add(ticket);
  }

  // Método para actualizar el estado de un ticket
  Future<void> updateTicketStatus(int index, String estado) async {
    final ticket = Map<String, dynamic>.from(ticketsBox.getAt(index)!);
    ticket['estado'] = estado;
    await ticketsBox.putAt(index, ticket);
  }

  // Método para eliminar un ticket por su índice
  Future<void> deleteTicket(int index) async {
    await ticketsBox.deleteAt(index);
  }
}

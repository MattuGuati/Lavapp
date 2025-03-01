import 'package:hive/hive.dart';

class DatabaseService {
  late Box<Map> ticketsBox;

  DatabaseService() {
    _initializeHive(); // Inicialización en el constructor
  }

  Future<void> _initializeHive() async {
    ticketsBox = await Hive.openBox<Map>('ticketsBox'); // Inicialización asíncrona
  }

  // Método para obtener todos los tickets
  Future<List<Map<String, dynamic>>> getAllTickets() async {
    await _initializeHive(); // Asegura la inicialización antes de acceder
    return ticketsBox.values.cast<Map<String, dynamic>>().toList();
  }

  // Método para insertar un nuevo ticket
  Future<void> insertTicket(Map<String, dynamic> ticket) async {
    await _initializeHive();
    await ticketsBox.add(ticket);
  }

  // Método para actualizar el estado de un ticket
  Future<void> updateTicketStatus(int index, String status) async {
    await _initializeHive();
    final ticket = ticketsBox.getAt(index) as Map<String, dynamic>?;
    if (ticket != null) {
      ticket['estado'] = status;
      await ticketsBox.putAt(index, ticket);
    }
  }

  // Método para eliminar un ticket
  Future<void> deleteTicket(int index) async {
    await _initializeHive();
    await ticketsBox.deleteAt(index);
  }
}
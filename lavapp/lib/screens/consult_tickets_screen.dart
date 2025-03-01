import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'edit_ticket_screen.dart';

class ConsultTicketsScreen extends StatefulWidget {
  const ConsultTicketsScreen({super.key});

  @override
  State<ConsultTicketsScreen> createState() => _ConsultTicketsScreenState();
}

class _ConsultTicketsScreenState extends State<ConsultTicketsScreen> {
  final dbService = DatabaseService();
  List<Map<String, dynamic>> tickets = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final data = await dbService.getAllTickets();
      if (data.isNotEmpty) {
        setState(() {
          tickets = data.reversed.toList(); // Ordena de más nuevo a más viejo
        });
      } else {
        setState(() {
          tickets = [];
        });
      }
    } catch (e) {
      print('Error loading tickets: $e'); // Para depuración
      setState(() {
        tickets = [];
      });
    }
  }

  Future<void> _searchTickets(String query) async {
    try {
      final data = await dbService.getAllTickets();
      final filtered = data.where((ticket) {
        return ticket['celular'].toString().contains(query);
      }).toList().reversed.toList();
      setState(() {
        tickets = filtered.isNotEmpty ? filtered : [];
      });
    } catch (e) {
      print('Error searching tickets: $e'); // Para depuración
      setState(() {
        tickets = [];
      });
    }
  }

  Future<void> _editTicket(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTicketScreen(ticket: tickets[index])),
    );
    if (result != null && result is Map<String, dynamic>) {
      await dbService.updateTicketStatus(index, result['estado']);
      _loadTickets();
    }
  }

  Future<void> _deleteTicket(int index) async {
    await dbService.deleteTicket(index);
    _loadTickets();
  }

  void _returnToMain() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Buscar por teléfono'),
                  content: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      _searchTickets(value); // Actualiza en tiempo real
                    },
                    decoration: const InputDecoration(hintText: 'Ingrese número'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _loadTickets();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        _searchTickets(_searchController.text);
                        Navigator.pop(context);
                      },
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: tickets.isEmpty
          ? const Center(
              child: Text(
                'No hay tickets disponibles',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text("${ticket['nombre']} #${ticket['celular']}"),
                    subtitle: Text("Estado: ${ticket['estado']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.blue),
                          onPressed: () => _returnToMain(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTicket(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _editTicket(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
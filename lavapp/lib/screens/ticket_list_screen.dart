import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import 'new_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Map<String, dynamic>> tickets = [];
  final dbService = DatabaseService();
  int costPerBag = 500;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _loadPreferences();
  }

  Future<void> _loadTickets() async {
    final data = dbService.getAllTickets();
    setState(() {
      tickets = data;
    });
  }

  Future<void> _loadPreferences() async {
    final box = await Hive.openBox('preferences');
    setState(() {
      costPerBag = box.get('costPerBag', defaultValue: 500);
    });
  }

  Future<void> _addNewTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewTicketScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      await dbService.insertTicket(result);
      setState(() {
        tickets.add(result);
      });
    }
  }

  void _changeTicketStatus(int index) async {
    final estados = ['En Proceso', 'Pendiente', 'Entregado'];
    final currentIndex = estados.indexOf(tickets[index]['estado']);
    final newIndex = (currentIndex + 1) % estados.length;

    setState(() {
      tickets[index]['estado'] = estados[newIndex];
    });

    await dbService.updateTicketStatus(index, estados[newIndex]);

    if (tickets[index]['estado'] == 'Pendiente') {
      _sendWhatsAppMessage(index);
    }

    if (tickets[index]['estado'] == 'Entregado') {
      Future.delayed(const Duration(seconds: 5), () async {
        await dbService.deleteTicket(index);
        setState(() {
          tickets.removeAt(index);
        });
      });
    }
  }

  void _deleteTicket(int index) async {
    await dbService.deleteTicket(index);
    setState(() {
      tickets.removeAt(index);
    });
  }

  void _sendWhatsAppMessage(int index) {
    final ticket = tickets[index];
    final String phoneNumber = ticket['celular'];
    final int cost = ticket['cantidadBolsas'] * costPerBag;
    final String message =
        'Hola ${ticket['nombre']}, te informamos que podés pasar a retirar la ropa. El costo es \$${cost}. ¡Gracias por confiar en nosotros!';

    final Uri whatsappUrl =
        Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    launchUrl(whatsappUrl, mode: LaunchMode.externalApplication).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LavApp',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/preferences');
          },
        ),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "${tickets[index]['nombre']}  #${tickets[index]['celular']}",
                            style: const TextStyle(color: Colors.blue, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _changeTicketStatus(index),
                            child: Chip(
                              label: Text(
                                tickets[index]['estado'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: tickets[index]['estado'] == 'Entregado'
                                  ? Colors.green
                                  : (tickets[index]['estado'] == 'Pendiente'
                                      ? Colors.orange
                                      : Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteTicket(index);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _addNewTicket,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

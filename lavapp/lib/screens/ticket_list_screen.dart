import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'new_ticket_screen.dart';
import 'edit_ticket_screen.dart';
import 'consult_tickets_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Map<String, dynamic>> tickets = [];
  final dbService = DatabaseService();
  final apiService = ApiService();
  int costPerBag = 500;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _loadPreferences();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final box = await Hive.openBox('users');
    final username = box.get('username');
    final password = box.get('password');
    if (username == 'admin' && password == '1234') {
      setState(() {
        isLoggedIn = true;
      });
    } else {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    String username = '';
    String password = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'LavApp - Iniciar Sesión',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withAlpha(128), spreadRadius: 2, blurRadius: 5)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) => username = value,
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                obscureText: true,
                onChanged: (value) => password = value,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              if (username == 'admin' && password == '1234') {
                final box = Hive.box('users');
                box.put('username', username);
                box.put('password', password);
                setState(() {
                  isLoggedIn = true;
                });
                _loadTickets();
                _loadPreferences();
              } else {
                _showLoginDialog();
              }
            },
            child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTickets() async {
    final data = await dbService.getAllTickets();
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
    if (!isLoggedIn) return _showLoginDialog();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTicketScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      await dbService.insertTicket(result);
      _loadTickets();
    }
  }

  Future<void> _editTicket(int index) async {
    if (!isLoggedIn) return _showLoginDialog();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTicketScreen(ticket: tickets[index])),
    );
    if (result != null && result is Map<String, dynamic>) {
      await dbService.updateTicketStatus(index, result['estado']);
      _loadTickets();
    }
  }

  Future<void> _changeTicketStatus(int index) async {
    if (!isLoggedIn) return _showLoginDialog();
    final estados = ['En Proceso', 'Pendiente', 'Entregado'];
    final currentIndex = estados.indexOf(tickets[index]['estado']);
    final newIndex = (currentIndex + 1) % estados.length;

    setState(() {
      tickets[index]['estado'] = estados[newIndex];
    });
    await dbService.updateTicketStatus(index, estados[newIndex]);

    if (tickets[index]['estado'] == 'Pendiente') {
      await _sendWhatsAppMessage(index);
    }

    if (tickets[index]['estado'] == 'Entregado') {
      await Future.delayed(const Duration(seconds: 5), () async {
        await dbService.deleteTicket(index);
        if (mounted) {
          setState(() {
            tickets.removeAt(index);
          });
        }
      });
    }

    // Mostrar botón de revertir por 5 segundos
    _showRevertOption(index, estados[currentIndex]);
  }

  void _showRevertOption(int index, String previousState) {
    final snackBar = SnackBar(
      content: const Text('¿Revertir estado?'),
      action: SnackBarAction(
        label: 'Revertir',
        textColor: Colors.blue,
        onPressed: () {
          setState(() {
            tickets[index]['estado'] = previousState;
          });
          dbService.updateTicketStatus(index, previousState);
        },
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.grey[800],
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _deleteTicket(int index) async {
    if (!isLoggedIn) return _showLoginDialog();
    await dbService.deleteTicket(index);
    _loadTickets();
  }

  Future<void> _sendWhatsAppMessage(int index) async {
    if (!isLoggedIn) return;
    final ticket = tickets[index];
    final String phoneNumber = "549${ticket['celular']}";
    final int cost = ticket['cantidadBolsas'] * costPerBag;
    final String message =
        'Hola ${ticket['nombre']}, podés pasar a retirar la ropa. Costo: \$$cost. ¡Gracias por confiar en nosotros!';
    try {
      await apiService.sendMessage(phoneNumber, message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje enviado correctamente')),
        );
      }
    } catch (e) {
      print('Error enviando mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar mensaje')),
        );
      }
    }
  }

  void _goToPreferences() {
    if (!isLoggedIn) return _showLoginDialog();
    Navigator.pushNamed(context, '/preferences');
  }

  void _goToConsultTickets() {
    if (!isLoggedIn) return _showLoginDialog();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConsultTicketsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return Container();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LavApp',
          style: TextStyle(color: Colors.blue, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Preferencias'),
              onTap: _goToPreferences,
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Consultar Tickets'),
              onTap: _goToConsultTickets,
            ),
          ],
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
                final ticket = tickets[index];
                Color stateColor;
                switch (ticket['estado']) {
                  case 'En Proceso':
                    stateColor = Colors.red;
                    break;
                  case 'Pendiente':
                    stateColor = Colors.yellow;
                    break;
                  case 'Entregado':
                    stateColor = Colors.green;
                    break;
                  default:
                    stateColor = Colors.grey;
                }
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text("${ticket['nombre']} #${ticket['celular']}"),
                    subtitle: Text("Costo: \$${ticket['cantidadBolsas'] * costPerBag}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: stateColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket['estado'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editTicket(index);
                            } else if (value == 'delete') {
                              _deleteTicket(index);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _changeTicketStatus(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        onPressed: _addNewTicket,
        label: const Text("Crear Ticket", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
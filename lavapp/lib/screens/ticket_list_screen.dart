import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import 'new_ticket_screen.dart';
import 'consult_tickets_screen.dart';
import 'reports_screen.dart';
import 'cost_screen.dart';
import 'clients_screen.dart';
import 'preferences_screen.dart';
import 'edit_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  List<Map<String, dynamic>> tickets = [];
  final DatabaseService dbService = DatabaseService();
  final ApiService apiService = ApiService();
  int costPerBag = 500;
  bool isLoggedIn = false;
  String? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing TicketListScreen');
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      AppLogger.info('Checking session...');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUsername = prefs.getString('username');
      if (savedUsername != null) {
        AppLogger.info('Session found for user: $savedUsername');
        setState(() {
          isLoggedIn = true;
          currentUser = savedUsername;
          isLoading = false;
        });
        _loadPreferences();
      } else {
        AppLogger.info('No session found, showing login dialog');
        setState(() {
          isLoading = false;
        });
        _showLoginDialog();
      }
    } catch (e, stackTrace) {
      print('Error checking session: $e\n$stackTrace'); // Usamos print en lugar de AppLogger.error
      setState(() {
        isLoading = false;
      });
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    String username = '';
    String password = '';
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext dialogContext, StateSetter setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.person, color: Colors.blue[800]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[800]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      username = value;
                      setDialogState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue[800]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[800]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      password = value;
                      setDialogState(() {
                        errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (username.isEmpty || password.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Por favor, complete todos los campos.';
                        });
                        return;
                      }

                      try {
                        AppLogger.info('Attempting login for user: $username');
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(username)
                            .get();

                        if (userDoc.exists) {
                          final userData = userDoc.data();
                          if (userData == null) {
                            throw Exception('El documento del usuario existe pero los datos son null');
                          }
                          if (userData['password'] == password) {
                            AppLogger.info('Login successful for user: $username');
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setString('username', username);
                            setState(() {
                              isLoggedIn = true;
                              currentUser = username;
                            });
                            _loadPreferences();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } else {
                            setDialogState(() {
                              errorMessage = 'Contraseña incorrecta.';
                            });
                          }
                        } else {
                          AppLogger.info('User not found, creating new user: $username');
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(username)
                              .set(
                            {
                              'username': username,
                              'password': password,
                              'createdAt': FieldValue.serverTimestamp(),
                            },
                            SetOptions(merge: true),
                          );
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('username', username);
                          setState(() {
                            isLoggedIn = true;
                            currentUser = username;
                          });
                          _loadPreferences();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      } catch (e, stackTrace) {
                        print('Error during login: $e\n$stackTrace'); // Usamos print en lugar de AppLogger.error
                        setDialogState(() {
                          errorMessage = 'Error al iniciar sesión: $e';
                        });
                      }
                    },
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadPreferences() async {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot load preferences: User not logged in');
      return;
    }
    try {
      AppLogger.info('Loading preferences...');
      final doc = await FirebaseFirestore.instance
          .collection('preferences')
          .doc('settings')
          .get();
      if (mounted) {
        setState(() {
          costPerBag = doc.data()?['costPerBag'] ?? 500;
        });
        AppLogger.info('Preferences loaded: costPerBag = $costPerBag');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading preferences: $e', e, stackTrace);
    }
  }

  Future<void> _addNewTicket() async {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot add new ticket: User not logged in');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Navigating to NewTicketScreen to create a new ticket');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewTicketScreen()),
      );
      if (result != null && result is Map<String, dynamic> && mounted) {
        AppLogger.info('New ticket data received: $result');
        if ((result['cantidadBolsas'] as int? ?? 0) <= 0 &&
            (result['extras']?.isEmpty ?? true) &&
            (result['counterExtras']?.isEmpty ?? true)) {
          AppLogger.warning('Validation failed: Ticket must have bags or extras');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Debe seleccionar al menos cantidad de bolsas o extras.')),
            );
          }
          return;
        }
        result['usuario'] = currentUser;
        result['timestamp'] = DateTime.now().toIso8601String();
        final docId = await dbService.insertTicket(result);
        if (docId.isNotEmpty) {
          AppLogger.info('Ticket inserted successfully with docId: $docId');
          result['docId'] = docId;
        } else {
          AppLogger.error('Error: docId is null or empty after insert for ticket: $result');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al crear el ticket: ID no generado')),
            );
          }
        }
      } else {
        AppLogger.info('No ticket data returned from NewTicketScreen');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error adding new ticket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el ticket: $e')),
        );
      }
    }
  }

  Future<void> _editTicket(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot edit ticket: User not logged in or invalid index');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Editing ticket at index $index');
      final ticket = Map<String, dynamic>.from(tickets[index]);
      final docId = await _getDocIdFromIndex(index);
      if (docId.isNotEmpty && mounted) {
        AppLogger.info('Navigating to EditTicketScreen with ticket: $ticket');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditTicketScreen(ticket: ticket)),
        );
        if (result != null && result is Map<String, dynamic> && mounted) {
          AppLogger.info('Updating ticket with docId $docId: $result');
          await dbService.updateTicket(docId, result);
        } else {
          AppLogger.info('No updated ticket data returned from EditTicketScreen');
        }
      } else {
        AppLogger.error('Error: Could not obtain docId for ticket: $ticket');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al editar el ticket: No se pudo obtener el ID')),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error editing ticket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al editar el ticket: $e')),
        );
      }
    }
  }

  Future<void> _changeTicketStatus(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot change ticket status: User not logged in or invalid index');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Changing ticket status at index $index');
      final estados = ['En Proceso', 'Pendiente', 'Entregado'];
      final currentIndex = estados.indexOf(tickets[index]['estado']);
      final newIndex = (currentIndex + 1) % estados.length;
      final newStatus = estados[newIndex];

      setState(() {
        tickets[index]['estado'] = newStatus;
      });

      String? docId = tickets[index]['docId'] as String?;
      if (docId == null || docId.isEmpty) {
        docId = await _getDocIdFromIndex(index);
        if (docId.isNotEmpty) {
          tickets[index]['docId'] = docId;
        } else {
          AppLogger.error('Error: docId is null or empty for ticket: ${tickets[index]}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al cambiar el estado: No se pudo obtener el ID')),
            );
          }
          return;
        }
      }

      AppLogger.info('Updating ticket status in Firestore: docId=$docId, newStatus=$newStatus');
      await dbService.updateTicketStatus(docId, newStatus, isArchived: false);

      if (newStatus == 'Entregado' && index < tickets.length) {
        AppLogger.info('Archiving ticket with docId: $docId');
        await dbService.archiveTicket(docId);
        if (mounted) {
          setState(() {
            tickets.removeAt(index);
          });
          _showRevertOption(index, estados[currentIndex]);
        }
      }

      if (index < tickets.length && tickets[index]['estado'] == 'Pendiente' && mounted) {
        AppLogger.info('Sending WhatsApp message for ticket at index $index');
        await _sendWhatsAppMessage(index);
      } else if (mounted && newStatus != 'Entregado') {
        AppLogger.info('Showing revert option for status change');
        _showRevertOption(index, estados[currentIndex]);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error changing ticket status: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar el estado del ticket: $e')),
        );
      }
    }
  }

  Future<void> _deleteTicket(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot delete ticket: User not logged in or invalid index');
      _showLoginDialog();
      return;
    }
    try {
      AppLogger.info('Deleting ticket at index $index');
      String? docId = tickets[index]['docId'] as String?;
      if (docId == null || docId.isEmpty) {
        docId = await _getDocIdFromIndex(index);
      }
      if (docId.isNotEmpty) {
        AppLogger.info('Deleting ticket with docId: $docId');
        await dbService.deleteTicket(docId, isArchived: false);
      } else {
        AppLogger.error('Error: docId is null or empty for ticket at index $index');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el ticket: No se pudo obtener el ID')),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting ticket: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el ticket: $e')),
        );
      }
    }
  }

  Future<String> _getDocIdFromIndex(int index) async {
    try {
      AppLogger.info('Getting docId for ticket at index $index');
      final ticket = tickets[index];
      final collection = ticket['estado'] == 'Entregado' ? 'archivedTickets' : 'tickets';
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('nombre', isEqualTo: ticket['nombre'])
          .where('celular', isEqualTo: ticket['celular'])
          .where('cantidadBolsas', isEqualTo: ticket['cantidadBolsas'])
          .where('estado', isEqualTo: ticket['estado'])
          .where('usuario', isEqualTo: currentUser)
          .where('timestamp', isEqualTo: ticket['timestamp'])
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        AppLogger.info('Found docId: $docId');
        return docId;
      } else {
        AppLogger.warning('No docId found for ticket at index $index');
        return '';
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error getting docId: $e', e, stackTrace);
      return '';
    }
  }

  void _showRevertOption(int index, String previousState) {
    AppLogger.info('Showing revert option for index $index, previous state: $previousState');
    final snackBar = SnackBar(
      content: const Text('¿Revertir estado?'),
      action: SnackBarAction(
        label: 'Revertir',
        textColor: Colors.blue,
        onPressed: () async {
          if (mounted && index < tickets.length) {
            try {
              AppLogger.info('Reverting ticket state to $previousState');
              setState(() {
                tickets[index]['estado'] = previousState;
              });
              final docId = await _getDocIdFromIndex(index);
              if (docId.isNotEmpty) {
                AppLogger.info('Updating ticket status to $previousState with docId: $docId');
                await dbService.updateTicketStatus(docId, previousState, isArchived: false);
              } else {
                AppLogger.error('Error: Could not obtain docId for revert');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al revertir el estado: No se pudo obtener el ID')),
                  );
                }
              }
            } catch (e, stackTrace) {
              AppLogger.error('Error reverting ticket status: $e', e, stackTrace);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al revertir el estado: $e')),
                );
              }
            }
          }
        },
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.grey[800],
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    }
  }

  Future<void> _sendWhatsAppMessage(int index) async {
    if (!isLoggedIn || index >= tickets.length) {
      AppLogger.warning('Cannot send WhatsApp message: User not logged in or invalid index');
      return;
    }
    try {
      AppLogger.info('Sending WhatsApp message for ticket at index $index');
      final ticket = tickets[index];
      final String phoneNumber = ticket['celular'] ?? '';
      if (phoneNumber.isEmpty) {
        AppLogger.error('Error: Phone number is empty for ticket at index $index');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Número de teléfono no especificado')),
          );
        }
        return;
      }
      AppLogger.info('Sending message to: $phoneNumber');
      final int cost = ((ticket['cantidadBolsas'] as int) * costPerBag +
          ((ticket['extras'] ?? <String, int>{}).values.fold(0, (total, price) => total + (price as int)))).toInt();
      final String message =
          '¡Hola ${ticket['nombre']} 👋! Ya podés pasar a retirar tu ropa 🧼✨. Costo: \$$cost. Si deseas transferir, podés hacerlo al alias: matteo.peirano.mp. ¡Gracias por elegirnos! 😊🙌';
      AppLogger.info('Message content: $message');
      await apiService.sendMessage(phoneNumber, message);
      AppLogger.info('WhatsApp message sent successfully');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mensaje enviado correctamente')),
            );
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error sending WhatsApp message: $e', e, stackTrace);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al enviar mensaje: $e')),
            );
          }
        });
      }
    }
  }

  void _goToPreferences() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to Preferences: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to PreferencesScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreferencesScreen()),
    );
  }

  void _goToConsultTickets() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to ConsultTicketsScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to ConsultTicketsScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConsultTicketsScreen()),
    ).then((_) {
      if (mounted) {
        AppLogger.info('Returned from ConsultTicketsScreen');
      }
    });
  }

  void _goToReports() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to ReportsScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to ReportsScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _goToCost() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to CostScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to CostScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CostScreen()),
    );
  }

  void _goToClients() {
    if (!isLoggedIn) {
      AppLogger.warning('Cannot navigate to ClientsScreen: User not logged in');
      _showLoginDialog();
      return;
    }
    AppLogger.info('Navigating to ClientsScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      AppLogger.info('Building: Showing loading indicator');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!isLoggedIn) {
      AppLogger.info('Building: User not logged in, showing empty container');
      return Container();
    }

    AppLogger.info('Building: Rendering ticket list for user $currentUser');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LavApp',
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
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
              child: Text(
                'Menú',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title: const Text('Preferencias', style: TextStyle(color: Colors.black)),
              onTap: _goToPreferences,
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.black),
              title: const Text('Consultar Tickets', style: TextStyle(color: Colors.black)),
              onTap: _goToConsultTickets,
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.black),
              title: const Text('Reportes', style: TextStyle(color: Colors.black)),
              onTap: _goToReports,
            ),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.black),
              title: const Text('Costos', style: TextStyle(color: Colors.black)),
              onTap: _goToCost,
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.black),
              title: const Text('Clientes', style: TextStyle(color: Colors.black)),
              onTap: _goToClients,
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('usuario', isEqualTo: currentUser)
            .where('estado', whereIn: ['En Proceso', 'Pendiente'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            AppLogger.info('StreamBuilder: Loading tickets...');
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            AppLogger.error('StreamBuilder: Error loading tickets: ${snapshot.error}', snapshot.error, snapshot.stackTrace);
            return Center(
              child: Text(
                'Error al cargar tickets: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            AppLogger.info('StreamBuilder: No tickets available');
            return const Center(
              child: Text(
                'No hay tickets disponibles',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          AppLogger.info('StreamBuilder: Tickets loaded, count: ${snapshot.data!.docs.length}');
          tickets = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            return data;
          }).toList();

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              Color stateColor;
              switch (ticket['estado']) {
                case 'En Proceso':
                  stateColor = Colors.red;
                  break;
                case 'Pendiente':
                  stateColor = const Color.fromARGB(255, 210, 190, 7);
                  break;
                case 'Entregado':
                  stateColor = Colors.green;
                  break;
                default:
                  stateColor = Colors.grey;
              }
              int totalCost = (ticket['cantidadBolsas'] as int) * costPerBag;
              if (ticket['extras'] != null && ticket['extras'] is Map) {
                totalCost += (ticket['extras'] as Map).values.fold(0, (acc, p) => acc + (p as int));
              }
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text("${ticket['nombre'] ?? 'Sin nombre'} #${ticket['celular'] ?? 'Sin celular'}"),
                  subtitle: Text("Costo: \$$totalCost"),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        onPressed: _addNewTicket,
        label: const Text("Crear Ticket", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
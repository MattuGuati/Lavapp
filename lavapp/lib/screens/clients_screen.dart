import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final snapshot = await FirebaseFirestore.instance.collection('clients').get();
    setState(() {
      clients = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    });
  }

  void _addClient() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      final client = {
        'name': _nameController.text,
        'phone': _phoneController.text,
      };
      FirebaseFirestore.instance.collection('clients').add(client);
      _nameController.clear();
      _phoneController.clear();
      _loadClients();
    }
  }

  void _deleteClient(String id) {
    FirebaseFirestore.instance.collection('clients').doc(id).delete();
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                ElevatedButton(onPressed: _addClient, child: const Text('Agregar Cliente')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return ListTile(
                  title: Text(client['name']),
                  subtitle: Text('Tel: ${client['phone']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteClient(client['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class EditTicketScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const EditTicketScreen({super.key, required this.ticket});

  @override
  State<EditTicketScreen> createState() => _EditTicketScreenState();
}

class _EditTicketScreenState extends State<EditTicketScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bagsController;
  String _selectedState = 'En Proceso';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ticket['nombre']);
    _phoneController = TextEditingController(text: widget.ticket['celular']);
    _bagsController = TextEditingController(text: widget.ticket['cantidadBolsas'].toString());
    _selectedState = widget.ticket['estado'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bagsController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    Navigator.pop(context, {
      'nombre': _nameController.text,
      'celular': _phoneController.text,
      'cantidadBolsas': int.tryParse(_bagsController.text) ?? 1,
      'estado': _selectedState,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Ticket"),
        actions: [
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Celular"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bagsController,
              decoration: const InputDecoration(labelText: "Cantidad de bolsas"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            const Text("Estado", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedState,
              isExpanded: true,
              items: ['En Proceso', 'Pendiente', 'Entregado']
                  .map((estado) => DropdownMenuItem(value: estado, child: Text(estado)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedState = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
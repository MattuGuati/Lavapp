import 'package:flutter/material.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key}); // Cambiamos `Key? key` a `super.key`

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  String _estado = 'Pendiente';
  int _cantidad = 1;

  void _saveTicket() {
    if (_nombreController.text.isNotEmpty && _celularController.text.isNotEmpty) {
      Navigator.pop(context, {
        'nombre': _nombreController.text,
        'celular': _celularController.text,
        'estado': _estado,
        'cantidad': _cantidad,
        'id': DateTime.now().millisecondsSinceEpoch.toString().substring(9), 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo Ticket',
          style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nombre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                fillColor: Colors.grey[300],
                filled: true,
                border: const UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Celular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _celularController,
              decoration: InputDecoration(
                fillColor: Colors.grey[300],
                filled: true,
                border: const UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            const Text('Estado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _estado,
              items: const [
                DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'En Proceso', child: Text('En Proceso')),
                DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
              ],
              onChanged: (value) {
                setState(() {
                  _estado = value!;
                });
              },
              underline: Container(height: 2, color: Colors.blue),
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            const Text('Cantidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      fillColor: Colors.grey[300],
                      filled: true,
                      border: const UnderlineInputBorder(),
                      hintText: '$_cantidad',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_cantidad > 1) _cantidad--;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _cantidad++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _saveTicket,
                child: const Text(
                  'Guardar Ticket',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

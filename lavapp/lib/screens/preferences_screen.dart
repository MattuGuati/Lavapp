import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final TextEditingController _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final box = await Hive.openBox('preferences');
    _costController.text = box.get('costPerBag', defaultValue: 500).toString();
  }

  Future<void> _savePreferences() async {
    final box = await Hive.openBox('preferences');
    final cost = int.tryParse(_costController.text) ?? 500;
    await box.put('costPerBag', cost);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferencias guardadas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _costController,
              decoration: const InputDecoration(labelText: 'Costo por bolsa'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePreferences,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

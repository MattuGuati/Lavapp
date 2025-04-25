import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPerBagController = TextEditingController();
  bool hasCounter = false;
  List<Map<String, dynamic>> attributes = [];

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing PreferencesScreen');
    _loadAttributes();
    _loadCostPerBag();
  }

  Future<void> _loadAttributes() async {
    try {
      AppLogger.info('Loading attributes from Firestore');
      final snapshot = await FirebaseFirestore.instance.collection('attributes').get();
      if (mounted) {
        setState(() {
          attributes = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
          AppLogger.info('Loaded ${attributes.length} attributes');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading attributes: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar atributos: $e')),
        );
      }
    }
  }

  Future<void> _loadCostPerBag() async {
    try {
      AppLogger.info('Loading cost per bag from Firestore');
      final doc = await FirebaseFirestore.instance.collection('preferences').doc('settings').get();
      if (mounted && doc.exists) {
        setState(() {
          _costPerBagController.text = (doc.data()?['costPerBag'] ?? 500).toString();
          AppLogger.info('Cost per bag loaded: ${_costPerBagController.text}');
        });
      } else {
        AppLogger.info('No cost per bag settings found, using default: 500');
        if (mounted) {
          setState(() {
            _costPerBagController.text = '500';
          });
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading cost per bag: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar costo por bolsa: $e')),
        );
      }
    }
  }

  void _addAttribute() {
    try {
      AppLogger.info('Adding new attribute');
      if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
        AppLogger.warning('Validation failed: Name or price is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complete todos los campos.')),
          );
        }
        return;
      }
      final price = int.tryParse(_priceController.text);
      if (price == null) {
        AppLogger.warning('Validation failed: Price is not a valid number');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El precio debe ser un número válido.')),
          );
        }
        return;
      }
      final attribute = {
        'name': _nameController.text,
        'price': price,
        'hasCounter': hasCounter,
      };
      AppLogger.info('Adding attribute to Firestore: $attribute');
      FirebaseFirestore.instance.collection('attributes').add(attribute).then((_) {
        AppLogger.info('Attribute added successfully');
        _nameController.clear();
        _priceController.clear();
        if (mounted) {
          setState(() => hasCounter = false);
          _loadAttributes();
        }
      }).catchError((e, stackTrace) {
        AppLogger.error('Error adding attribute: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar atributo: $e')),
          );
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error in _addAttribute: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar atributo: $e')),
        );
      }
    }
  }

  void _deleteAttribute(String id) {
    try {
      AppLogger.info('Deleting attribute with id: $id');
      FirebaseFirestore.instance.collection('attributes').doc(id).delete().then((_) {
        AppLogger.info('Attribute deleted successfully');
        if (mounted) {
          _loadAttributes();
        }
      }).catchError((e, stackTrace) {
        AppLogger.error('Error deleting attribute: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar atributo: $e')),
          );
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error in _deleteAttribute: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar atributo: $e')),
        );
      }
    }
  }

  void _saveCostPerBag() {
    try {
      AppLogger.info('Saving cost per bag');
      final cost = int.tryParse(_costPerBagController.text);
      if (cost == null) {
        AppLogger.warning('Validation failed: Cost per bag is not a valid number');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El costo debe ser un número válido.')),
          );
        }
        return;
      }
      AppLogger.info('Saving cost per bag to Firestore: $cost');
      FirebaseFirestore.instance.collection('preferences').doc('settings').set(
        {'costPerBag': cost},
        SetOptions(merge: true),
      ).then((_) {
        AppLogger.info('Cost per bag saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferencias guardadas')),
          );
        }
      }).catchError((e, stackTrace) {
        AppLogger.error('Error saving cost per bag: $e', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error('Error in _saveCostPerBag: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar costo por bolsa: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building PreferencesScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kToolbarHeight - 32.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración de Costos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Divider(thickness: 2, color: Colors.grey),
                const SizedBox(height: 16),
                TextField(
                  controller: _costPerBagController,
                  decoration: InputDecoration(
                    labelText: 'Costo por Bolsa',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveCostPerBag,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Guardar Costo por Bolsa'),
                  ),
                ),
                const Divider(thickness: 2, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Agregar Nuevo Atributo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Atributo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Precio',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Contador'),
                  value: hasCounter,
                  onChanged: (value) {
                    if (mounted) {
                      AppLogger.info('Toggling hasCounter: $hasCounter -> $value');
                      setState(() => hasCounter = value ?? false);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _addAttribute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Agregar Atributo'),
                  ),
                ),
                const Divider(thickness: 2, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Atributos Existentes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attributes.length,
                    itemBuilder: (context, index) {
                      final attribute = attributes[index];
                      return ListTile(
                        title: Text(attribute['name'] ?? 'Sin nombre'),
                        subtitle: Text('\$${attribute['price'] ?? 0}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (attribute['hasCounter'] == true)
                              const Text('Contador'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAttribute(attribute['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    AppLogger.info('Disposing PreferencesScreen');
    _nameController.dispose();
    _priceController.dispose();
    _costPerBagController.dispose();
    super.dispose();
  }
}
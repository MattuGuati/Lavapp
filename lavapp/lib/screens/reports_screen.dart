import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService dbService = DatabaseService();
  List<Map<String, dynamic>> tickets = [];
  List<Map<String, dynamic>> costs = [];
  int enProceso = 0;
  int pendiente = 0;
  int entregado = 0;
  int dailyProfit = 0;
  int monthlyProfit = 0;
  int yearlyProfit = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Initializing ReportsScreen');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      AppLogger.info('Loading data for reports');
      final ticketSnapshot = await dbService.getAllTickets();
      final archivedSnapshot = await dbService.getAllArchivedTickets();
      final costSnapshot = await FirebaseFirestore.instance.collection('costs').get();
      if (mounted) {
        setState(() {
          tickets = [...ticketSnapshot, ...archivedSnapshot];
          costs = costSnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
          enProceso = tickets.where((t) => t['estado'] == 'En Proceso').length;
          pendiente = tickets.where((t) => t['estado'] == 'Pendiente').length;
          entregado = tickets.where((t) => t['estado'] == 'Entregado').length;
          final now = DateTime.now();
          dailyProfit = _calculateProfit(now, const Duration(days: 1));
          monthlyProfit = _calculateProfit(now, const Duration(days: 30));
          yearlyProfit = _calculateProfit(now, const Duration(days: 365));
          AppLogger.info('Data loaded: enProceso=$enProceso, pendiente=$pendiente, entregado=$entregado');
          AppLogger.info('Profits: daily=$dailyProfit, monthly=$monthlyProfit, yearly=$yearlyProfit');
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading reports: $e', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reportes: $e')),
        );
      }
    }
  }

  int _calculateProfit(DateTime now, Duration period) {
    try {
      AppLogger.info('Calculating profit for period: $period');
      final start = now.subtract(period);
      int ticketRevenue = 0;
      for (final t in tickets) {
        final timestamp = t['timestamp'] != null ? DateTime.tryParse(t['timestamp'] as String) : null;
        if (timestamp != null && timestamp.isAfter(start) && t['estado'] == 'Entregado') {
          final bags = (t['cantidadBolsas'] as int?) ?? 0;
          int extraCost = 0;
          if (t['extras'] != null && t['extras'] is Map) {
            extraCost = (t['extras'] as Map).values.fold(0, (acc, p) {
              return acc + (p is num ? p.toInt() : (p as int));
            });
          }
          ticketRevenue += (bags * 500) + extraCost;
        }
      }
      int costTotal = 0;
      for (final c in costs) {
        final timestamp = c['timestamp'] != null ? DateTime.tryParse(c['timestamp'] as String) : null;
        if (timestamp != null && timestamp.isAfter(start)) {
          costTotal += (c['price'] is num ? (c['price'] as num).toInt() : (c['price'] as int));
        }
      }
      final profit = ticketRevenue - costTotal;
      AppLogger.info('Calculated profit: $profit (revenue=$ticketRevenue, costs=$costTotal)');
      return profit;
    } catch (e, stackTrace) {
      AppLogger.error('Error calculating profit: $e', e, stackTrace);
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('Building ReportsScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Distribución de Tickets por Estado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.red,
                      value: enProceso.toDouble(),
                      title: 'En Proceso ($enProceso)',
                      radius: 100,
                    ),
                    PieChartSectionData(
                      color: Colors.yellow,
                      value: pendiente.toDouble(),
                      title: 'Pendiente ($pendiente)',
                      radius: 100,
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: entregado.toDouble(),
                      title: 'Entregado ($entregado)',
                      radius: 100,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ganancia Diaria: $dailyProfit', style: const TextStyle(fontSize: 18)),
            Text('Ganancia Mensual: $monthlyProfit', style: const TextStyle(fontSize: 18)),
            Text('Ganancia Anual: $yearlyProfit', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
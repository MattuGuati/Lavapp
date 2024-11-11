import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/ticket.dart';

class ApiService {
  final String baseUrl = 'http://localhost:3000'; // URL de tu API

  Future<List<Ticket>> fetchTickets() async {
    final response = await http.get(Uri.parse('$baseUrl/tickets'));
    if (response.statusCode == 200) {
      List<dynamic> ticketsJson = json.decode(response.body);
      return ticketsJson.map((json) => Ticket.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tickets');
    }
  }

  Future<void> createTicket(Ticket ticket) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tickets'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(ticket.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create ticket');
    }
  }

  Future<void> updateTicket(int id, Ticket ticket) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tickets/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(ticket.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update ticket');
    }
  }

  Future<void> deleteTicket(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tickets/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete ticket');
    }
  }
}

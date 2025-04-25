import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class ApiService {
  final String baseUrl = 'http://181.104.129.36:3008';

  Future<void> sendMessage(String phoneNumber, String message) async {
    String formattedNumber = phoneNumber;
    if (!formattedNumber.startsWith("549")) {
      formattedNumber = "549$formattedNumber";
    }

    developer.log("Base URL configurada: $baseUrl"); // Depuración
    developer.log("Intentando enviar mensaje a: $baseUrl/v1/messages"); // Depuración

    final response = await http.post(
      Uri.parse('$baseUrl/v1/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'number': "$formattedNumber@s.whatsapp.net", 'message': message}),
    );

    if (response.statusCode == 200) {
      developer.log("✅ Mensaje enviado correctamente a $formattedNumber");
    } else {
      developer.log("❌ Error al enviar mensaje: ${response.body}");
      throw Exception('Error al enviar mensaje: ${response.body}');
    }
  }
}
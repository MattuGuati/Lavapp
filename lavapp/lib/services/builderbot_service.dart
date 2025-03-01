import 'package:http/http.dart' as http;
import 'dart:convert';

class BuilderBotService {
  final String baseUrl = "http://localhost:3008"; // Asegúrate de que el bot esté corriendo en este puerto

  Future<void> sendMessage(String phoneNumber, String message) async {
    String formattedNumber = phoneNumber;

    // Si el número no tiene el código de país, lo agregamos automáticamente
    if (!formattedNumber.startsWith("549")) {
      formattedNumber = "549$formattedNumber";
    }

    final response = await http.post(
      Uri.parse('$baseUrl/v1/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'number': "$formattedNumber@s.whatsapp.net", 'message': message}),
    );

    if (response.statusCode == 200) {
      print("✅ Mensaje enviado correctamente a $formattedNumber");
    } else {
      print("❌ Error al enviar mensaje: ${response.body}");
    }
  }
}

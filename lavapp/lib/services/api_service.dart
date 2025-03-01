import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
    final String baseUrl = 'http://localhost:3008/v1';

    Future<void> sendMessage(String phoneNumber, String message) async {
        final response = await http.post(
            Uri.parse('$baseUrl/messages'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
                'number': "$phoneNumber@s.whatsapp.net",
                'message': message,
            }),
        );

        if (response.statusCode != 200) {
            print('Error: ${response.statusCode} - ${response.body}');
            if (response.body.contains('qr code')) {
                throw Exception('El bot no está autenticado. Escanea el QR code en el backend.');
            }
            throw Exception('Error al enviar el mensaje: ${response.body}');
        } else {
            print('Mensaje enviado: ${response.body}');
        }
    }
}
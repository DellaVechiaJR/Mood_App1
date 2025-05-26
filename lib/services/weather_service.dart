import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Substitua pela sua chave
  static const String _apiKey = 'af1e8995acee3be7aeb7cc9e4fa67af2';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  /// Retorna a temperatura em °C para a latitude/longitude dadas.
  static Future<double> fetchTemperature({
    required double lat,
    required double lon,
  }) async {
    final url = Uri.parse(
      '$_baseUrl?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Erro ao buscar temperatura: ${resp.statusCode}');
    }
    final data = jsonDecode(resp.body);
    return (data['main']['temp'] as num).toDouble();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class RadioApiService {
  static const String apiUrl = 'https://r-a-d.io/api';

  Future<Map<String, dynamic>> getCurrentTrack() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final np = data['main']['np'];
      final parts = np.split(' - ');
      final artist = parts.isNotEmpty ? parts[0] : '';
      final title = parts.length > 1 ? parts[1] : '';
      return {
        'artist': artist,
        'title': title,
      };
    } else {
      throw Exception('Failed to load track info');
    }
  }
}
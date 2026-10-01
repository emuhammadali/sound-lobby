import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';

class MusicService {
  static const String _baseUrl = 'http://bardi.fsc-clan.eu';

  Future<List<SongModel>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {'query': query.trim()},
    );

    final response = await http.get(uri).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Search timed out. Try again.'),
        );

    if (response.statusCode != 200) {
      throw Exception('Search failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      return data
          .map((item) => SongModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    // fallback safety (in case backend returns single object)
    if (data is Map<String, dynamic>) {
      return [SongModel.fromJson(data)];
    }

    return [];
  }

  Future<SongModel> getStream(
    String videoId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/stream/$videoId',
    );

    final response = await http.get(uri).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(
            'Song loading timed out.',
          ),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load song',
      );
    }

    final data = jsonDecode(response.body);

    return SongModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
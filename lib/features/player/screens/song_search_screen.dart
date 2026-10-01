import 'package:flutter/material.dart';
import '../../../models/song_model.dart';
import '../../../services/music_service.dart';

class SongSearchScreen extends StatefulWidget {
  const SongSearchScreen({super.key});

  @override
  State<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends State<SongSearchScreen> {
  final _searchController = TextEditingController();
  final _musicService = MusicService();
  List<SongModel> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  Future<void> _search() async {
    if (_loading) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final results = await _musicService.search(query);
      if (mounted) setState(() => _results = results);
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search Music',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search for a song...',
                      hintStyle: const TextStyle(color: Color(0xFF5A5A80)),
                      filled: true,
                      fillColor: const Color(0xFF222240),
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF9E9EC8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6C63FF), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: (_loading) ? null : _search,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                      ),
                    ),
                  )
                : !_searched
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.music_note,
                              color: Color(0xFF6C63FF),
                              size: 56,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Search for a song to play',
                              style: TextStyle(
                                color: Color(0xFF9E9EC8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _loading
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF6C63FF),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Searching songs...',
                                  style: TextStyle(
                                    color: Color(0xFF9E9EC8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? const Center(
                                child: Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: Color(0xFF9E9EC8),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemBuilder: (context, i) {
                                  final song = _results[i];

                                  return _SongTile(
                                    song: song,
                                    onTap: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      try {
                                        final playableSong = await _musicService
                                            .getStream(song.id);

                                        if (!context.mounted) return;

                                        Navigator.of(context)
                                            .pop(); // close dialog

                                        Navigator.of(context).pop(playableSong);
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        Navigator.of(context)
                                            .pop(); // close dialog

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceAll(
                                                  'Exception: ', ''),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;

  const _SongTile({required this.song, required this.onTap});

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final duration = Duration(milliseconds: ms);
    final m = duration.inMinutes;
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222240)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbnail != null
                  ? Image.network(
                      song.thumbnail!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style:
                        const TextStyle(color: Color(0xFF9E9EC8), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (song.durationMs != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatDuration(song.durationMs),
                style: const TextStyle(color: Color(0xFF9E9EC8), fontSize: 12),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline,
                color: Color(0xFF6C63FF), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF222240),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Color(0xFF6C63FF), size: 24),
    );
  }
}

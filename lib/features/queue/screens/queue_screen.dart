import 'package:flutter/material.dart';
import '../../../models/queued_song_model.dart';
import '../../../services/queue_service.dart';

class QueueScreen extends StatelessWidget {
  final String lobbyId;
  final bool isDJ;

  const QueueScreen({
    super.key,
    required this.lobbyId,
    required this.isDJ,
  });

  String _fmt(int? ms) {
    if (ms == null) return '';
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final queueService = QueueService();

    return Container(
      color: const Color(0xFF0F0F1A),
      child: StreamBuilder<List<QueuedSongModel>>(
        stream: queueService.queueStream(lobbyId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          final queue = snap.data ?? [];

          if (queue.isEmpty) return _EmptyState(isDJ: isDJ);

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.queue_music,
                        color: Color(0xFF6C63FF), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Queue • ${queue.length} song${queue.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final item = queue[index];
                    final isNext = index == 0;

                    return _QueueTile(
                      item: item,
                      isNext: isNext,
                      isDJ: isDJ,
                      duration: _fmt(item.durationMs),
                      onRemove: isDJ
                          ? () => queueService.removeFromQueue(
                                lobbyId: lobbyId,
                                queueItemId: item.id,
                              )
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Queue tile

class _QueueTile extends StatelessWidget {
  final QueuedSongModel item;
  final bool isNext;
  final bool isDJ;
  final String duration;
  final VoidCallback? onRemove;

  const _QueueTile({
    required this.item,
    required this.isNext,
    required this.isDJ,
    required this.duration,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "UP NEXT" label
          if (isNext) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow,
                      color: Color(0xFF6C63FF), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Song tile
          Container(
            decoration: BoxDecoration(
              color: isNext
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.05)
                  : const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNext
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                    : const Color(0xFF222240),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.thumbnail != null
                    ? Image.network(
                        item.thumbnail!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  color: isNext ? const Color(0xFF6C63FF) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.artist,
                    style: const TextStyle(
                        color: Color(0xFF9E9EC8), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 10, color: Color(0xFF5A5A80)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Added by ${item.addedByName}',
                          style: const TextStyle(
                              color: Color(0xFF5A5A80), fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (duration.isNotEmpty)
                    Text(
                      duration,
                      style: const TextStyle(
                          color: Color(0xFF9E9EC8), fontSize: 12),
                    ),
                  if (isDJ && onRemove != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF222240),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note,
            color: Color(0xFF6C63FF), size: 24),
      );
}

// Empty state

class _EmptyState extends StatelessWidget {
  final bool isDJ;
  const _EmptyState({required this.isDJ});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.queue_music,
                  color: Color(0xFF6C63FF), size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              'Queue is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isDJ
                  ? 'Add a song from the Player tab to start the queue.'
                  : 'Use /request <song> in chat\nto suggest songs.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF9E9EC8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
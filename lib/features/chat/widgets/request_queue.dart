import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/music_request_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/music_service.dart';
import '../../../services/playback_service.dart';
import '../../../services/queue_service.dart';

class RequestQueue extends StatelessWidget {
  final String lobbyId;
  final bool isDJ;

  const RequestQueue({
    super.key,
    required this.lobbyId,
    required this.isDJ,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDJ) return const SizedBox.shrink();

    final chatService = ChatService();

    return StreamBuilder<List<MusicRequestModel>>(
      stream: chatService.pendingRequestsStream(lobbyId),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Icon(Icons.queue_music, color: Color(0xFF6C63FF), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Music Requests',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ...requests.map((req) => _RequestTile(
                    request: req,
                    lobbyId: lobbyId,
                    chatService: chatService,
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatefulWidget {
  final MusicRequestModel request;
  final String lobbyId;
  final ChatService chatService;

  const _RequestTile({
    required this.request,
    required this.lobbyId,
    required this.chatService,
  });

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);

    try {
      final results = await MusicService().search(
        widget.request.songQuery,
      );

      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No results for "${widget.request.songQuery}"',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      int? pickedIndex;

      if (results.length == 1) {
        pickedIndex = 0;
      } else {
        pickedIndex = await showModalBottomSheet<int>(
          context: context,
          backgroundColor: const Color(0xFF1A1A2E),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pick a result to play',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...results.take(5).toList().asMap().entries.map(
                    (e) => ListTile(
                      leading: const Icon(
                        Icons.music_note,
                        color: Color(0xFF6C63FF),
                      ),
                      title: Text(
                        e.value.title,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        e.value.artist,
                        style: const TextStyle(
                          color: Color(0xFF9E9EC8),
                        ),
                      ),
                      onTap: () => Navigator.pop(context, e.key),
                    ),
                  ),
            ],
          ),
        );
      }

      if (pickedIndex == null || !mounted) return;

      final selected = results[pickedIndex];

      final playableSong = await MusicService().getStream(
        selected.id,
      );

      if (!mounted) return;

      // Check if a song is currently playing
      final lobbyDoc = await FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.lobbyId)
          .get();

      final currentSongUrl = lobbyDoc.data()?['currentSongUrl'] as String?;
      final hasSongPlaying =
          currentSongUrl != null && currentSongUrl.isNotEmpty;

      if (hasSongPlaying) {
        // Song is playing → add to queue
        await QueueService().addToQueue(
          lobbyId: widget.lobbyId,
          song: playableSong,
          addedByUid: widget.request.uid,
          addedByName: widget.request.requesterName,
        );
      } else {
        // No song playing → play immediately
        await PlaybackService().playSong(
          lobbyId: widget.lobbyId,
          song: playableSong,
        );
      }

      await widget.chatService.updateRequestStatus(
        lobbyId: widget.lobbyId,
        requestId: widget.request.id,
        status: 'approved',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reject() async {
    await widget.chatService.updateRequestStatus(
      lobbyId: widget.lobbyId,
      requestId: widget.request.id,
      status: 'rejected',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF222240))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.songQuery,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'by ${widget.request.requesterName}',
                  style:
                      const TextStyle(color: Color(0xFF9E9EC8), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF), strokeWidth: 2),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF2ECC71), size: 22),
              onPressed: _approve,
              tooltip: 'Play this',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.cancel_outlined,
                  color: Colors.redAccent, size: 22),
              onPressed: _reject,
              tooltip: 'Reject',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
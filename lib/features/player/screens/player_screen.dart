import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../models/lobby_model.dart';
import '../../../models/song_model.dart';
import '../../../services/audio_controller.dart';
import '../../../services/playback_service.dart';
import '../../../services/queue_service.dart';
import '../screens/song_search_screen.dart';

class PlayerScreen extends StatefulWidget {
  final LobbyModel lobby;
  final String currentUid;
  final String currentUserName;

  const PlayerScreen(
      {super.key,
      required this.lobby,
      required this.currentUid,
      required this.currentUserName});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioController _audio = AudioController.instance;
  final PlaybackService _playbackService = PlaybackService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _audio.sync(widget.lobby);
    });
  }

  @override
  void didUpdateWidget(PlayerScreen old) {
    super.didUpdateWidget(old);
    final p = old.lobby;
    final c = widget.lobby;
    if (p.currentSongUrl != c.currentSongUrl ||
        p.isPlaying != c.isPlaying ||
        p.playbackStartedAt != c.playbackStartedAt) {
      _audio.sync(c);
    }
  }

  bool get _isDJ => widget.lobby.isDJ(widget.currentUid);

  Future<void> _openSearch() async {
    final song = await Navigator.push<SongModel>(
      context,
      MaterialPageRoute(builder: (_) => const SongSearchScreen()),
    );
    if (song == null || !mounted) return;

    final lobby = widget.lobby;
    final hasSong = lobby.currentSongUrl?.isNotEmpty == true;

    if (hasSong) {
      // Song already playing — add to queue
      await QueueService().addToQueue(
        lobbyId: lobby.id,
        song: song,
        addedByUid: widget.currentUid,
        addedByName: widget.currentUserName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} added to queue', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF6C63FF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Nothing playing — play immediately
      await _playbackService.playSong(
        lobbyId: lobby.id,
        song: song,
      );
    }
  }

  Future<void> _onPlayPause() async {
    setState(() {}); // trigger icon rebuild
    await _audio.toggleLocalPause(widget.lobby);
    if (mounted) setState(() {});
  }

  Future<void> _onStop() async {
    _audio.localPaused = false;
    await _playbackService.stop(widget.lobby.id);
  }

  Future<void> _onSkipNext() async {
    final next = await QueueService().popNext(widget.lobby.id);
    if (next != null) {
      await _playbackService.playSong(
        lobbyId: widget.lobby.id,
        song: next.toSongModel(),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queue is empty'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onSkipPrev() async {
    // Restart current song from beginning
    await _playbackService.playSong(
      lobbyId: widget.lobby.id,
      song: SongModel(
        id: '',
        title: widget.lobby.currentSongTitle ?? '',
        artist: widget.lobby.currentSongArtist ?? '',
        audioUrl: widget.lobby.currentSongUrl ?? '',
        thumbnail: widget.lobby.currentSongThumbnail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lobby = widget.lobby;
    final hasSong = lobby.currentSongUrl?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      floatingActionButton: null,
      body: hasSong
          ? _PlayerBody(
              lobby: lobby,
              isDJ: _isDJ,
              audio: _audio,
              onPlayPause: _onPlayPause,
              onStop: _onStop,
              onSearch: _openSearch,
              onSkipNext: _isDJ ? _onSkipNext : null,
              onSkipPrev: _isDJ ? _onSkipPrev : null,
            )
          : _EmptyState(isDJ: _isDJ, onSearch: _openSearch),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  final LobbyModel lobby;
  final bool isDJ;
  final AudioController audio;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onSearch;
  final VoidCallback? onSkipNext;
  final VoidCallback? onSkipPrev;

  const _PlayerBody({
    required this.lobby,
    required this.isDJ,
    required this.audio,
    required this.onPlayPause,
    required this.onStop,
    required this.onSearch,
    required this.onSkipNext,
    required this.onSkipPrev,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbSize = screenWidth * 0.72;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            if (isDJ) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF6C63FF),
                    size: 18,
                  ),
                  label: const Text(
                    'Add Song',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6C63FF).withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Thumbnail
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: lobby.currentSongThumbnail != null
                    ? Image.network(
                        lobby.currentSongThumbnail!,
                        width: thumbSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _ThumbPlaceholder(size: thumbSize),
                      )
                    : _ThumbPlaceholder(size: thumbSize),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              lobby.currentSongTitle ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              lobby.currentSongArtist ?? '',
              style: const TextStyle(
                color: Color(0xFF9E9EC8),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 28),

            // Progress bar
            StreamBuilder<Duration?>(
              stream: audio.player.durationStream,
              builder: (_, dSnap) {
                final duration = dSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: audio.player.positionStream,
                  builder: (_, pSnap) {
                    final pos = pSnap.data ?? Duration.zero;
                    final progress = duration.inMilliseconds > 0
                        ? (pos.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14),
                            activeTrackColor: const Color(0xFF6C63FF),
                            inactiveTrackColor: const Color(0xFF222240),
                            thumbColor: const Color(0xFF6C63FF),
                            overlayColor:
                                const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (_) {}, // listeners can't seek
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos),
                                  style: const TextStyle(
                                      color: Color(0xFF9E9EC8), fontSize: 12)),
                              Text(
                                duration > Duration.zero
                                    ? _fmt(duration)
                                    : '--:--',
                                style: const TextStyle(
                                    color: Color(0xFF9E9EC8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Buffering label — shows for all users
            StreamBuilder<PlayerState>(
              stream: audio.player.playerStateStream,
              builder: (_, snap) {
                final isBuffering =
                    snap.data?.processingState == ProcessingState.loading ||
                        snap.data?.processingState == ProcessingState.buffering;
                if (!isBuffering) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Buffering...',
                    style: TextStyle(color: Color(0xFF9E9EC8), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Controls row
            // Previous | Play/Pause | Next
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Color(0xFF9E9EC8)),
                  onPressed: isDJ ? onSkipPrev : null,
                ),
                const SizedBox(width: 16),

                // Play / Pause
                StreamBuilder<PlayerState>(
                  stream: audio.player.playerStateStream,
                  builder: (_, snap) {
                    final state = snap.data;
                    final isBuffering =
                        state?.processingState == ProcessingState.loading ||
                            state?.processingState == ProcessingState.buffering;
                    final isPlaying = state?.playing ?? false;
                    final showPause = isPlaying && !audio.localPaused;

                    return GestureDetector(
                      onTap: (isDJ && !isBuffering) ? onPlayPause : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDJ
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          boxShadow: isDJ
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isBuffering
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Icon(
                                showPause
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 16),

                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Color(0xFF9E9EC8)),
                  onPressed: isDJ ? onSkipNext : null,
                ),
              ],
            ),

            if (isDJ) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded,
                    color: Colors.redAccent, size: 18),
                label: const Text(
                  'Stop Playback',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDJ;
  final VoidCallback onSearch;

  const _EmptyState({required this.isDJ, required this.onSearch});

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
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    width: 2),
              ),
              child: const Icon(Icons.music_off_rounded,
                  color: Color(0xFF6C63FF), size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nothing playing right now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isDJ
                  ? 'Pick a song to get the party started.'
                  : 'Waiting for the DJ to start the music.',
              style: const TextStyle(
                color: Color(0xFF9E9EC8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (isDJ) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.search, color: Colors.white, size: 18),
                label: const Text(
                  'Browse Songs',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  final double size;
  const _ThumbPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * (9 / 16), // 16:9
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: Color(0xFF6C63FF), size: 56),
    );
  }
}

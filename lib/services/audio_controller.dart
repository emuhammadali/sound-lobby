import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lobby_model.dart';
import '../services/playback_service.dart';
import '../services/queue_service.dart';

class AudioController {
  AudioController._();
  static final AudioController instance = AudioController._();

  final AudioPlayer player = AudioPlayer();
  final PlaybackService _playbackService = PlaybackService();
  final QueueService _queueService = QueueService();

  int _syncToken = 0;
  String? _loadedUrl;
  bool localPaused = false;

  StreamSubscription<PlayerState>? _playerStateSub;
  String? _attachedLobbyId;
  bool _isAdmin = false; // only one device should pop the queue
  bool _isHandlingCompletion = false;

  void attachLobby(String lobbyId, {required bool isAdmin}) {
    if (_attachedLobbyId == lobbyId) return; // already attached
    _attachedLobbyId = lobbyId;
    _isAdmin = isAdmin;

    _playerStateSub?.cancel();
    _playerStateSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          !_isHandlingCompletion) {
        _onSongCompleted(lobbyId);
      }
    });
  }

  Future<void> _onSongCompleted(String lobbyId) async {
    // Only the admin triggers the next song to avoid race conditions
    if (!_isAdmin || _isHandlingCompletion) return;
    _isHandlingCompletion = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final next = await _queueService.popNext(lobbyId);
      if (next != null) {
        await _playbackService.playSong(
          lobbyId: lobbyId,
          song: next.toSongModel(),
        );
      } else {
        await _playbackService.stop(lobbyId);
      }
    } finally {
      _isHandlingCompletion = false;
    }
  }

  Future<void> detach() async {
    _playerStateSub?.cancel();
    _playerStateSub = null;
    _attachedLobbyId = null;
    _isAdmin = false;
    localPaused = false;
    _loadedUrl = null;
    await player.stop();
  }

  Future<void> sync(LobbyModel lobby) async {
    if (localPaused) return;

    _syncToken++;
    final token = _syncToken;
    bool stale() => _syncToken != token;

    try {
      final url = lobby.currentSongUrl;

      if (url == null || url.isEmpty) {
        await player.stop();
        if (stale()) return;
        _loadedUrl = null;
        return;
      }

      if (_loadedUrl != url) {
        await player.stop();
        if (stale()) return;
        await player.setUrl(
          url,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            'Accept': 'audio/webm,audio/ogg,audio/*;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Range': 'bytes=0-',
            'Connection': 'keep-alive',
          },
        );
        if (stale()) return;
        _loadedUrl = url;

        if (lobby.isPlaying && lobby.playbackStartedAt != null) {
          final target = _playbackService.calculateSyncPosition(
            storedPositionMs: lobby.currentPositionMs,
            playbackStartedAt: lobby.playbackStartedAt!,
          );
          final max = player.duration?.inMilliseconds ?? 0;
          await player.seek(
              Duration(milliseconds: max > 0 ? target.clamp(0, max) : target));
          if (stale()) return;
        }
      }

      if (lobby.isPlaying && lobby.playbackStartedAt != null) {
        final target = _playbackService.calculateSyncPosition(
          storedPositionMs: lobby.currentPositionMs,
          playbackStartedAt: lobby.playbackStartedAt!,
        );
        final max = player.duration?.inMilliseconds ?? 0;
        final seekMs = max > 0 ? target.clamp(0, max) : target;
        final drift = (player.position.inMilliseconds - seekMs).abs();

        if (drift > 1000) {
          await player.seek(Duration(milliseconds: seekMs));
          if (stale()) return;
        }
        if (!player.playing) await player.play();
      } else {
        if (player.playing) {
          await player.pause();
          if (stale()) return;
        }
        final max = player.duration?.inMilliseconds ?? 0;
        final seekMs = max > 0
            ? lobby.currentPositionMs.clamp(0, max)
            : lobby.currentPositionMs;
        final drift = (player.position.inMilliseconds - seekMs).abs();
        if (drift > 1000) {
          await player.seek(Duration(milliseconds: seekMs));
        }
      }
    } catch (e) {
      debugPrint('AudioController.sync error: $e');
    }
  }

  Future<void> toggleLocalPause(LobbyModel lobby) async {
    if (localPaused) {
      localPaused = false;
      await sync(lobby);
    } else {
      localPaused = true;
      await player.pause();
    }
  }

  String fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

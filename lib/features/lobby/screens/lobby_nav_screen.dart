import 'package:flutter/material.dart';
import 'package:sound_lobby/services/chat_service.dart';
import 'package:sound_lobby/services/queue_service.dart';
import 'package:sound_lobby/shared/widgets/nav_badge.dart';
import '../../../models/lobby_model.dart';
import '../../../models/user_model.dart';
import '../../../services/lobby_service.dart';
import '../../player/screens/player_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../queue/screens/queue_screen.dart';
import '../../members/screens/members_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../services/audio_controller.dart';
import 'dart:async';

class LobbyNavScreen extends StatefulWidget {
  final String lobbyId;
  final UserModel user;

  const LobbyNavScreen({
    super.key,
    required this.lobbyId,
    required this.user,
  });

  @override
  State<LobbyNavScreen> createState() => _LobbyNavScreenState();
}

class _LobbyNavScreenState extends State<LobbyNavScreen> {
  final LobbyService _lobbyService = LobbyService();

  int _selectedIndex = 2;
  LobbyModel? _lastLobby;
  bool _isDeafened = false;

  // Badge fields
  int _newChatCount = 0;
  int _newQueueCount = 0;
  int _newMemberCount = 0;
  int _lastSeenChatCount = 0;
  int _lastSeenQueueCount = 0;
  int _lastSeenMemberCount = 0;

  StreamSubscription? _chatSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _memberSub;

  static const List<String> _titles = [
    'Queue',
    'Chat',
    'Player',
    'Members',
    'Lobby Information',
  ];

  void _toggleDeafen() {
    setState(() => _isDeafened = !_isDeafened);
    final player = AudioController.instance.player;
    player.setVolume(_isDeafened ? 0.0 : 1.0);
  }

  Future<void> _confirmLeave(LobbyModel lobby) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Leave Lobby', style: TextStyle(color: Colors.white)),
        content: Text(
          lobby.isAdmin(widget.user.uid)
              ? 'You are the admin. Admin will be transferred to a random participant.'
              : 'Are you sure you want to leave?',
          style: const TextStyle(color: Color(0xFF9E9EC8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9EC8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Leave', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await AudioController.instance.detach();
    await _lobbyService.leaveLobby(
      lobbyId: widget.lobbyId,
      uid: widget.user.uid,
    );

    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void initState() {
    super.initState();
    _listenForBadges();
  }

  void _listenForBadges() {
    final chatService = ChatService();
    final queueService = QueueService();

    _chatSub = chatService.chatStream(widget.lobbyId).listen((messages) {
      final newCount = messages.length - _lastSeenChatCount;

      if (_selectedIndex != 1 && newCount > 0) {
        setState(() => _newChatCount += newCount);
      }
      if (_selectedIndex == 1) {
        setState(() => _newChatCount = 0);
      }
      _lastSeenChatCount = messages.length;
    });

    _queueSub = queueService.queueStream(widget.lobbyId).listen((queue) {
      final newCount = queue.length - _lastSeenQueueCount;

      if (_selectedIndex != 0 && queue.length > _lastSeenQueueCount) {
        setState(() => _newQueueCount += newCount);
      }
      if (_selectedIndex == 0) {
        setState(() => _newQueueCount = 0);
      }
      _lastSeenQueueCount = queue.length;
    });

    _memberSub =
        _lobbyService.participantsStream(widget.lobbyId).listen((members) {
      final newCount = members.length - _lastSeenMemberCount;

      if (_selectedIndex != 3 && members.length > _lastSeenMemberCount) {
        setState(() => _newMemberCount += newCount);
      }
      if (_selectedIndex == 3) {
        setState(() => _newMemberCount = 0);
      }
      _lastSeenMemberCount = members.length;
    });
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _queueSub?.cancel();
    _memberSub?.cancel();
    AudioController.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LobbyModel?>(
      stream: _lobbyService.lobbyStream(widget.lobbyId),
      builder: (context, snap) {
        final lobby = snap.data;

        // Still loading OR lobby deleted
        if (lobby == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
          );
        }

        AudioController.instance.attachLobby(
          widget.lobbyId,
          isAdmin: lobby.isAdmin(widget.user.uid),
        );

        // Sync audio on every lobby change
        if (lobby != _lastLobby) {
          _lastLobby = lobby;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AudioController.instance.sync(lobby);
          });
        }

        // Kicked from lobby
        if (!lobby.isParticipant(widget.user.uid)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are no longer in the lobby.'),
                backgroundColor: Colors.redAccent,
              ),
            );

            Navigator.of(context).popUntil((r) => r.isFirst);
          });

          return const SizedBox.shrink();
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave(lobby);
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A1A2E),
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: IconButton(
                tooltip: _isDeafened ? 'Undeafen' : 'Deafen',
                icon: Icon(
                  _isDeafened ? Icons.headset_off : Icons.headset,
                  color:
                      _isDeafened ? Colors.redAccent : const Color(0xFF9E9EC8),
                ),
                onPressed: _toggleDeafen,
              ),
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF9E9EC8)),
                  color: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF222240)),
                  ),
                  onSelected: (value) {
                    if (value == 'leave') {
                      _confirmLeave(lobby);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app,
                              color: Colors.redAccent, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Leave Lobby',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: _buildBody(lobby),
            bottomNavigationBar: _BottomNav(
              selectedIndex: _selectedIndex,
              onTap: (i) {
                setState(() {
                  _selectedIndex = i;
                  if (i == 0) _newQueueCount = 0;
                  if (i == 1) _newChatCount = 0;
                  if (i == 3) _newMemberCount = 0;
                });
              },
              newChatCount: _newChatCount,
              newQueueCount: _newQueueCount,
              newMemberCount: _newMemberCount,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(LobbyModel lobby) {
    switch (_selectedIndex) {
      case 0:
        return QueueScreen(
            lobbyId: widget.lobbyId, isDJ: lobby.isDJ(widget.user.uid));
      case 1:
        return ChatScreen(
          lobbyId: widget.lobbyId,
          user: widget.user,
          isDJ: lobby.isDJ(widget.user.uid),
        );
      case 2:
        return PlayerScreen(
          lobby: lobby,
          currentUid: widget.user.uid,
          currentUserName: widget.user.fullName,
        );
      case 3:
        return MembersScreen(
          lobby: lobby,
          currentUid: widget.user.uid,
          lobbyService: _lobbyService,
        );
      case 4:
        return SettingsScreen(
          lobby: lobby,
          user: widget.user,
          lobbyService: _lobbyService,
          onLeave: () async {
            await AudioController.instance.detach();
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int newChatCount;
  final int newQueueCount;
  final int newMemberCount;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.newChatCount,
    required this.newQueueCount,
    required this.newMemberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF222240), width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: const Color(0xFF9E9EC8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            label: 'Queue',
            icon: NavBadge(
              count: newQueueCount,
              icon: const Icon(Icons.queue_music_outlined),
            ),
            activeIcon: NavBadge(
              count: newQueueCount,
              icon: const Icon(Icons.queue_music),
            ),
          ),
          BottomNavigationBarItem(
            label: 'Chat',
            icon: NavBadge(
              count: newChatCount,
              icon: const Icon(Icons.chat_bubble_outline),
            ),
            activeIcon: NavBadge(
              count: newChatCount,
              icon: const Icon(Icons.chat_bubble),
            ),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline, size: 32),
            activeIcon: Icon(Icons.play_circle, size: 32),
            label: 'Player',
          ),
          BottomNavigationBarItem(
            label: 'Members',
            icon: NavBadge(
              count: newMemberCount,
              icon: const Icon(Icons.people_outline),
            ),
            activeIcon: NavBadge(
              count: newMemberCount,
              icon: const Icon(Icons.people),
            ),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}

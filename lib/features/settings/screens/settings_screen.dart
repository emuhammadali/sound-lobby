import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/lobby_model.dart';
import '../../../models/participant_model.dart';
import '../../../models/user_model.dart';
import '../../../services/lobby_service.dart';

class SettingsScreen extends StatefulWidget {
  final LobbyModel lobby;
  final UserModel user;
  final LobbyService lobbyService;
  final VoidCallback onLeave;

  const SettingsScreen({
    super.key,
    required this.lobby,
    required this.user,
    required this.lobbyService,
    required this.onLeave,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _leaving = false;

  Future<void> _copyToClipboard(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF6C63FF),
        ),
      );
    }
  }

  Future<void> _leaveLobby() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Leave Lobby', style: TextStyle(color: Colors.white)),
        content: Text(
          widget.lobby.isAdmin(widget.user.uid)
              ? 'You are the admin. Admin will be transferred to a random participant.'
              : 'Are you sure you want to leave this lobby?',
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
    setState(() => _leaving = true);

    try {
      await widget.lobbyService.leaveLobby(
        lobbyId: widget.lobby.id,
        uid: widget.user.uid,
      );
      widget.onLeave();
    } catch (e) {
      if (mounted) {
        setState(() => _leaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _getUserRole() {
    if (widget.lobby.isAdmin(widget.user.uid)) return 'admin';
    if (widget.lobby.isDJ(widget.user.uid)) return 'dj';
    return 'listener';
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin 👑';
      case 'dj':
        return 'DJ 🎧';
      default:
        return 'Listener 🎵';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.verified;
      case 'dj':
        return Icons.headphones;
      default:
        return Icons.audiotrack;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.redAccent;
      case 'dj':
        return Colors.amber;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ParticipantModel>>(
      stream: widget.lobbyService.participantsStream(widget.lobby.id),
      builder: (context, snap) {
        final participants = snap.data ?? [];

        final admin = participants.isEmpty
            ? null
            : participants.firstWhere(
                (p) => p.role == 'admin',
                orElse: () => participants.first,
              );

        final currentUserRole = _getUserRole();
        final isCurrentUserAdmin = widget.lobby.isAdmin(widget.user.uid);

        return Container(
          color: const Color(0xFF0F0F1A),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF040613),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6C63FF),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Image.asset(
                        'assets/images/soundlobby_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Lobby Name
              _buildInfoCard(
                title: 'Lobby Name',
                value: widget.lobby.name,
                icon: Icons.meeting_room,
                onTap: () =>
                    _copyToClipboard(widget.lobby.name, 'Lobby name copied!'),
              ),
              const SizedBox(height: 16),

              // Lobby Code
              _buildInfoCard(
                title: 'Lobby Code',
                value: widget.lobby.id,
                icon: Icons.code,
                onTap: () =>
                    _copyToClipboard(widget.lobby.id, 'Lobby code copied!'),
                showCopyButton: true,
              ),
              const SizedBox(height: 16),

              // Admin
              _buildInfoCard(
                title: 'Lobby Admin',
                value: admin?.fullName ?? '...',
                icon: Icons.verified,
                subtitle: isCurrentUserAdmin ? 'You are the admin' : null,
                valueColor: Colors.redAccent,
              ),
              const SizedBox(height: 16),

              // Total members
              _buildInfoCard(
                title: 'Total Members',
                value: '${widget.lobby.participantIds.length}',
                icon: Icons.people,
                subtitle: widget.lobby.participantIds.length == 1
                    ? 'person in lobby'
                    : 'people in lobby',
              ),
              const SizedBox(height: 16),

              // My role
              _buildInfoCard(
                title: 'Your Role',
                value: _getRoleLabel(currentUserRole),
                icon: _getRoleIcon(currentUserRole),
                valueColor: _getRoleColor(currentUserRole),
              ),
              const SizedBox(height: 24),

              Container(height: 1, color: const Color(0xFF222240)),
              const SizedBox(height: 24),

              // Leave Lobby button
              GestureDetector(
                onTap: _leaving ? null : _leaveLobby,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_leaving)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.redAccent,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(
                          Icons.exit_to_app,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        _leaving ? 'Leaving...' : 'Leave Lobby',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'SoundLobby v1.0.0',
                  style: TextStyle(color: Color(0xFF5A5A80), fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
    Color? valueColor,
    bool showCopyButton = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222240)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6C63FF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF9E9EC8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showCopyButton)
              const Icon(Icons.copy, color: Color(0xFF6C63FF), size: 20),
          ],
        ),
      ),
    );
  }
}
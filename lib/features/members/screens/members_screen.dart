import 'package:flutter/material.dart';
import '../../../models/lobby_model.dart';
import '../../../models/participant_model.dart';
import '../../../services/lobby_service.dart';

class MembersScreen extends StatelessWidget {
  final LobbyModel lobby;
  final String currentUid;
  final LobbyService lobbyService;

  const MembersScreen({
    super.key,
    required this.lobby,
    required this.currentUid,
    required this.lobbyService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ParticipantModel>>(
      stream: lobbyService.participantsStream(lobby.id),
      builder: (context, snap) {
        final participants = snap.data ?? [];

        if (participants.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: participants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = participants[i];
            final isMe = p.uid == currentUid;
            final isAdmin = lobby.isAdmin(currentUid);
            final canManage = isAdmin && !isMe && !p.isAdmin;

            return _MemberTile(
              participant: p,
              isMe: isMe,
              canManage: canManage,
              lobby: lobby,
              currentUid: currentUid,
              lobbyService: lobbyService,
            );
          },
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ParticipantModel participant;
  final bool isMe;
  final bool canManage;
  final LobbyModel lobby;
  final String currentUid;
  final LobbyService lobbyService;

  const _MemberTile({
    required this.participant,
    required this.isMe,
    required this.canManage,
    required this.lobby,
    required this.currentUid,
    required this.lobbyService,
  });

  Color get _roleColor {
    switch (participant.role) {
      case 'admin':
        return Colors.redAccent;
      case 'dj':
        return Colors.amber;
      default:
        return const Color(0xFF6C63FF);
    }
  }

  String get _roleLabel {
    switch (participant.role) {
      case 'admin':
        return 'Admin';
      case 'dj':
        return 'DJ';
      default:
        return 'Listener';
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              participant.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _roleLabel,
              style: TextStyle(color: _roleColor, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (!participant.isDJ)
              _OptionTile(
                icon: Icons.headphones,
                label: 'Assign DJ',
                color: Colors.amber,
                onTap: () async {
                  Navigator.pop(context);
                  await lobbyService.assignDJ(
                    lobbyId: lobby.id,
                    targetUid: participant.uid,
                  );
                },
              ),
            if (participant.isDJ && !participant.isAdmin)
              _OptionTile(
                icon: Icons.headset_off,
                label: 'Revoke DJ',
                color: Colors.orange,
                onTap: () async {
                  Navigator.pop(context);
                  await lobbyService.revokeDJ(
                    lobbyId: lobby.id,
                    targetUid: participant.uid,
                  );
                },
              ),
            _OptionTile(
              icon: Icons.swap_horiz,
              label: 'Transfer Admin',
              color: Colors.amber,
              onTap: () async {
                Navigator.pop(context);
                await lobbyService.transferAdmin(
                  lobbyId: lobby.id,
                  currentAdminId: currentUid,
                  newAdminId: participant.uid,
                );
              },
            ),
            _OptionTile(
              icon: Icons.person_remove,
              label: 'Kick ${participant.fullName}',
              color: Colors.redAccent,
              onTap: () async {
                Navigator.pop(context);
                await lobbyService.kickUser(
                  lobbyId: lobby.id,
                  targetUid: participant.uid,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roleColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _roleColor.withValues(alpha: 0.15),
            child: Text(
              participant.fullName[0].toUpperCase(),
              style: TextStyle(
                color: _roleColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  participant.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '(you)',
                    style: TextStyle(
                      color: Color(0xFF9E9EC8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _roleColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roleLabel,
              style: TextStyle(
                color: _roleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canManage) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showOptions(context),
              child: const Icon(
                Icons.more_vert,
                color: Color(0xFF9E9EC8),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
    );
  }
}
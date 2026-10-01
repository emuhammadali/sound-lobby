import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'lobby_nav_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String lobbyId;
  final UserModel user;

  const LobbyScreen({
    super.key,
    required this.lobbyId,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return LobbyNavScreen(
      lobbyId: lobbyId,
      user: user,
    );
  }
}
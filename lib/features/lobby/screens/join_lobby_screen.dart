import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/lobby_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import 'lobby_screen.dart';

class JoinLobbyScreen extends StatefulWidget {
  final UserModel user;
  const JoinLobbyScreen({super.key, required this.user});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _lobbyService = LobbyService();
  bool _loading = false;
  String? _error;

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lobby = await _lobbyService.joinLobby(
        code: _codeController.text.trim(),
        user: widget.user,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(lobbyId: lobby.id, user: widget.user),
        ),
      );
    } on Exception catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
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
          'Join Lobby',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF040613),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2ECC71),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.55),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.login,
                    color: Color(0xFF2ECC71),
                    size: 55,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              AppTextField(
                controller: _codeController,
                label: 'Enter room code',
                hint: 'e.g. AB3X9Z',
                validator: (v) => (v == null || v.trim().length != 6)
                    ? 'Enter a valid 6-character code'
                    : null,
              ),

              const SizedBox(height: 30),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 12),
              ],

              AppButton(
                label: 'Join Lobby',
                onPressed: _join,
                isLoading: _loading,
                color: const Color(0xFF2ECC71).withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

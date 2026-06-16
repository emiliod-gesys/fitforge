import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[];
  bool _loading = false;

  final _suggestions = [
    '¿Qué ejercicios me recomiendas para pecho hoy?',
    'Sugiere un peso para press banca basado en mi historial',
    'Crea una rutina de piernas de 45 minutos',
    '¿Cuándo debería descansar cada grupo muscular?',
  ];

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
    });
    _controller.clear();

    try {
      final profile = await ref.read(profileProvider.future);
      final workouts = await ref.read(workoutsProvider.future);
      final routines = await ref.read(routinesProvider.future);

      final response = await ref.read(aiCoachServiceProvider).getRecommendation(
            userMessage: text,
            recentWorkouts: workouts,
            routines: routines,
            profile: profile,
          );

      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: 'Error: $e', isUser: false, isError: true));
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach IA')),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Icon(Icons.auto_awesome, size: 64, color: Colors.purple),
                  const SizedBox(height: 16),
                  Text(
                    'Tu entrenador personal con IA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configura tu API key en Perfil para activar el coach.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  ..._suggestions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ActionChip(
                        label: Text(s),
                        onPressed: () => _send(s),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Pregunta al coach...'),
                      onSubmitted: _send,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  _ChatMessage({required this.text, required this.isUser, this.isError = false});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isError
              ? Colors.red.withValues(alpha: 0.2)
              : message.isUser
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message.text),
      ),
    );
  }
}

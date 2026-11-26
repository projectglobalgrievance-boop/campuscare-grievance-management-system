import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/chatbot.dart';
import '../services/voice.dart';
import '../theme/tokens.dart';

/// The assistant, as a small launcher pinned to the right edge that opens a
/// compact panel over whatever screen you are on — the way a support widget
/// behaves on a company website. It is deliberately not a tab and not a full
/// screen: asking a question should not cost you your place in the app.
///
/// Drop it into a [Stack] above the current screen.
class ChatAssistant extends StatefulWidget {
  const ChatAssistant({super.key, this.bottomInset = 0});

  /// Space to keep clear at the bottom, so the launcher never sits on top of
  /// a bottom navigation bar.
  final double bottomInset;

  @override
  State<ChatAssistant> createState() => _ChatAssistantState();
}

class _ChatAssistantState extends State<ChatAssistant> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: Space.md,
      bottom: widget.bottomInset + Space.md,
      child: _open
          ? _ChatPanel(onClose: () => setState(() => _open = false))
          : _Launcher(onTap: () => setState(() => _open = true)),
    );
  }
}

class _Launcher extends StatelessWidget {
  const _Launcher({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Open the CampusCare assistant',
      child: Material(
        color: scheme.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.forum_rounded, color: scheme.onPrimary, size: 26),
          ),
        ),
      ),
    )
        .animate()
        .scale(duration: Motion.normal, curve: Curves.easeOutBack)
        .fadeIn(duration: Motion.fast);
  }
}

class _Msg {
  _Msg(this.text, {required this.fromBot, this.unanswered = false});

  final String text;
  final bool fromBot;

  /// True when the bot fell back — used to offer suggestions again.
  final bool unanswered;
}

class _ChatPanel extends StatefulWidget {
  const _ChatPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<_ChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = VoiceService();

  ChatBot? _bot;
  final _messages = <_Msg>[];
  bool _listening = false;
  bool _speakReplies = true;
  String _partial = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final bot = await ChatBot.load();
    await _voice.init();
    if (!mounted) return;
    setState(() {
      _bot = bot;
      _messages.add(_Msg(
        'Hi! Ask me about Global Academy of Technology or about using '
        'CampusCare. Type, or hold the mic and speak.',
        fromBot: true,
      ));
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _voice.dispose();
    super.dispose();
  }

  void _send(String text) {
    final q = text.trim();
    final bot = _bot;
    if (q.isEmpty || bot == null) return;

    final answer = bot.ask(q);
    setState(() {
      _messages.add(_Msg(q, fromBot: false));
      _messages.add(_Msg(answer.text,
          fromBot: true, unanswered: !answer.matched));
      _input.clear();
      _partial = '';
    });
    _scrollToEnd();
    if (_speakReplies) _voice.speak(answer.text);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: Motion.fast, curve: Motion.curve);
      }
    });
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stopListening();
      setState(() => _listening = false);
      if (_partial.trim().isNotEmpty) _send(_partial);
      return;
    }
    if (!_voice.canListen) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_voice.unavailableReason ??
            'Speech recognition is not available on this phone.'),
      ));
      return;
    }
    await _voice.stopSpeaking();
    setState(() {
      _listening = true;
      _partial = '';
    });
    await _voice.listen(onText: (text, isFinal) {
      if (!mounted) return;
      setState(() => _partial = text);
      if (isFinal) {
        setState(() => _listening = false);
        if (text.trim().isNotEmpty) _send(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final width = math.min(360.0, media.size.width - Space.lg);
    final height = math.min(520.0, media.size.height * 0.68);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(Corners.lg),
      clipBehavior: Clip.antiAlias,
      color: scheme.surface,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _header(theme, scheme),
            Expanded(
              child: _bot == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(Space.md),
                      itemCount: _messages.length + (_showSuggestions ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _messages.length) return _suggestions(theme);
                        return _bubble(_messages[i], theme, scheme);
                      },
                    ),
            ),
            _composer(theme, scheme),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: Motion.fast)
        .scaleXY(begin: 0.92, duration: Motion.normal, curve: Curves.easeOutBack);
  }

  bool get _showSuggestions =>
      _bot != null &&
      (_messages.length <= 1 || (_messages.isNotEmpty && _messages.last.unanswered));

  Widget _header(ThemeData theme, ColorScheme scheme) => Container(
        color: scheme.primary,
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
        child: Row(
          children: [
            Icon(Icons.forum_rounded, color: scheme.onPrimary, size: 20),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text('Assistant',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: scheme.onPrimary)),
            ),
            IconButton(
              tooltip: _speakReplies ? 'Mute replies' : 'Speak replies',
              onPressed: () {
                if (_speakReplies) _voice.stopSpeaking();
                setState(() => _speakReplies = !_speakReplies);
              },
              icon: Icon(
                  _speakReplies
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: scheme.onPrimary,
                  size: 20),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              icon: Icon(Icons.close_rounded, color: scheme.onPrimary, size: 20),
            ),
          ],
        ),
      );

  Widget _bubble(_Msg m, ThemeData theme, ColorScheme scheme) {
    final isBot = m.fromBot;
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: Space.md, vertical: Space.sm + 2),
        constraints: const BoxConstraints(maxWidth: 268),
        decoration: BoxDecoration(
          color: isBot ? scheme.surfaceContainerHighest : scheme.primary,
          borderRadius: BorderRadius.circular(Corners.md).copyWith(
            bottomLeft: isBot ? const Radius.circular(4) : null,
            bottomRight: isBot ? null : const Radius.circular(4),
          ),
          border: isBot ? Border.all(color: scheme.outline) : null,
        ),
        child: Text(
          m.text,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: isBot ? scheme.onSurface : scheme.onPrimary),
        ),
      ),
    );
  }

  Widget _suggestions(ThemeData theme) {
    final items = _bot?.suggestions ?? const <String>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs, bottom: Space.sm),
      child: Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final s in items)
            ActionChip(
              label: Text(s, style: theme.textTheme.bodySmall),
              onPressed: () => _send(s),
            ),
        ],
      ),
    );
  }

  Widget _composer(ThemeData theme, ColorScheme scheme) => Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 3,
                onSubmitted: _send,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _listening
                      ? (_partial.isEmpty ? 'Listening…' : _partial)
                      : 'Ask about GAT or the app',
                  filled: true,
                  fillColor: scheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: Space.md, vertical: Space.sm + 2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Corners.pill),
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.xs),
            IconButton(
              tooltip: _listening ? 'Stop listening' : 'Speak your question',
              onPressed: _bot == null ? null : _toggleMic,
              icon: Icon(_listening ? Icons.stop_circle_rounded : Icons.mic_rounded),
              color: _listening ? scheme.error : scheme.primary,
            ),
            IconButton(
              tooltip: 'Send',
              onPressed: _bot == null ? null : () => _send(_input.text),
              icon: const Icon(Icons.send_rounded),
              color: scheme.primary,
            ),
          ],
        ),
      );
}

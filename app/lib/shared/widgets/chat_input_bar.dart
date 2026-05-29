import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';

/// Input bar untuk chat room — design-spec.md §8 ChatRoom + §11.1 Debounce.
///
/// - Background: surface-elevated, border radius 24
/// - Tombol kirim: lingkaran accent saat ada teks, abu-abu saat kosong
/// - Scale 0.95 saat ditekan (haptic-like, design-spec §10)
/// - Debounced via `isSending` flag dari caller
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  final Future<void> Function(String body) onSend;
  final bool isSending;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || widget.isSending) return;

    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() => _hasText = false);

    try {
      await widget.onSend(body);
    } catch (_) {
      // Caller sudah tampilkan snackbar. Restore teks supaya bisa retry.
      _controller.text = body;
      setState(() => _hasText = body.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = !_hasText || widget.isSending;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                enabled: !widget.isSending,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan…',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SendButton(
              isDisabled: isDisabled,
              isLoading: widget.isSending,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol kirim — accent circle aktif, muted disabled.
/// Animasi scale 0.95 saat tap (design-spec §10).
class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.isDisabled,
    required this.isLoading,
    required this.onTap,
  });

  final bool isDisabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = widget.isDisabled
        ? colors.secondary.withValues(alpha: 0.35)
        : colors.primary;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled) setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isDisabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

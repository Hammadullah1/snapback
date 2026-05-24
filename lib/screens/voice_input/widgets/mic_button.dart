import 'package:flutter/material.dart';

import '../../../config/theme.dart';

enum MicState { idle, recording, transcribing }

class MicButton extends StatefulWidget {
  final MicState state;
  final VoidCallback onTap;
  const MicButton({super.key, required this.state, required this.onTap});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.state == MicState.recording) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MicButton old) {
    super.didUpdateWidget(old);
    if (widget.state == MicState.recording && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.state != MicState.recording && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcribing = widget.state == MicState.transcribing;
    return GestureDetector(
      onTap: transcribing ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final scale = 1.0 + (_pulse.value * 0.08);
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.state == MicState.recording
                ? AppColors.danger
                : AppColors.accent,
            boxShadow: [
              BoxShadow(
                color: (widget.state == MicState.recording
                        ? AppColors.danger
                        : AppColors.accent)
                    .withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: transcribing
                ? const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    widget.state == MicState.recording
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
          ),
        ),
      ),
    );
  }
}

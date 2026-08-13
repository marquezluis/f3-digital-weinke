// lib/utils/q_mode_transition.dart
// A distinct "gearing up" transition for entering Q Mode — a slight scale-up
// + fade + upward slide, instead of the platform's default push, so stepping
// into the live timer feels like a deliberate moment rather than just
// another screen change. Respects Reduced Motion by falling back to a plain
// fade (still a transition, just without the scale/slide motion).

import 'package:flutter/material.dart';

Route<T> qModeRoute<T>(Widget screen, {required bool reducedMotion}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => screen,
    transitionsBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      if (reducedMotion) {
        return FadeTransition(opacity: curved, child: child);
      }
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

// Consistent fade + subtle slide transition used for every pushed route,
// so navigation feels continuous rather than snapping between screens.
Route<T> smoothRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

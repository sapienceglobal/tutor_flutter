import 'package:flutter/material.dart';

/// Premium page transition utilities.
/// Replace default MaterialPageRoute with smooth, animated transitions.

/// Fade + Slide Up transition (like iOS bottom sheet feel)
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Fade through transition (Material Design motion)
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeThroughRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
}

/// Shared Axis transition — horizontal slide with fade (like tabs)
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SharedAxisRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.15, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
        );
}

/// Helper extension for Navigator convenience
extension NavigatorPremium on NavigatorState {
  /// Push with slide-up animation
  Future<T?> pushSlideUp<T>(Widget page) {
    return push<T>(SlideUpRoute<T>(page: page));
  }

  /// Push with fade-through animation
  Future<T?> pushFadeThrough<T>(Widget page) {
    return push<T>(FadeThroughRoute<T>(page: page));
  }

  /// Push with shared axis animation
  Future<T?> pushSharedAxis<T>(Widget page) {
    return push<T>(SharedAxisRoute<T>(page: page));
  }
}

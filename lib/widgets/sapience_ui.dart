import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Soft ice-blue page canvas gradient (`#F9FBFF` -> `#F3F6FD`) matching Sapience Mobile UI.
class SapienceBackground extends StatelessWidget {
  final Widget child;
  const SapienceBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

/// Standard `.mhd` mobile header matching Sapience LMS PNGs.
class SapienceHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? titleBadge;
  final VoidCallback? onBack;
  final bool centerTitle;

  const SapienceHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.titleBadge,
    this.onBack,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final effectiveLeading = leading ??
        (canPop || onBack != null
            ? IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.navy,
                  size: 24,
                ),
                splashRadius: 22,
              )
            : const SizedBox(width: 40));

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            effectiveLeading,
            Expanded(
              child: Align(
                alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    if (titleBadge != null) ...[
                      const SizedBox(width: 8),
                      titleBadge!,
                    ],
                  ],
                ),
              ),
            ),
            if (actions.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: actions)
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

/// Bell icon button with optional red unread dot (`.ico.rdot`).
class SapienceBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const SapienceBellButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.navy,
              size: 26,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SapienceNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showDot;

  const SapienceNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showDot = false,
  });
}

/// Deep navy gradient bottom navigation bar with crisp white selected pill (`.mnav`).
class SapienceBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SapienceNavItem> items;

  const SapienceBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navBarTop, AppColors.navBarBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navBarBottom.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 24,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.94),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.94),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                        if (item.showDot)
                          Positioned(
                            top: 8,
                            right: 16,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Crisp gradient white card matching `.mc`.
class SapienceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final Color? borderColor;

  const SapienceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.onTap,
    this.gradientColors,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? const [Colors.white, AppColors.surfaceSoft],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.cardBorder, width: 1),
        boxShadow: const [AppThemeDesign.cardShadow],
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: box,
      ),
    );
  }
}

enum SapienceTileTone { blue, green, purple, orange, pink, white }

/// Pastel tinted quick-action or stat tile matching `.mtile`.
class SapienceTintedTile extends StatelessWidget {
  final SapienceTileTone tone;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final String? badgeText;

  const SapienceTintedTile({
    super.key,
    this.tone = SapienceTileTone.blue,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius = 16,
    this.badgeText,
  });

  List<Color> get _colors {
    switch (tone) {
      case SapienceTileTone.blue:
        return const [Color(0xFFF6F9FF), Color(0xFFE9F0FD)];
      case SapienceTileTone.green:
        return const [Color(0xFFF7FDF9), Color(0xFFE7F7EE)];
      case SapienceTileTone.purple:
        return const [Color(0xFFFAF7FF), Color(0xFFEFE8FC)];
      case SapienceTileTone.orange:
        return const [Color(0xFFFFFBF4), Color(0xFFFDF0DC)];
      case SapienceTileTone.pink:
        return const [Color(0xFFFFF8FB), Color(0xFFFCE9F1)];
      case SapienceTileTone.white:
        return const [Colors.white, Color(0xFFF5F8FE)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE7EDF8)),
        boxShadow: const [AppThemeDesign.softShadow],
      ),
      child: child,
    );

    final widget = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: container),
        if (badgeText != null)
          Positioned(
            top: -7,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return widget;
    return InteractivePressScale(onTap: onTap!, child: widget);
  }
}

/// Section heading + royal blue `"View All ->"` link matching `.msec`.
class SapienceSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SapienceSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pill segmented tab switcher matching `.mtabs`.
class SapienceSegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final int? liveDotIndex;
  final bool flat;

  const SapienceSegmentedTabs({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
    this.liveDotIndex,
    this.flat = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.innerSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4EBF7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x161E46A0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isOn = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 36,
                decoration: BoxDecoration(
                  gradient: isOn ? AppColors.primaryGradient : null,
                  color: isOn
                      ? null
                      : (flat ? Colors.transparent : const Color(0xFFE8EEF8)),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isOn ? const [AppThemeDesign.brandShadow] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        tabs[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isOn ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                    if (liveDotIndex == i) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Emerald green progress bar matching `.mbar`.
class SapienceProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? fillColor;

  const SapienceProgressBar({
    super.key,
    required this.value,
    this.height = 9,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.trackBlue,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            gradient: fillColor == null ? AppColors.progressGradient : null,
            color: fillColor,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

enum SapienceButtonVariant { blue, green, greenToBlue, outlinedNavy, outlinedGreen }

/// Pill gradient button matching `.mbtn` variants.
class SapienceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final SapienceButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const SapienceButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = SapienceButtonVariant.blue,
    this.leadingIcon,
    this.trailingIcon,
    this.height = 42,
    this.fontSize = 14,
    this.padding,
    this.borderRadius = 999,
  });

  @override
  Widget build(BuildContext context) {
    Gradient? grad;
    Color bg = Colors.white;
    Color fg = Colors.white;
    Border? border;
    List<BoxShadow>? shadow;

    switch (variant) {
      case SapienceButtonVariant.blue:
        grad = AppColors.primaryGradient;
        shadow = const [AppThemeDesign.brandShadow];
        break;
      case SapienceButtonVariant.green:
        grad = AppColors.greenGradient;
        shadow = [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case SapienceButtonVariant.greenToBlue:
        grad = AppColors.greenToBlueGradient;
        shadow = const [AppThemeDesign.brandShadow];
        break;
      case SapienceButtonVariant.outlinedNavy:
        fg = AppColors.navy;
        border = Border.all(color: AppColors.navy, width: 1.5);
        break;
      case SapienceButtonVariant.outlinedGreen:
        fg = AppColors.success;
        border = Border.all(color: AppColors.success, width: 1.6);
        break;
    }

    return Opacity(
      opacity: onTap == null ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: height,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: grad,
              color: grad == null ? bg : null,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border,
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: fontSize + 3, color: fg),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(trailingIcon, size: fontSize + 3, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular play / lock icon matching `.mplay`, `.mplay.solid`, `.mplay.lock`.
class SapiencePlayCircle extends StatelessWidget {
  final bool solid;
  final bool locked;
  final double size;
  final VoidCallback? onTap;

  const SapiencePlayCircle({
    super.key,
    this.solid = false,
    this.locked = false,
    this.size = 38,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: solid && !locked
            ? const LinearGradient(
                colors: [Color(0xFF3A8DFF), Color(0xFF0757EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF4F8FF), Color(0xFFE5EDFB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        boxShadow: [
          BoxShadow(
            color: (solid && !locked
                    ? AppColors.primary
                    : const Color(0xFF1E46A0))
                .withValues(alpha: solid && !locked ? 0.34 : 0.14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
        size: locked ? size * 0.46 : size * 0.56,
        color: locked
            ? const Color(0xFF26357A)
            : (solid ? Colors.white : AppColors.primary),
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

/// Live indicator pill (`• LIVE`) matching `.mlive`.
class SapienceLiveBadge extends StatelessWidget {
  final String text;
  final Color color;
  const SapienceLiveBadge({
    super.key,
    this.text = 'LIVE',
    this.color = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deep Navy Wave Banner matching Profile Hero, Course Details Banner & Result Banner.
class SapienceNavyWaveBanner extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const SapienceNavyWaveBanner({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _SapienceNavyWavePainter()),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SapienceNavyWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.navyBannerStart,
          AppColors.navyBannerMid,
          AppColors.navyBannerEnd,
        ],
        stops: [0.0, 0.58, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Subtle right radial blue glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.75, -0.4),
        radius: 1.0,
        colors: [
          const Color(0xFF3A7DFF).withValues(alpha: 0.36),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    // Top-right flowing green/cyan wave ribbon (from Profile/Course PNGs)
    final topWave = Path()
      ..moveTo(size.width * 0.58, 0)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.14,
        size.width * 0.78,
        size.height * 0.42,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      topWave,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1EE249), Color(0xFF0A85FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    // Bottom-right sweeping bright emerald-to-blue wave
    final bottomWave = Path()
      ..moveTo(size.width * 0.42, size.height)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.72,
        size.width * 0.84,
        size.height * 0.66,
        size.width,
        size.height * 0.56,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      bottomWave,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF17D443).withValues(alpha: 0.9),
            const Color(0xFF0B5CFF).withValues(alpha: 0.85),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SapienceStatItem {
  final Widget icon;
  final String value;
  final String label;

  const SapienceStatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
}

/// 4-column stat strip with vertical dividers matching `.mstat`.
class SapienceStatsRow extends StatelessWidget {
  final List<SapienceStatItem> items;
  final double borderRadius;

  const SapienceStatsRow({
    super.key,
    required this.items,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SapienceCard(
      borderRadius: borderRadius,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Expanded(
            child: Container(
              decoration: i > 0
                  ? const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.divider, width: 1.2),
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  item.icon,
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Dual emerald-green -> royal-blue score/progress ring (from Home & Progress PNGs).
class SapienceScoreRing extends StatelessWidget {
  final double percentage; // 0 to 100
  final double size;
  final double strokeWidth;
  final Widget center;
  final Color? trackColor;

  const SapienceScoreRing({
    super.key,
    required this.percentage,
    this.size = 76,
    this.strokeWidth = 7,
    required this.center,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ScoreRingPainter(
              progress: (percentage / 100).clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              trackColor: trackColor ?? const Color(0xFFDCE6F7),
            ),
          ),
          center,
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;

  _ScoreRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    final sweep = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 1.5 * math.pi,
        colors: [Color(0xFF0B5CFF), Color(0xFF16B53A), Color(0xFF10A85A)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
}

/// Emerald green circular checkmark icon matching `.mchk`.
class SapienceCheckBadge extends StatelessWidget {
  final double size;
  const SapienceCheckBadge({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * 0.64,
        color: Colors.white,
      ),
    );
  }
}


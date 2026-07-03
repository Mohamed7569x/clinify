import 'package:flutter/material.dart';
import '../app/config/app_theme.dart';

// ═══════════════════════════════════════════
// Status Badge (Arabic)
// ═══════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String s) {
    switch (s.toUpperCase()) {
      case 'CONFIRMED':
        return _StatusConfig('مؤكد', AppTheme.primary, AppTheme.primaryLight);
      case 'COMPLETED':
        return _StatusConfig(
            'مكتمل', AppTheme.success, AppTheme.successSoft);
      case 'CANCELLED':
        return _StatusConfig('ملغي', AppTheme.error, AppTheme.errorSoft);
      case 'NO_SHOW':
        return _StatusConfig(
            'لم يحضر', AppTheme.error, AppTheme.errorSoft);
      case 'RESCHEDULED':
        return _StatusConfig(
            'مُعاد جدولته', AppTheme.purple, AppTheme.purpleSoft);
      default:
        return _StatusConfig(
            'بانتظار', AppTheme.warning, AppTheme.warningSoft);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final Color bg;
  _StatusConfig(this.label, this.color, this.bg);
}

// ═══════════════════════════════════════════
// Star Rating (display)
// ═══════════════════════════════════════════

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  const StarRating({required this.rating, this.size = 16, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, size: size, color: AppTheme.amber);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded,
              size: size, color: AppTheme.amber);
        }
        return Icon(Icons.star_outline_rounded,
            size: size, color: AppTheme.textHint);
      }),
    );
  }
}

// ═══════════════════════════════════════════
// Interactive Star Rating (for reviews)
// ═══════════════════════════════════════════

class InteractiveStarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  const InteractiveStarRating({
    required this.rating,
    required this.onChanged,
    this.size = 36,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < rating ? AppTheme.amber : AppTheme.textHint,
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════
// User Avatar
// ═══════════════════════════════════════════

class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;

  const UserAvatar({
    required this.name,
    this.size = 40,
    this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final colors = [
      AppTheme.primary,
      AppTheme.info,
      AppTheme.purple,
      AppTheme.warning,
      AppTheme.error,
      AppTheme.success,
    ];
    final bgColors = [
      AppTheme.primaryLight,
      const Color(0xFFEBF2FF),
      const Color(0xFFF0EBFF),
      const Color(0xFFFFF7E6),
      AppTheme.errorSoft,
      AppTheme.successSoft,
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColors[idx],
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: colors[idx],
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Empty State (Arabic)
// ═══════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Loading Overlay
// ═══════════════════════════════════════════

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
      ],
    );
  }
}

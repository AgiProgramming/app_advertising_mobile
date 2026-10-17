import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Angka rupiah dengan tabular figures supaya digit tidak bergeser.
class Money extends StatelessWidget {
  const Money(
    this.value, {
    super.key,
    this.size = 16,
    this.weight = FontWeight.w700,
    this.color,
    this.prefix = true,
  });

  final String value;
  final double size;
  final FontWeight weight;
  final Color? color;
  final bool prefix;

  @override
  Widget build(BuildContext context) {
    return Text(
      prefix ? 'Rp $value' : value,
      style: appText(size: size, weight: weight, color: color).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

enum StatusTone { paid, unpaid, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = StatusTone.neutral, this.dot = true});

  factory StatusBadge.payment(String status) => StatusBadge(
        status,
        tone: status == 'Sudah Dibayar' ? StatusTone.paid : StatusTone.unpaid,
      );

  final String label;
  final StatusTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StatusTone.paid => (AppColors.successSoft, AppColors.success),
      StatusTone.unpaid => (AppColors.warningSoft, AppColors.warning),
      StatusTone.neutral => (AppColors.surfaceSunken, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: tone == StatusTone.neutral ? Border.all(color: AppColors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 5, height: 5, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Text(label, style: appText(size: 11, weight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Kartu putih ber-border 1px (komponen dasar aplikasi).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.hint, this.valueSize = 14});

  final String label;
  final String value;
  final String? hint;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: labelText().copyWith(fontSize: 9.5, letterSpacing: 0.5)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Money(value, size: valueSize, prefix: false),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: appText(size: 10, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: appText(size: 15, weight: FontWeight.w700))),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: appText(size: 12, weight: FontWeight.w600, color: AppColors.primary)),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined, this.action});

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.borderStrong),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: appText(size: 14, color: AppColors.muted, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.borderStrong),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: appText(size: 14, color: AppColors.muted, height: 1.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kerangka isi halaman: loading / error / kosong / data.
class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.isEmpty,
    required this.child,
    this.emptyMessage = 'Belum ada data.',
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final bool isEmpty;
  final Widget child;
  final String emptyMessage;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (error != null) return ErrorView(message: error!, onRetry: onRetry);
    if (isEmpty) return EmptyState(message: emptyMessage);

    return RefreshIndicator(onRefresh: () async => onRetry(), child: child);
  }
}

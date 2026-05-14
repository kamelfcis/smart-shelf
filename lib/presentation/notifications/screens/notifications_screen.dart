import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/notification_model.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollCtrl = ScrollController();
  int _prevCount = 0;

  /// IDs optimistically removed locally before the stream confirms deletion.
  /// Prevents "dismissed Dismissible still in tree" assertion.
  final Set<String> _dismissedIds = {};

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onDismiss(String id, NotificationActionsNotifier notifier) {
    // Remove immediately from local set so the list rebuilds without the item.
    setState(() => _dismissedIds.add(id));
    // Fire-and-forget the async delete.
    notifier.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final actionsNotifier = ref.read(notificationActionsProvider.notifier);

    // Auto-scroll to top when a new notification arrives.
    // Also prune _dismissedIds for items the stream has already removed.
    ref.listen<AsyncValue<List<NotificationModel>>>(
      notificationsStreamProvider,
      (_, next) {
        final list = next.valueOrNull ?? [];
        final count = list.length;
        final streamIds = list.map((n) => n.id).toSet();
        if (mounted) {
          setState(() => _dismissedIds.removeWhere(
              (id) => !streamIds.contains(id)));
        }
        if (count > _prevCount) {
          _prevCount = count;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
        } else {
          _prevCount = count;
        }
      },
    );

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              SmartShelfAppBar(
                title: 'Notifications',
                actions: [
                  // ── Test panel trigger ───────────────────
                  IconButton(
                    icon: const Icon(
                      Icons.science_outlined,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Send test notification',
                    onPressed: () => _showTestPanel(context, actionsNotifier),
                  ),
                  TextButton(
                    onPressed: () => actionsNotifier.markAllAsRead(),
                    child: Text(
                      'Mark all read',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: notifsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load notifications',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                  data: (notifs) {
                    // Filter out items already optimistically dismissed.
                    final visible = notifs
                        .where((n) => !_dismissedIds.contains(n.id))
                        .toList();

                    if (visible.isEmpty) {
                      return RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async =>
                            ref.invalidate(notificationsStreamProvider),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(
                              icon: Icons.notifications_none_outlined,
                              title: 'All caught up!',
                              subtitle:
                                  "No notifications yet. We'll alert you when something needs attention.",
                            ),
                          ],
                        ),
                      );
                    }

                    final today = DateTime.now();
                    final todayNotifs = visible
                        .where((n) =>
                            today.difference(n.createdAt).inHours < 24)
                        .toList();
                    final earlierNotifs = visible
                        .where((n) =>
                            today.difference(n.createdAt).inHours >= 24)
                        .toList();

                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: () async =>
                          ref.invalidate(notificationsStreamProvider),
                      child: ListView(
                        controller: _scrollCtrl,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPadding,
                        ),
                        children: [
                          if (todayNotifs.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.md),
                            _SectionHeader(title: 'Today'),
                            const SizedBox(height: AppDimensions.sm),
                            ...todayNotifs.asMap().entries.map(
                                  (e) => _NotifCard(
                                    notif: e.value,
                                    index: e.key,
                                    onDismiss: () =>
                                        _onDismiss(e.value.id, actionsNotifier),
                                    onTap: () =>
                                        actionsNotifier.markAsRead(e.value.id),
                                  ),
                                ),
                          ],
                          if (earlierNotifs.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.md),
                            _SectionHeader(title: 'Earlier'),
                            const SizedBox(height: AppDimensions.sm),
                            ...earlierNotifs.asMap().entries.map(
                                  (e) => _NotifCard(
                                    notif: e.value,
                                    index: todayNotifs.length + e.key,
                                    onDismiss: () =>
                                        _onDismiss(e.value.id, actionsNotifier),
                                    onTap: () =>
                                        actionsNotifier.markAsRead(e.value.id),
                                  ),
                                ),
                          ],
                          const SizedBox(height: AppDimensions.xl),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showTestPanel(
  BuildContext context,
  NotificationActionsNotifier notifier,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Material(
      color: Colors.transparent,
      child: _TestNotificationPanel(notifier: notifier),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Test notification panel
// ─────────────────────────────────────────────────────────────────────────────

class _TestNotificationPanel extends StatefulWidget {
  const _TestNotificationPanel({required this.notifier});
  final NotificationActionsNotifier notifier;

  @override
  State<_TestNotificationPanel> createState() =>
      _TestNotificationPanelState();
}

class _TestNotificationPanelState extends State<_TestNotificationPanel> {
  String? _sending;

  Future<void> _send(String type) async {
    setState(() => _sending = type);
    await widget.notifier.insertTest(type);
    if (mounted) {
      setState(() => _sending = null);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    const types = [
      (
        type: 'low_stock',
        label: 'Low Stock',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      (
        type: 'item_removed',
        label: 'Item Empty',
        icon: Icons.remove_shopping_cart_outlined,
        color: AppColors.error,
      ),
      (
        type: 'sensor_offline',
        label: 'Sensor Offline',
        icon: Icons.sensors_off_rounded,
        color: AppColors.secondary,
      ),
      (
        type: 'system',
        label: 'System',
        icon: Icons.info_outline_rounded,
        color: AppColors.primary,
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Notifications',
                      style: AppTypography.headingSmall),
                  Text('Tap a type to fire a demo notification',
                      style: AppTypography.caption),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),

          ...types.map((t) {
            final isSending = _sending == t.type;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: InkWell(
                onTap: _sending != null ? null : () => _send(t.type),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.md,
                  ),
                  decoration: BoxDecoration(
                    color: t.color.withAlpha(12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: t.color.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: t.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd),
                        ),
                        child: Icon(t.icon, color: t.color, size: 18),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Text(
                          t.label,
                          style: AppTypography.labelLarge
                              .copyWith(color: t.color),
                        ),
                      ),
                      if (isSending)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.color,
                          ),
                        )
                      else
                        Icon(
                          Icons.send_rounded,
                          color: t.color.withAlpha(160),
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppDimensions.sm),
        ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.notif,
    required this.index,
    required this.onDismiss,
    required this.onTap,
  });

  final NotificationModel notif;
  final int index;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  Color get _typeColor {
    switch (notif.type) {
      case NotifType.lowStock:
        return AppColors.warning;
      case NotifType.itemRemoved:
        return AppColors.error;
      case NotifType.sensorOffline:
        return AppColors.secondary;
      case NotifType.system:
        return AppColors.primary;
    }
  }

  IconData get _typeIcon {
    switch (notif.type) {
      case NotifType.lowStock:
        return Icons.warning_amber_rounded;
      case NotifType.itemRemoved:
        return Icons.remove_shopping_cart_outlined;
      case NotifType.sensorOffline:
        return Icons.sensors_off_rounded;
      case NotifType.system:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.lg),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(40),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: GlassCard(
          onTap: onTap,
          backgroundColor: notif.isRead
              ? null
              : _typeColor.withAlpha(12),
          border: Border.all(
            color: notif.isRead
                ? AppColors.border
                : _typeColor.withAlpha(60),
            width: 1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor.withAlpha(25),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 20),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: notif.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _typeColor,
                              boxShadow: [
                                BoxShadow(
                                  color: _typeColor.withAlpha(120),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (notif.body != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        notif.body!,
                        style: AppTypography.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.dateTime(notif.createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

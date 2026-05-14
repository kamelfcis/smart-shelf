import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/seed_data.dart';
import '../../auth/providers/auth_provider.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_button.dart';
import '../providers/dashboard_provider.dart';
import '../../../data/models/shelf_model.dart';
import '../../notifications/providers/notification_provider.dart';

// ── Accent palette cycling per shelf ─────────────────────────────────────────
const _kAccents = [
  [Color(0xFF6C63FF), Color(0xFF4A42D6)], // purple
  [Color(0xFF00E5FF), Color(0xFF0097A7)], // cyan
  [Color(0xFF00E096), Color(0xFF00897B)], // green
  [Color(0xFFFF6B6B), Color(0xFFE53935)], // red
  [Color(0xFFFFB74D), Color(0xFFF57C00)], // amber
  [Color(0xFFCE93D8), Color(0xFF8E24AA)], // violet
];

List<Color> _accentFor(int index) => _kAccents[index % _kAccents.length];

// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelvesAsync = ref.watch(shelvesStreamProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final user = ref.watch(currentUserProvider);
    final itemCounts = ref.watch(shelfItemCountsProvider).valueOrNull ?? {};

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shelvesStreamProvider);
              ref.invalidate(shelfItemCountsProvider);
            },
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.md,
                      AppDimensions.screenPadding,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_greeting()},',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                user?.userMetadata?['full_name']
                                        ?.toString()
                                        .split(' ')
                                        .first ??
                                    'User',
                                style: AppTypography.displaySmall,
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.2),
                        ),
                        NotificationBell(
                          unreadCount: unreadCount,
                          onTap: () =>
                              context.push(AppRoutes.notifications),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        _AvatarButton(user: user),
                      ],
                    ),
                  ),
                ),

                // ── Stats row ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.lg,
                      AppDimensions.screenPadding,
                      0,
                    ),
                    child: _StatsRow(stats: stats),
                  ),
                ),

                // ── Section header ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.screenPadding,
                      AppDimensions.xl,
                      AppDimensions.screenPadding,
                      AppDimensions.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Shelves',
                          style: AppTypography.headingMedium,
                        ),
                        IconTextButton(
                          label: 'Add Shelf',
                          icon: Icons.add_rounded,
                          onPressed: () => context.push('/shelf/add'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cinema carousel ───────────────────────────────────────
                shelvesAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPadding,
                        ),
                        itemCount: 2,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(right: 16),
                          // Fixed width required — horizontal ListView
                          // gives unbounded width to children.
                          child: SizedBox(
                            width: 300,
                            child: ShelfCardShimmer(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'Failed to load shelves',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                  data: (shelves) {
                    if (shelves.isEmpty) {
                      return SliverFillRemaining(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No shelves yet',
                          subtitle:
                              'Add your first shelf, or load demo data to explore the app.',
                          action: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PrimaryButton(
                                label: 'Add Your First Shelf',
                                isFullWidth: false,
                                onPressed: () =>
                                    context.push('/shelf/add'),
                              ),
                              const SizedBox(height: AppDimensions.sm),
                              _SeedButton(
                                onSeeded: () {
                                  ref.invalidate(shelvesStreamProvider);
                                  ref.invalidate(shelfItemCountsProvider);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverToBoxAdapter(
                      child: _CinemaCarousel(
                        shelves: shelves,
                        itemCounts: itemCounts,
                        onDelete: (id) async {
                          final ok = await ref
                              .read(shelfFormProvider.notifier)
                              .deleteShelf(id);
                          if (ok) {
                            ref.invalidate(shelvesStreamProvider);
                            ref.invalidate(shelfItemCountsProvider);
                          }
                        },
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.xxl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cinema carousel
// ─────────────────────────────────────────────────────────────────────────────

class _CinemaCarousel extends StatefulWidget {
  const _CinemaCarousel({
    required this.shelves,
    required this.itemCounts,
    required this.onDelete,
  });

  final List<ShelfModel> shelves;
  final Map<String, int> itemCounts;
  final Future<void> Function(String shelfId) onDelete;

  @override
  State<_CinemaCarousel> createState() => _CinemaCarouselState();
}

class _CinemaCarouselState extends State<_CinemaCarousel> {
  late final PageController _ctrl;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.84, initialPage: 0);
    _ctrl.addListener(() {
      setState(() => _page = _ctrl.page ?? 0);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.shelves.length,
            itemBuilder: (ctx, i) {
              final delta = (_page - i).abs();
              final scale = (1.0 - delta * 0.07).clamp(0.88, 1.0);
              final opacity = (1.0 - delta * 0.35).clamp(0.55, 1.0);

              return TweenAnimationBuilder<double>(
                tween: Tween(end: scale),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (_, s, child) => Transform.scale(
                  scale: s,
                  child: Opacity(opacity: opacity, child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: _CinemaCard(
                    shelf: widget.shelves[i],
                    index: i,
                    itemCount:
                        widget.itemCounts[widget.shelves[i].id] ?? 0,
                    onDelete: () =>
                        widget.onDelete(widget.shelves[i].id),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppDimensions.md),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.shelves.length, (i) {
            final active = (_page.round()) == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusFull,
                ),
                color: active
                    ? _accentFor(i)[0]
                    : AppColors.textHint.withAlpha(100),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _accentFor(i)[0].withAlpha(100),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual cinema card
// ─────────────────────────────────────────────────────────────────────────────

class _CinemaCard extends StatelessWidget {
  const _CinemaCard({
    required this.shelf,
    required this.index,
    required this.itemCount,
    required this.onDelete,
  });

  final ShelfModel shelf;
  final int index;
  final int itemCount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(index);

    return GestureDetector(
      onTap: () => context.push(
        '/shelf/${shelf.id}',
        extra: {'name': shelf.name},
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(AppColors.card, accent[0], 0.30)!,
              Color.lerp(AppColors.card, accent[1], 0.18)!,
            ],
          ),
          border: Border.all(
            color: accent[0].withAlpha(60),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent[0].withAlpha(40),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative hex glyph (top-right)
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.hexagon_outlined,
                  size: 160,
                  color: accent[0],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: icon + menu ──────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shelf icon
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: accent),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent[0].withAlpha(80),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shelves,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const Spacer(),

                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: shelf.isOnline
                              ? AppColors.success.withAlpha(25)
                              : AppColors.textHint.withAlpha(25),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          border: Border.all(
                            color: shelf.isOnline
                                ? AppColors.success.withAlpha(80)
                                : AppColors.textHint.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SensorDot(isOnline: shelf.isOnline),
                            const SizedBox(width: 5),
                            Text(
                              shelf.isOnline ? 'Online' : 'Offline',
                              style: AppTypography.labelSmall.copyWith(
                                color: shelf.isOnline
                                    ? AppColors.success
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4),

                      // ⋮ menu
                      _ShelfMenu(shelf: shelf, onDelete: onDelete),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.md),

                  // ── Name + location ───────────────────────────────────
                  Text(
                    shelf.name,
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (shelf.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            shelf.location!,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // ── Bottom stats bar ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(30),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.category_outlined,
                          label: '$itemCount items',
                          color: accent[0],
                        ),
                        const SizedBox(width: AppDimensions.md),
                        if (shelf.sensorId != null)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.memory_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    shelf.sensorId!,
                                    style: AppTypography.monoSmall
                                        .copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: accent[0].withAlpha(200),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.12, end: 0),
    );
  }
}

// ── Small stat chip inside the card ──────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

// ── ⋮ popup menu on the card ─────────────────────────────────────────────────

class _ShelfMenu extends StatelessWidget {
  const _ShelfMenu({required this.shelf, required this.onDelete});
  final ShelfModel shelf;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ShelfAction>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: AppColors.textHint,
        size: 20,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      onSelected: (action) async {
        if (action == _ShelfAction.edit) {
          context.push('/shelf/${shelf.id}/edit');
        } else {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => _DeleteDialog(
              title: 'Delete Shelf',
              message:
                  'Delete "${shelf.name}"?\nAll items inside will also be deleted.',
            ),
          );
          if (confirmed == true) onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ShelfAction.edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text('Edit', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ShelfAction.delete,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.error),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style:
                    AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ShelfAction { edit, delete }

// ─────────────────────────────────────────────────────────────────────────────
// Seed button
// ─────────────────────────────────────────────────────────────────────────────

class _SeedButton extends StatefulWidget {
  const _SeedButton({required this.onSeeded});
  final VoidCallback onSeeded;

  @override
  State<_SeedButton> createState() => _SeedButtonState();
}

class _SeedButtonState extends State<_SeedButton> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);
    await SeedData.insert();
    if (mounted) {
      setState(() => _loading = false);
      widget.onSeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _loading ? null : _seed,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(Icons.auto_fix_high_rounded,
              color: AppColors.primary, size: 18),
      label: Text(
        _loading ? 'Loading demo data…' : 'Load Demo Data',
        style:
            AppTypography.labelLarge.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'Shelves',
          value: '${stats.totalShelves}',
          icon: Icons.shelves,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.sm),
        _StatTile(
          label: 'Online',
          value: '${stats.onlineShelves}',
          icon: Icons.sensors_rounded,
          color: AppColors.success,
        ),
        const SizedBox(width: AppDimensions.sm),
        _StatTile(
          label: 'Alerts',
          value: '${stats.totalAlerts}',
          icon: Icons.warning_amber_rounded,
          color: stats.totalAlerts > 0
              ? AppColors.warning
              : AppColors.textHint,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppDimensions.xs),
            Text(
              value,
              style: AppTypography.displaySmall.copyWith(
                fontSize: 22,
                color: AppColors.textPrimary,
              ),
            ),
            Text(label, style: AppTypography.caption),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: 200.ms, duration: 400.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar button
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final initial = (user?.userMetadata?['full_name']
                ?.toString()
                .substring(0, 1) ??
            'U')
        .toUpperCase();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.profile),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(color: AppColors.primaryGlow, blurRadius: 12),
          ],
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete confirmation dialog (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        side: BorderSide(color: AppColors.border),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(title, style: AppTypography.headingSmall),
          ),
        ],
      ),
      content: Text(message, style: AppTypography.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }
}


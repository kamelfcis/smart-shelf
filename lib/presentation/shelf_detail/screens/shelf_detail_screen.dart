import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_button.dart';
import '../providers/shelf_detail_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart'
    show shelfFormProvider, shelvesStreamProvider;
import '../../../data/models/item_model.dart';

class ShelfDetailScreen extends ConsumerWidget {
  const ShelfDetailScreen({
    super.key,
    required this.shelfId,
    this.shelfName,
  });

  final String shelfId;
  final String? shelfName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsStreamProvider(shelfId));
    final shelfAsync = ref.watch(shelfProvider(shelfId));

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              shelfAsync.when(
                data: (shelf) => SmartShelfAppBar(
                  title: shelf?.name ?? shelfName ?? 'Shelf',
                  subtitle: shelf?.location,
                  actions: [
                    if (shelf != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: SensorDot(isOnline: shelf.isOnline),
                      ),
                    // ⋮ menu: Edit shelf + Delete shelf
                    PopupMenuButton<_ShelfDetailAction>(
                      icon: const Icon(Icons.more_vert_rounded),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        side: BorderSide(color: AppColors.border),
                      ),
                      onSelected: (action) async {
                        if (action == _ShelfDetailAction.edit) {
                          context.push('/shelf/$shelfId/edit');
                        } else {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => _DeleteDialog(
                              title: 'Delete Shelf',
                              message:
                                  'Delete "${shelf?.name ?? 'this shelf'}"?\nAll items inside will also be deleted.',
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            final ok = await ref
                                .read(shelfFormProvider.notifier)
                                .deleteShelf(shelfId);
                            if (ok && context.mounted) {
                              ref.invalidate(shelvesStreamProvider);
                              context.pop();
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _ShelfDetailAction.edit,
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 10),
                              Text('Edit shelf',
                                  style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _ShelfDetailAction.delete,
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 10),
                              Text(
                                'Delete shelf',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () =>
                    SmartShelfAppBar(title: shelfName ?? 'Shelf'),
                error: (_, __) =>
                    SmartShelfAppBar(title: shelfName ?? 'Shelf'),
              ),

              // Body
              Expanded(
                child: itemsAsync.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenPadding,
                    ),
                    itemCount: 4,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.sm),
                      child: ItemRowShimmer(),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Failed to load items',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.category_outlined,
                        title: 'No items yet',
                        subtitle:
                            'Add items to start tracking stock levels',
                        action: PrimaryButton(
                          label: 'Add Item',
                          isFullWidth: false,
                          onPressed: () =>
                              context.push('/shelf/$shelfId/item/add'),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPadding,
                        vertical: AppDimensions.sm,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.md,
                        ),
                        child: _ItemCard(item: items[i], index: i),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shelf/$shelfId/item/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Item',
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      )
          .animate(delay: 600.ms)
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.5, end: 0),
    );
  }
}

enum _ShelfDetailAction { edit, delete }

// ─────────────────────────────────────────────────────────────────────────────
// Item card with ⋮ menu (edit + delete)
// ─────────────────────────────────────────────────────────────────────────────

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item, required this.index});
  final ItemModel item;
  final int index;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(
        title: 'Delete Item',
        message:
            'Delete "${item.name}" from this shelf?\nThis cannot be undone.',
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok =
          await ref.read(itemFormProvider.notifier).deleteItem(item.id);
      if (ok) {
        ref.invalidate(itemsStreamProvider(item.shelfId));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = stockStatusFromQty(item.currentQty, item.minThreshold);

    return GlassCard(
      onTap: () => context.push(
        '/shelf/${item.shelfId}/item/${item.id}/history',
        extra: {'name': item.name},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Item image / icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: status.color.withAlpha(25),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: status.color.withAlpha(60)),
                ),
                child: item.imageUrl != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.inventory_2_outlined,
                            color: status.color,
                            size: 26,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: status.color,
                        size: 26,
                      ),
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
                            item.name,
                            style: AppTypography.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.weight(item.currentWeight),
                      style: AppTypography.monoSmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.sm),

              // Qty
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.currentQty}',
                    style: AppTypography.monoLarge.copyWith(
                      color: status.color,
                      fontSize: 24,
                    ),
                  ),
                  Text('units', style: AppTypography.caption),
                ],
              ),

              // ── ⋮ menu ──────────────────────────────────────
              PopupMenuButton<_ItemAction>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  side: BorderSide(color: AppColors.border),
                ),
                onSelected: (action) {
                  if (action == _ItemAction.edit) {
                    context.push(
                        '/shelf/${item.shelfId}/item/${item.id}/edit');
                  } else {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _ItemAction.edit,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 18,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Text('Edit', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _ItemAction.delete,
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Stock bar
          StockBar(
            current: item.currentQty,
            max: item.minThreshold * 3,
            minThreshold: item.minThreshold,
          ),

          const SizedBox(height: AppDimensions.xs),

          Text(
            'Min: ${item.minThreshold} units',
            style: AppTypography.caption,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, end: 0);
  }
}

enum _ItemAction { edit, delete }

// ─────────────────────────────────────────────────────────────────────────────
// Shared delete confirmation dialog
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

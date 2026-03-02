import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/notification_item.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  static String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GetBuilder<NotificationsController>(
      init: NotificationsController(),
      builder: (ctrl) {
        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: Obx(() {
                  final count = ctrl.unreadCount.value;
                  return Text(
                    count > 0 ? 'Notifications ($count)' : 'Notifications',
                  );
                }),
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => Get.back(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.arrow_left,
                      color: colors.onSurface,
                      size: 18,
                    ),
                  ),
                ),
                trailing: ctrl.list.isEmpty
                    ? null
                    : CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: ctrl.clearing.value
                            ? null
                            : () async {
                                final confirm = await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                    title: const Text('Clear all?'),
                                    content: const Text(
                                      'Remove all notifications from history.',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        isDefaultAction: true,
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Clear all'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) await ctrl.clearAll();
                              },
                        child: ctrl.clearing.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary,
                                ),
                              )
                            : Text(
                                'Clear all',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                backgroundColor: Colors.transparent,
                border: null,
                automaticallyImplyTitle: false,
                automaticallyImplyLeading: false,
              ),
              SliverSafeArea(
                top: false,
                sliver: Obx(() {
                  if (ctrl.loading.value && ctrl.list.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      ),
                    );
                  }
                  if (ctrl.list.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.bell_slash,
                              size: 56,
                              color: colors.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'When you get messages or updates,\nthey’ll show up here.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 12),
                        SectionHeader(
                          title: 'RECENT (${ctrl.total.value})',
                        ),
                        const SizedBox(height: 16),
                        ...ctrl.list.map((item) {
                          final displayText =
                              item.body.isEmpty ? item.title : '${item.title} ${item.body}';
                          return NotificationItem(
                            profileImage: 'assets/artists/Choc B.png',
                            notificationText: displayText,
                            timestamp: _formatTime(item.createdAt),
                            imageUrl: null,
                            isUnread: !item.isRead,
                            onTap: () => ctrl.handleTap(item),
                          );
                        }),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

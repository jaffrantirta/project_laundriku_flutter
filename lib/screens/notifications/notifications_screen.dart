import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 1;
      _notifications = [];
      _hasMore = true;
    });
    try {
      final res = await ApiService.getNotifications(page: 1);
      final outer = (res['data'] ?? res) as Map<String, dynamic>;
      final inner = outer['data'] as List<dynamic>? ?? [];
      final meta = outer['meta'] as Map<String, dynamic>?;
      setState(() {
        _notifications = inner
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _hasMore = meta != null
            ? (meta['current_page'] as int? ?? 1) < (meta['last_page'] as int? ?? 1)
            : false;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await ApiService.getNotifications(page: _page + 1);
      final outer = (res['data'] ?? res) as Map<String, dynamic>;
      final inner = outer['data'] as List<dynamic>? ?? [];
      final meta = outer['meta'] as Map<String, dynamic>?;
      setState(() {
        _notifications.addAll(inner
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList());
        _page++;
        _hasMore = meta != null
            ? (meta['current_page'] as int? ?? 1) < (meta['last_page'] as int? ?? 1)
            : false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await ApiService.markNotificationRead(n.id);
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifications[idx] = NotificationModel(
            id: n.id,
            type: n.type,
            data: n.data,
            readAt: DateTime.now().toIso8601String(),
            createdAt: n.createdAt,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications.map((n) => NotificationModel(
              id: n.id,
              type: n.type,
              data: n.data,
              readAt: n.readAt ?? DateTime.now().toIso8601String(),
              createdAt: n.createdAt,
            )).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool get _hasUnread => _notifications.any((n) => !n.isRead);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShimmerLoading(height: 76, borderRadius: BorderRadius.circular(14)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _notifications.isEmpty
                  ? const CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          child: EmptyState(
                            title: 'Belum ada notifikasi',
                            subtitle: 'Notifikasi cicilan dan sistem akan muncul di sini',
                            icon: Icons.notifications_none_rounded,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _notifications.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildItem(_notifications[i]);
                      },
                    ),
            ),
    );
  }

  Widget _buildItem(NotificationModel n) {
    final isInstallment = n.type.contains('InstallmentReminder');
    final color = isInstallment ? AppColors.warning : AppColors.primary;
    final icon = isInstallment
        ? Icons.calendar_today_rounded
        : Icons.notifications_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _markRead(n),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.isRead ? AppColors.divider : color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: n.isRead ? 0.08 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                    if (n.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(n.createdAt!),
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

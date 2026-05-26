import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/referral_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupDetailScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupModel? _group;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getGroupDetail(widget.groupId);
      setState(() {
        _group = GroupModel.fromJson(res['data']);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.groupName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _group == null
              ? const EmptyState(title: 'Gagal memuat grup', icon: Icons.error_outline_rounded)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GradientCard(
                            colors: const [AppColors.primary, AppColors.primaryLight],
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _group!.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                                      ),
                                      Text(
                                        '${_group!.membersCount} anggota',
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(title: 'Daftar Anggota (${_group!.membersCount})'),
                        ),
                      ),
                      if (_group!.members == null || _group!.members!.isEmpty)
                        const SliverToBoxAdapter(
                          child: EmptyState(title: 'Belum ada anggota', icon: Icons.group_off_outlined),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final m = _group!.members![i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.primary.withOpacity(0.1),
                                          child: Text(
                                            m.userName.isNotEmpty ? m.userName[0].toUpperCase() : '?',
                                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                              Text(m.userEmail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  m.userReferralCode,
                                                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Bergabung', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                                            Text(
                                              DateFormatter.formatDate(m.joinedAt),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _group!.members!.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

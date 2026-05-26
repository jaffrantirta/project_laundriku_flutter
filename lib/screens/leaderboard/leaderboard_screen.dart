import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/services/api_service.dart';
import '../../widgets/app_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardModel> _items = [];
  CurrentUserRank? _myRank;
  bool _loading = true;
  String? _selectedMonth;
  String _monthLabel = '';
  List<Map<String, dynamic>> _months = [];

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    try {
      final res = await ApiService.getLeaderboardMonths();
      final data = res['data'];
      setState(() {
        _months = List<Map<String, dynamic>>.from(data['months'] ?? []);
        _selectedMonth = data['current_month'];
      });
      await _loadLeaderboard();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getLeaderboard(month: _selectedMonth, perPage: 50);
      final data = res['data'];
      setState(() {
        _items = (data['leaderboard'] as List).map((e) => LeaderboardModel.fromJson(e)).toList();
        _monthLabel = data['month_label'] ?? '';
        if (data['current_user_rank'] != null) {
          _myRank = CurrentUserRank.fromJson(data['current_user_rank']);
        } else {
          _myRank = null;
        }
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
      appBar: AppBar(
        title: const Text('Papan Peringkat'),
        actions: [
          if (_months.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                initialValue: _selectedMonth,
                onSelected: (val) {
                  setState(() => _selectedMonth = val);
                  _loadLeaderboard();
                },
                itemBuilder: (_) => _months.map((m) => PopupMenuItem(
                  value: m['value'] as String,
                  child: Text(m['label'] as String),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _monthLabel.isNotEmpty ? _monthLabel : 'Pilih Bulan',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLeaderboard,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  if (_myRank != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GradientCard(
                          colors: const [AppColors.accent, Color(0xFFFF867F)],
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '#${_myRank!.rank}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Peringkat Anda', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(
                                      'Rank #${_myRank!.rank}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Reward', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text(
                                    CurrencyFormatter.format(_myRank!.amount),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_items.length >= 3)
                    SliverToBoxAdapter(child: _buildPodium()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: _items.isEmpty
                        ? const SliverToBoxAdapter(
                            child: EmptyState(
                              title: 'Belum ada data',
                              subtitle: 'Papan peringkat akan muncul setelah ada aktivitas',
                              icon: Icons.leaderboard_outlined,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final item = _items[i];
                                if (i < 3) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildListItem(item),
                                );
                              },
                              childCount: _items.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPodium() {
    final top3 = _items.take(3).toList();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Top 3 - $_monthLabel',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _podiumItem(top3[1], 2, 80),
              _podiumItem(top3[0], 1, 100),
              _podiumItem(top3[2], 3, 70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(LeaderboardModel item, int rank, double height) {
    final medals = ['🥇', '🥈', '🥉'];
    return Expanded(
      child: Column(
        children: [
          Text(medals[rank - 1], style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            item.user.name.split(' ').first,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.compact(item.amount),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(rank == 1 ? 0.3 : 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(LeaderboardModel item) {
    final isMe = item.user.isCurrentUser;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isMe ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              item.user.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Saya', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text(item.user.referralCode, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isMe ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

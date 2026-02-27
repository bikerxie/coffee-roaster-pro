import 'package:flutter/material.dart';
import '../models/roast_session.dart';

/// 历史记录列表界面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // 模拟历史数据
  List<RoastSession> sessions = [];
  String filterBean = '';

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  void _loadMockData() {
    // 模拟数据
    sessions = [
      RoastSession(
        id: '1',
        beanName: '埃塞俄比亚 耶加雪菲',
        beanOrigin: '埃塞俄比亚',
        beanWeight: 500,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
      )
        ..endTime = DateTime.now().subtract(const Duration(days: 1)).add(const Duration(minutes: 12))
        ..fcTemp = 196
        ..dropTemp = 210
        ..roastLevel = 3
        ..notes = '花香明显，酸度适中',
      RoastSession(
        id: '2',
        beanName: '哥伦比亚 慧兰',
        beanOrigin: '哥伦比亚',
        beanWeight: 500,
        startTime: DateTime.now().subtract(const Duration(days: 3)),
      )
        ..endTime = DateTime.now().subtract(const Duration(days: 3)).add(const Duration(minutes: 14))
        ..fcTemp = 198
        ..dropTemp = 215
        ..roastLevel = 4
        ..notes = '坚果巧克力风味',
      RoastSession(
        id: '3',
        beanName: '肯尼亚 AA',
        beanOrigin: '肯尼亚',
        beanWeight: 400,
        startTime: DateTime.now().subtract(const Duration(days: 5)),
      )
        ..endTime = DateTime.now().subtract(const Duration(days: 5)).add(const Duration(minutes: 11))
        ..fcTemp = 194
        ..dropTemp = 208
        ..roastLevel = 2
        ..notes = '黑莓酸质，口感饱满',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text('烘焙历史'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计卡片
          _buildStatsCard(),
          
          // 列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _buildSessionCard(sessions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalRoasts = sessions.length;
    final totalBeans = sessions.fold<double>(
      0, 
      (sum, s) => sum + (s.beanWeight ?? 0)
    );
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总烘焙次数', '$totalRoasts'),
          _buildStatItem('总生豆量', '${totalBeans.toStringAsFixed(0)}g'),
          _buildStatItem('平均烘焙度', '3.5'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(RoastSession session) {
    final duration = session.duration;
    final durationText = duration != null 
      ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
      : '--:--';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetail(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 烘焙度指示
              Container(
                width: 8,
                height: 60,
                decoration: BoxDecoration(
                  color: _getRoastLevelColor(session.roastLevel),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.beanName ?? '未知豆种',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.beanOrigin} • ${session.beanWeight}g',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.schedule,
                          durationText,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.thermostat,
                          '${session.dropTemp?.toStringAsFixed(0) ?? '--'}°C',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.calendar_today,
                          '${session.startTime.month}/${session.startTime.day}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 更多按钮
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showSessionOptions(session),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoastLevelColor(int? level) {
    switch (level) {
      case 1:
        return Colors.yellow[700]!;
      case 2:
        return Colors.orange[400]!;
      case 3:
        return Colors.orange[700]!;
      case 4:
        return Colors.brown[400]!;
      case 5:
        return Colors.brown[700]!;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    // TODO: 显示筛选对话框
  }

  void _exportData() {
    // TODO: 导出数据
  }

  void _showSessionDetail(RoastSession session) {
    // TODO: 显示详情
  }

  void _showSessionOptions(RoastSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.white),
              title: const Text('查看详情', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSessionDetail(session);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('分享曲线', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 分享
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除记录', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 删除
              },
            ),
          ],
        ),
      ),
    );
  }
}
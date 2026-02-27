import 'package:flutter/material.dart';

/// 事件标记按钮（FC、SC、Drop等）
class EventButtons extends StatelessWidget {
  final Function(String) onEventPressed;
  final bool disabled;

  const EventButtons({
    super.key,
    required this.onEventPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 一爆按钮
          Expanded(
            child: _buildEventButton(
              label: '一爆\nFC',
              icon: Icons.local_fire_department,
              color: Colors.yellow,
              onPressed: () => onEventPressed('fc'),
            ),
          ),
          const SizedBox(width: 12),
          
          // 二爆按钮
          Expanded(
            child: _buildEventButton(
              label: '二爆\nSC',
              icon: Icons.local_fire_department,
              color: Colors.orange,
              onPressed: () => onEventPressed('sc'),
            ),
          ),
          const SizedBox(width: 12),
          
          // 下豆按钮
          Expanded(
            child: _buildEventButton(
              label: '下豆\nDrop',
              icon: Icons.download,
              color: Colors.red,
              onPressed: () => onEventPressed('drop'),
            ),
          ),
          const SizedBox(width: 12),
          
          // 自定义按钮
          Expanded(
            child: _buildEventButton(
              label: '标记\nNote',
              icon: Icons.edit_note,
              color: Colors.blue,
              onPressed: () => _showCustomEventDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: disabled 
              ? Colors.grey[800] 
              : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: disabled 
                ? Colors.grey[700]! 
                : color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: disabled ? Colors.grey[600] : color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: disabled ? Colors.grey[600] : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomEventDialog(BuildContext context) {
    if (disabled) return;
    
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          '添加自定义标记',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入标记内容...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // TODO: 添加自定义事件
                Navigator.pop(context);
              }
            },
            child: const Text(
              '添加',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
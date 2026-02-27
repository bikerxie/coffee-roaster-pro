import 'package:flutter/material.dart';

/// 控制面板（火力、转速、风量）
class ControlPanel extends StatelessWidget {
  final double gasLevel;
  final double drumSpeed;
  final double airflow;
  
  final ValueChanged<double> onGasChanged;
  final ValueChanged<double> onDrumSpeedChanged;
  final ValueChanged<double> onAirflowChanged;

  const ControlPanel({
    super.key,
    required this.gasLevel,
    required this.drumSpeed,
    required this.airflow,
    required this.onGasChanged,
    required this.onDrumSpeedChanged,
    required this.onAirflowChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 火力控制
          Expanded(
            child: _buildControlItem(
              icon: Icons.local_fire_department,
              label: '火力',
              value: gasLevel,
              color: Colors.orange,
              onChanged: onGasChanged,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 转速控制
          Expanded(
            child: _buildControlItem(
              icon: Icons.rotate_right,
              label: '转速',
              value: drumSpeed,
              color: Colors.blue,
              onChanged: onDrumSpeedChanged,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 风量控制
          Expanded(
            child: _buildControlItem(
              icon: Icons.air,
              label: '风量',
              value: airflow,
              color: Colors.cyan,
              onChanged: onAirflowChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        // 图标和数值
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              '${value.toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        
        // 滑块
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.grey[800],
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
        
        // 快速调节按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickButton('-10', () {
              onChanged((value - 10).clamp(0, 100));
            }, color),
            _buildQuickButton('-5', () {
              onChanged((value - 5).clamp(0, 100));
            }, color),
            _buildQuickButton('+5', () {
              onChanged((value + 5).clamp(0, 100));
            }, color),
            _buildQuickButton('+10', () {
              onChanged((value + 10).clamp(0, 100));
            }, color),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
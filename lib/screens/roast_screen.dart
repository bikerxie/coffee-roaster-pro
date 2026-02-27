import 'package:flutter/material.dart';
import '../models/roast_session.dart';
import '../models/device.dart';
import '../widgets/roast_chart.dart';
import '../widgets/control_panel.dart';
import '../widgets/event_buttons.dart';

/// 主烘焙界面
class RoastScreen extends StatefulWidget {
  const RoastScreen({super.key});

  @override
  State<RoastScreen> createState() => _RoastScreenState();
}

class _RoastScreenState extends State<RoastScreen> {
  RoastSession? currentSession;
  RoasterDevice? connectedDevice;
  bool isRoasting = false;
  
  // 模拟实时数据
  List<RoastDataPoint> dataPoints = [];
  List<RoastEvent> events = [];
  
  double currentBeanTemp = 25.0;
  double currentAirTemp = 25.0;
  double currentRoor = 0.0;
  
  // 控制参数
  double gasLevel = 50.0;
  double drumSpeed = 60.0;
  double airflow = 80.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coffee Roaster Pro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (connectedDevice != null)
              Text(
                connectedDevice!.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: connectedDevice!.isConnected 
                    ? Colors.green 
                    : Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          // 连接状态指示
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: connectedDevice?.isConnected == true
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  connectedDevice?.isConnected == true
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                  size: 16,
                  color: connectedDevice?.isConnected == true
                    ? Colors.green
                    : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  connectedDevice?.isConnected == true ? '已连接' : '未连接',
                  style: TextStyle(
                    fontSize: 12,
                    color: connectedDevice?.isConnected == true
                      ? Colors.green
                      : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: 打开设置
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 温度显示卡片
          _buildTempDisplay(),
          
          // 烘焙曲线图
          Expanded(
            flex: 3,
            child: RoastChart(
              dataPoints: dataPoints,
              events: events,
            ),
          ),
          
          // 控制面板
          ControlPanel(
            gasLevel: gasLevel,
            drumSpeed: drumSpeed,
            airflow: airflow,
            onGasChanged: (value) => setState(() => gasLevel = value),
            onDrumSpeedChanged: (value) => setState(() => drumSpeed = value),
            onAirflowChanged: (value) => setState(() => airflow = value),
          ),
          
          // 事件按钮
          EventButtons(
            onEventPressed: _addEvent,
            disabled: !isRoasting,
          ),
          
          // 开始/结束烘焙按钮
          _buildActionButton(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTempDisplay() {
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
          _buildTempItem('豆温', currentBeanTemp, Colors.orange),
          _buildTempItem('风温', currentAirTemp, Colors.red),
          _buildTempItem('RoR', currentRoor, Colors.green, '°C/min'),
          _buildTimer(),
        ],
      ),
    );
  }

  Widget _buildTempItem(String label, double value, Color color, [String? unit]) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}${unit ?? '°C'}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          '时间',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isRoasting ? '02:35' : '00:00',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final bool canStart = connectedDevice?.isConnected == true && !isRoasting;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isRoasting 
              ? Colors.red 
              : (canStart ? Colors.green : Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isRoasting 
            ? _stopRoast
            : (canStart ? _startRoast : null),
          child: Text(
            isRoasting ? '结束烘焙' : '开始烘焙',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _startRoast() {
    setState(() {
      isRoasting = true;
      currentSession = RoastSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
      );
      dataPoints = [];
      events = [];
    });
    
    // 添加入豆事件
    _addEvent('charge');
    
    // TODO: 开始数据采集
  }

  void _stopRoast() {
    setState(() {
      isRoasting = false;
      currentSession?.endTime = DateTime.now();
    });
    
    // 添加下豆事件
    _addEvent('drop');
    
    // TODO: 保存会话
    _showSaveDialog();
  }

  void _addEvent(String type) {
    if (!isRoasting && type != 'charge') return;
    
    final event = RoastEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      beanTemp: currentBeanTemp,
      airTemp: currentAirTemp,
    );
    
    setState(() {
      events.add(event);
    });
    
    // 更新会话中的关键温度点
    switch (type) {
      case 'fc':
        currentSession?.fcTemp = currentBeanTemp;
        currentSession?.fcTime = DateTime.now();
        break;
      case 'sc':
        currentSession?.scTemp = currentBeanTemp;
        currentSession?.scTime = DateTime.now();
        break;
      case 'drop':
        currentSession?.dropTemp = currentBeanTemp;
        break;
    }
  }

  void _showSaveDialog() {
    // TODO: 显示保存对话框
  }
}
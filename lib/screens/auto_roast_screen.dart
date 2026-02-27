import 'package:flutter/material.dart';
import '../models/auto_roast.dart';
import '../services/hardware_service.dart';

/// 全自动烘焙界面
class AutoRoastScreen extends StatefulWidget {
  final RoasterHardware hardware;
  
  const AutoRoastScreen({
    super.key,
    required this.hardware,
  });

  @override
  State<AutoRoastScreen> createState() => _AutoRoastScreenState();
}

class _AutoRoastScreenState extends State<AutoRoastScreen> {
  final AutoRoastController _controller = AutoRoastController();
  AutoRoastProfile? _selectedProfile;
  RoastStage _currentStage = RoastStage.drying;
  bool _isRoasting = false;
  
  // 传感器数据显示
  double _beanTemp = 25.0;
  double _ror = 0.0;
  int _roastLevel = 1;
  bool _isFirstCrackDetected = false;
  bool _isSecondCrackDetected = false;
  
  @override
  void initState() {
    super.initState();
    _selectedProfile = AutoRoastProfile.mediumRoast();
    _startSensorListening();
  }
  
  void _startSensorListening() {
    // 监听温度
    widget.hardware.temperatureStream.listen((data) {
      setState(() {
        _beanTemp = data.beanTemp;
        _ror = data.roor;
      });
    });
    
    // 监听色度
    widget.hardware.colorStream.listen((color) {
      setState(() {
        _roastLevel = color.roastLevel;
      });
    });
    
    // 监听音频事件
    widget.hardware.audioStream.listen((event) {
      if (event.type == AudioEventType.firstCrack) {
        setState(() => _isFirstCrackDetected = true);
      } else if (event.type == AudioEventType.secondCrack) {
        setState(() => _isSecondCrackDetected = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text('全自动烘焙'),
        actions: [
          // 紧急停止按钮
          if (_isRoasting)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: _emergencyStop,
            ),
        ],
      ),
      body: Column(
        children: [
          // 曲线选择
          _buildProfileSelector(),
          
          // 传感器数据卡片
          _buildSensorCard(),
          
          // 烘焙阶段指示
          _buildStageIndicator(),
          
          // 自动烘焙日志
          Expanded(
            child: _buildLogPanel(),
          ),
          
          // 控制按钮
          _buildControlButton(),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildProfileSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                '烘焙曲线',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 预设曲线按钮
          Row(
            children: [
              _buildProfileButton('浅烘', AutoRoastProfile.lightRoast()),
              const SizedBox(width: 8),
              _buildProfileButton('中烘', AutoRoastProfile.mediumRoast()),
              const SizedBox(width: 8),
              _buildProfileButton('深烘', AutoRoastProfile.darkRoast()),
            ],
          ),
          
          if (_selectedProfile != null) ...[
            const SizedBox(height: 12),
            Text(
              _selectedProfile!.description ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildParamChip('目标温度', '${_selectedProfile!.targetDropTemp?.toStringAsFixed(0) ?? "--"}°C'),
                const SizedBox(width: 8),
                _buildParamChip('发展时间', '${((_selectedProfile!.developmentTime ?? 0) / 60).toStringAsFixed(1)}分钟'),
                const SizedBox(width: 8),
                _buildParamChip('目标烘焙度', '${_selectedProfile!.targetRoastLevel}级'),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildProfileButton(String label, AutoRoastProfile profile) {
    final isSelected = _selectedProfile?.name == profile.name;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isRoasting ? null : () => setState(() => _selectedProfile = profile),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildParamChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[300],
        ),
      ),
    );
  }
  
  Widget _buildSensorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSensorValue('豆温', '${_beanTemp.toStringAsFixed(1)}°C', Colors.orange),
          _buildSensorValue('RoR', '${_ror.toStringAsFixed(1)}°C/min', Colors.green),
          _buildSensorValue('烘焙度', '$_roastLevel级', _getRoastLevelColor(_roastLevel)),
        ],
      ),
    );
  }
  
  Widget _buildSensorValue(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
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
  
  Color _getRoastLevelColor(int level) {
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
  
  Widget _buildStageIndicator() {
    final stages = RoastStage.values.where((s) => 
      s != RoastStage.darkRoast && s != RoastStage.mediumDark
    ).toList();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '烘焙阶段',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: stages.map((stage) {
              final isCurrent = _currentStage == stage;
              final isPast = stages.indexOf(stage) < stages.indexOf(_currentStage);
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCurrent 
                      ? stage.color 
                      : isPast 
                        ? stage.color.withOpacity(0.5)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '当前: ${_currentStage.displayName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _currentStage.color,
                ),
              ),
              if (_isFirstCrackDetected)
                const Icon(Icons.volume_up, color: Colors.orange, size: 20),
              if (_isSecondCrackDetected)
                const Icon(Icons.volume_up, color: Colors.red, size: 20),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '自动烘焙日志',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _buildLogItem('09:49:17', '开始烘焙', Colors.green),
                _buildLogItem('09:51:23', '脱水期结束', Colors.blue),
                if (_isFirstCrackDetected)
                  _buildLogItem('10:01:45', '🎵 检测到一爆', Colors.orange),
                if (_isSecondCrackDetected)
                  _buildLogItem('10:03:12', '🎵 检测到二爆', Colors.red),
                if (_isRoasting)
                  _buildLogItem('10:01:45', '调整火力至 45%', Colors.yellow),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogItem(String time, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRoasting ? Colors.red : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isRoasting ? _stopAutoRoast : _startAutoRoast,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isRoasting ? Icons.stop : Icons.play_arrow),
              const SizedBox(width: 8),
              Text(
                _isRoasting ? '停止自动烘焙' : '开始自动烘焙',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _startAutoRoast() {
    if (_selectedProfile == null) return;
    
    setState(() {
      _isRoasting = true;
      _isFirstCrackDetected = false;
      _isSecondCrackDetected = false;
    });
    
    _controller.startAutoRoast(
      profile: _selectedProfile!,
      onCommand: (command) {
        // 执行硬件命令
        _executeCommand(command);
      },
      onStageChange: (stage) {
        setState(() => _currentStage = stage);
      },
    );
  }
  
  void _stopAutoRoast() {
    setState(() => _isRoasting = false);
    _controller.stopAutoRoast();
  }
  
  void _emergencyStop() {
    _controller.emergencyStop((command) => _executeCommand(command));
    setState(() => _isRoasting = false);
  }
  
  void _executeCommand(AutoRoastCommand command) {
    if (command is SetGasCommand) {
      widget.hardware.setGasLevel(command.level);
    } else if (command is SetDrumSpeedCommand) {
      widget.hardware.setDrumSpeed(command.speed);
    } else if (command is SetAirflowCommand) {
      widget.hardware.setAirflow(command.airflow);
    } else if (command is DropBeansCommand) {
      widget.hardware.dropBeans();
    }
  }
}
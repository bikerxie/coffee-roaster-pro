import 'dart:async';
import 'dart:typed_data';
import '../models/auto_roast.dart';
import '../models/roast_session.dart';

/// 硬件抽象接口
abstract class RoasterHardware {
  // 连接管理
  Future<bool> connect();
  Future<void> disconnect();
  bool get isConnected;
  Stream<ConnectionState> get connectionStream;
  
  // 温度传感器
  double get beanTemp;           // 豆温
  double get airTemp;            // 风温
  Stream<RoastDataPoint> get temperatureStream;
  
  // 色度传感器
  ColorReading? get colorReading;
  Stream<ColorReading> get colorStream;
  
  // 音频传感器（智能麦克风）
  List<AudioEvent> get recentAudioEvents;
  Stream<AudioEvent> get audioStream;
  
  // 执行器控制
  Future<void> setGasLevel(double level);      // 火力 0-100
  Future<void> setDrumSpeed(double speed);     // 滚筒转速 0-100
  Future<void> setAirflow(double airflow);     // 风量 0-100
  Future<void> dropBeans();                     // 下豆
  
  // 获取所有传感器数据（用于AI分析）
  SensorSnapshot get sensorSnapshot;
}

/// 连接状态
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// 传感器数据快照
class SensorSnapshot {
  final DateTime timestamp;
  final double beanTemp;
  final double airTemp;
  final double ror;
  final ColorReading? color;
  final List<AudioEvent> audioEvents;
  final double gasLevel;
  final double drumSpeed;
  final double airflow;
  
  SensorSnapshot({
    required this.timestamp,
    required this.beanTemp,
    required this.airTemp,
    required this.ror,
    this.color,
    required this.audioEvents,
    required this.gasLevel,
    required this.drumSpeed,
    required this.airflow,
  });
}

/// 智能烘焙机硬件实现
class SmartRoasterHardware implements RoasterHardware {
  // 模拟数据流控制器
  final _tempController = StreamController<RoastDataPoint>.broadcast();
  final _colorController = StreamController<ColorReading>.broadcast();
  final _audioController = StreamController<AudioEvent>.broadcast();
  final _connectionController = StreamController<ConnectionState>.broadcast();
  
  // 当前状态
  double _beanTemp = 25.0;
  double _airTemp = 25.0;
  double _ror = 0.0;
  ColorReading? _colorReading;
  List<AudioEvent> _audioEvents = [];
  
  double _gasLevel = 0;
  double _drumSpeed = 0;
  double _airflow = 0;
  
  bool _connected = false;
  Timer? _sensorTimer;
  
  // 温度历史（用于计算RoR）
  final List<Map<String, dynamic>> _tempHistory = [];
  
  @override
  Future<bool> connect() async {
    _connectionController.add(ConnectionState.connecting);
    
    // 模拟连接过程
    await Future.delayed(const Duration(seconds: 2));
    
    _connected = true;
    _connectionController.add(ConnectionState.connected);
    
    // 启动传感器数据模拟
    _startSensorSimulation();
    
    return true;
  }
  
  @override
  Future<void> disconnect() async {
    _sensorTimer?.cancel();
    _connected = false;
    _connectionController.add(ConnectionState.disconnected);
  }
  
  @override
  bool get isConnected => _connected;
  
  @override
  Stream<ConnectionState> get connectionStream => _connectionController.stream;
  
  void _startSensorSimulation() {
    // 模拟传感器数据更新（每秒）
    _sensorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_connected) return;
      
      // 模拟温度变化
      _simulateTemperature();
      
      // 模拟色度变化
      _simulateColor();
      
      // 模拟音频事件
      _simulateAudio();
    });
  }
  
  void _simulateTemperature() {
    // 根据火力计算升温
    final heatInput = _gasLevel * 0.1;  // 火力影响
    final cooling = (_beanTemp - _airTemp) * 0.02;  // 散热
    final tempRise = heatInput - cooling + (Random().nextDouble() - 0.5) * 0.5;
    
    _beanTemp += tempRise;
    _airTemp = _beanTemp + 15 + Random().nextDouble() * 5;
    
    // 计算RoR
    _tempHistory.add({
      'temp': _beanTemp,
      'time': DateTime.now(),
    });
    if (_tempHistory.length > 10) _tempHistory.removeAt(0);
    
    if (_tempHistory.length >= 2) {
      final first = _tempHistory.first;
      final last = _tempHistory.last;
      final tempDiff = last['temp'] - first['temp'];
      final timeDiff = (last['time'] as DateTime)
          .difference(first['time'] as DateTime)
          .inSeconds;
      _ror = timeDiff > 0 ? (tempDiff / timeDiff * 60) : 0;
    }
    
    // 发送数据
    final dataPoint = RoastDataPoint(
      timestamp: DateTime.now(),
      beanTemp: _beanTemp,
      airTemp: _airTemp,
      roor: _ror,
      drumSpeed: _drumSpeed,
      airflow: _airflow,
      gasLevel: _gasLevel,
    );
    
    _tempController.add(dataPoint);
  }
  
  void _simulateColor() {
    // 根据温度模拟色度变化
    // 温度越高，豆子越黑（L值越小）
    double targetL = 70;  // 生豆亮度
    
    if (_beanTemp > 150) {
      targetL = 70 - (_beanTemp - 150) * 0.4;
    }
    targetL = targetL.clamp(20, 70);
    
    // 添加一些噪声
    final actualL = targetL + (Random().nextDouble() - 0.5) * 2;
    
    _colorReading = ColorReading(
      timestamp: DateTime.now(),
      hue: 30 + Random().nextDouble() * 10,  // 褐色
      saturation: 60 + Random().nextDouble() * 10,
      lightness: actualL.clamp(20, 70),
    );
    
    _colorController.add(_colorReading!);
  }
  
  void _simulateAudio() {
    // 在一爆/二爆温度附近模拟音频事件
    if ((_beanTemp > 195 && _beanTemp < 200) ||
        (_beanTemp > 220 && _beanTemp < 225)) {
      if (Random().nextDouble() < 0.3) {  // 30%概率产生爆声
        final isFirstCrack = _beanTemp < 210;
        final event = AudioEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          type: isFirstCrack ? AudioEventType.firstCrack : AudioEventType.secondCrack,
          confidence: 0.7 + Random().nextDouble() * 0.25,
          intensity: 0.5 + Random().nextDouble() * 0.4,
          frequency: isFirstCrack ? 2000 : 3000,
        );
        
        _audioEvents.add(event);
        if (_audioEvents.length > 20) _audioEvents.removeAt(0);
        
        _audioController.add(event);
      }
    }
  }
  
  @override
  double get beanTemp => _beanTemp;
  
  @override
  double get airTemp => _airTemp;
  
  @override
  Stream<RoastDataPoint> get temperatureStream => _tempController.stream;
  
  @override
  ColorReading? get colorReading => _colorReading;
  
  @override
  Stream<ColorReading> get colorStream => _colorController.stream;
  
  @override
  List<AudioEvent> get recentAudioEvents => List.from(_audioEvents);
  
  @override
  Stream<AudioEvent> get audioStream => _audioController.stream;
  
  @override
  Future<void> setGasLevel(double level) async {
    _gasLevel = level.clamp(0, 100);
    // TODO: 通过蓝牙/WiFi发送命令到硬件
  }
  
  @override
  Future<void> setDrumSpeed(double speed) async {
    _drumSpeed = speed.clamp(0, 100);
    // TODO: 发送命令到硬件
  }
  
  @override
  Future<void> setAirflow(double airflow) async {
    _airflow = airflow.clamp(0, 100);
    // TODO: 发送命令到硬件
  }
  
  @override
  Future<void> dropBeans() async {
    // TODO: 发送下豆命令到硬件
    print('🫘 下豆命令已发送');
  }
  
  @override
  SensorSnapshot get sensorSnapshot => SensorSnapshot(
    timestamp: DateTime.now(),
    beanTemp: _beanTemp,
    airTemp: _airTemp,
    ror: _ror,
    color: _colorReading,
    audioEvents: List.from(_audioEvents),
    gasLevel: _gasLevel,
    drumSpeed: _drumSpeed,
    airflow: _airflow,
  );
  
  void dispose() {
    _sensorTimer?.cancel();
    _tempController.close();
    _colorController.close();
    _audioController.close();
    _connectionController.close();
  }
}

// 用于模拟的随机数生成器
class Random {
  static final _instance = Random._internal();
  factory Random() => _instance;
  Random._internal();
  
  double nextDouble() => DateTime.now().microsecond / 1000000;
}
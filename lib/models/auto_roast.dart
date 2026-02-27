import 'dart:async';
import 'dart:math';

/// 多传感器数据融合
class SensorFusion {
  final List<double> _tempHistory = [];
  final List<ColorReading> _colorHistory = [];
  final List<AudioEvent> _audioEvents = [];
  
  // 一爆检测阈值
  static const double FC_TEMP_THRESHOLD = 196.0;  // 典型一爆温度
  static const double FC_ROR_DROP_THRESHOLD = 5.0;  // RoR下降阈值
  
  // 二爆检测阈值
  static const double SC_TEMP_THRESHOLD = 224.0;  // 典型二爆温度
  
  /// 融合分析 - 判断当前烘焙阶段
  RoastStage analyzeStage({
    required double currentTemp,
    required double ror,
    required ColorReading? color,
    required List<AudioEvent> recentAudio,
    required Duration elapsedTime,
  }) {
    // 温度分析
    _tempHistory.add(currentTemp);
    if (_tempHistory.length > 30) _tempHistory.removeAt(0);
    
    // 1. 检查音频事件（最可靠的一爆/二爆检测）
    for (var audio in recentAudio) {
      if (audio.type == AudioEventType.firstCrack && audio.confidence > 0.7) {
        return RoastStage.firstCrack;
      }
      if (audio.type == AudioEventType.secondCrack && audio.confidence > 0.7) {
        return RoastStage.secondCrack;
      }
    }
    
    // 2. 色度分析（辅助判断）
    if (color != null) {
      _colorHistory.add(color);
      if (_colorHistory.length > 10) _colorHistory.removeAt(0);
      
      // 根据色度判断烘焙度
      if (color.lightness < 30) {
        return RoastStage.darkRoast;
      } else if (color.lightness < 45) {
        return RoastStage.mediumDark;
      }
    }
    
    // 3. 温度 + RoR 分析
    if (currentTemp >= SC_TEMP_THRESHOLD && _detectRorDrop()) {
      return RoastStage.secondCrack;
    }
    
    if (currentTemp >= FC_TEMP_THRESHOLD && _detectRorDrop()) {
      return RoastStage.firstCrack;
    }
    
    // 4. 发展阶段判断
    if (currentTemp < 150) {
      return RoastStage.drying;
    } else if (currentTemp < FC_TEMP_THRESHOLD - 10) {
      return RoastStage.mañana;
    } else {
      return RoastStage.development;
    }
  }
  
  /// 检测 RoR 下降（一爆/二爆特征）
  bool _detectRorDrop() {
    if (_tempHistory.length < 10) return false;
    
    // 计算最近10个点的RoR趋势
    final recent = _tempHistory.sublist(_tempHistory.length - 10);
    final firstHalf = recent.sublist(0, 5);
    final secondHalf = recent.sublist(5);
    
    final firstRor = _calculateRor(firstHalf);
    final secondRor = _calculateRor(secondHalf);
    
    // RoR 显著下降
    return (firstRor - secondRor) > FC_ROR_DROP_THRESHOLD;
  }
  
  double _calculateRor(List<double> temps) {
    if (temps.length < 2) return 0;
    final delta = temps.last - temps.first;
    return delta * 60 / 5;  // 每分钟升温
  }
  
  /// 预测完成时间
  Duration? predictCompletion({
    required double currentTemp,
    required double targetTemp,
    required double currentRor,
    required RoastStage currentStage,
  }) {
    if (currentRor <= 0) return null;
    
    final tempDiff = targetTemp - currentTemp;
    final minutesRemaining = tempDiff / currentRor;
    
    return Duration(minutes: minutesRemaining.ceil());
  }
}

/// 烘焙阶段
enum RoastStage {
  drying,        // 脱水期 (0-150°C)
  mañana,        // 梅纳反应期 (150-196°C)
  firstCrack,    // 一爆期
  development,   // 发展期 (一爆后)
  secondCrack,   // 二爆期
  darkRoast,     // 深烘
  mediumDark,    // 中深烘
}

extension RoastStageExtension on RoastStage {
  String get displayName {
    switch (this) {
      case RoastStage.drying:
        return '脱水期';
      case RoastStage.mañana:
        return '梅纳反应期';
      case RoastStage.firstCrack:
        return '一爆期';
      case RoastStage.development:
        return '发展期';
      case RoastStage.secondCrack:
        return '二爆期';
      case RoastStage.darkRoast:
        return '深烘阶段';
      case RoastStage.mediumDark:
        return '中深烘阶段';
    }
  }
  
  Color get color {
    switch (this) {
      case RoastStage.drying:
        return Colors.blue;
      case RoastStage.mañana:
        return Colors.yellow;
      case RoastStage.firstCrack:
        return Colors.orange;
      case RoastStage.development:
        return Colors.deepOrange;
      case RoastStage.secondCrack:
        return Colors.red;
      case RoastStage.darkRoast:
        return Colors.brown;
      case RoastStage.mediumDark:
        return Colors.orange[800]!;
    }
  }
}

/// 色度读数
class ColorReading {
  final DateTime timestamp;
  final double hue;        // 色相 (0-360)
  final double saturation; // 饱和度 (0-100)
  final double lightness;  // 亮度 (0-100，越小越黑)
  final double? agtron;    // 艾格壮数值（如果有校准）
  
  ColorReading({
    required this.timestamp,
    required this.hue,
    required this.saturation,
    required this.lightness,
    this.agtron,
  });
  
  /// 转换为烘焙度（近似）
  int get roastLevel {
    if (agtron != null) {
      // 艾格壮数值：95+ 极浅，70-95 浅烘，55-70 中烘，40-55 深烘，<40 极深
      if (agtron! > 85) return 1;
      if (agtron! > 70) return 2;
      if (agtron! > 55) return 3;
      if (agtron! > 40) return 4;
      return 5;
    }
    
    // 基于亮度估算
    if (lightness > 60) return 1;      // 极浅
    if (lightness > 50) return 2;      // 浅烘
    if (lightness > 40) return 3;      // 中烘
    if (lightness > 30) return 4;      // 中深
    return 5;                           // 深烘
  }
}

/// 音频事件
class AudioEvent {
  final String id;
  final DateTime timestamp;
  final AudioEventType type;
  final double confidence;  // 0.0 - 1.0
  final double intensity;   // 强度/音量
  final double frequency;   // 主频率
  
  AudioEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.confidence,
    required this.intensity,
    required this.frequency,
  });
}

enum AudioEventType {
  firstCrack,     // 一爆
  secondCrack,    // 二爆
  ambient,        // 环境音
  anomaly,        // 异常声音
}

/// 全自动烘焙控制器
class AutoRoastController {
  final SensorFusion _sensorFusion = SensorFusion();
  
  // 控制参数
  AutoRoastProfile? _profile;
  Timer? _controlTimer;
  
  // 状态
  bool isAutoMode = false;
  RoastStage _currentStage = RoastStage.drying;
  DateTime? _fcStartTime;
  DateTime? _scStartTime;
  
  // 目标参数
  double? _targetDropTemp;
  double? _targetDevelopmentTime;  // 发展时间（秒）
  int? _targetRoastLevel;          // 目标烘焙度
  
  /// 启动全自动烘焙
  void startAutoRoast({
    required AutoRoastProfile profile,
    required Function(AutoRoastCommand) onCommand,
    required Function(RoastStage) onStageChange,
  }) {
    _profile = profile;
    isAutoMode = true;
    
    // 解析目标
    _targetDropTemp = profile.targetDropTemp;
    _targetDevelopmentTime = profile.developmentTime;
    _targetRoastLevel = profile.targetRoastLevel;
    
    // 启动控制循环（每秒执行一次）
    _controlTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _executeControl(onCommand, onStageChange);
    });
  }
  
  /// 停止全自动烘焙
  void stopAutoRoast() {
    _controlTimer?.cancel();
    _controlTimer = null;
    isAutoMode = false;
  }
  
  /// 执行控制逻辑
  void _executeControl(
    Function(AutoRoastCommand) onCommand,
    Function(RoastStage) onStageChange,
  ) {
    // TODO: 获取实时传感器数据
    // final currentTemp = hardware.getBeanTemp();
    // final color = hardware.getColorReading();
    // final audio = hardware.getRecentAudio();
    
    // 分析当前阶段
    // final stage = _sensorFusion.analyzeStage(...);
    
    // 阶段变化回调
    // if (stage != _currentStage) {
    //   _currentStage = stage;
    //   onStageChange(stage);
    // }
    
    // 根据阶段和目标执行控制
    // _applyControlStrategy(stage, onCommand);
  }
  
  /// 应用控制策略
  void _applyControlStrategy(
    RoastStage stage,
    Function(AutoRoastCommand) onCommand,
  ) {
    if (_profile == null) return;
    
    switch (stage) {
      case RoastStage.drying:
        // 脱水期：大火力快速升温
        onCommand(AutoRoastCommand.setGas(_profile!.drying.gasLevel));
        onCommand(AutoRoastCommand.setDrumSpeed(_profile!.drying.drumSpeed));
        break;
        
      case RoastStage.mañana:
        // 梅纳期：降低火力，准备进入一爆
        onCommand(AutoRoastCommand.setGas(_profile!.mañana.gasLevel));
        break;
        
      case RoastStage.firstCrack:
        // 一爆期：记录时间，适当降火力防止爆焦
        _fcStartTime ??= DateTime.now();
        onCommand(AutoRoastCommand.setGas(_profile!.firstCrack.gasLevel));
        break;
        
      case RoastStage.development:
        // 发展期：控制发展时间
        if (_fcStartTime != null && _targetDevelopmentTime != null) {
          final devTime = DateTime.now().difference(_fcStartTime!).inSeconds;
          
          if (devTime >= _targetDevelopmentTime!) {
            // 发展时间达到，准备下豆
            onCommand(AutoRoastCommand.dropBeans());
          }
        }
        break;
        
      case RoastStage.secondCrack:
        // 二爆期：如果目标是深烘，继续；否则立即下豆
        _scStartTime ??= DateTime.now();
        if (_targetRoastLevel != null && _targetRoastLevel! < 4) {
          // 目标是浅烘/中烘，不应该到二爆
          onCommand(AutoRoastCommand.dropBeans());
        }
        break;
        
      default:
        break;
    }
  }
  
  /// 紧急停止（温度过高或其他异常）
  void emergencyStop(Function(AutoRoastCommand) onCommand) {
    onCommand(AutoRoastCommand.setGas(0));  // 关闭火力
    onCommand(AutoRoastCommand.setAirflow(100));  // 最大风量冷却
    onCommand(AutoRoastCommand.dropBeans());  // 立即下豆
    stopAutoRoast();
  }
}

/// 全自动烘焙曲线配置
class AutoRoastProfile {
  final String name;
  final String? description;
  
  // 各阶段参数
  final PhaseProfile drying;
  final PhaseProfile mañana;
  final PhaseProfile firstCrack;
  final PhaseProfile development;
  
  // 目标参数
  final double? targetDropTemp;
  final double? developmentTime;  // 发展时间（秒）
  final int? targetRoastLevel;    // 目标烘焙度
  final double? targetColorL;     // 目标色度L值
  
  AutoRoastProfile({
    required this.name,
    this.description,
    required this.drying,
    required this.mañana,
    required this.firstCrack,
    required this.development,
    this.targetDropTemp,
    this.developmentTime,
    this.targetRoastLevel,
    this.targetColorL,
  });
  
  /// 预设曲线 - 浅烘
  static AutoRoastProfile lightRoast() {
    return AutoRoastProfile(
      name: '浅烘',
      description: '突出酸质和花果香',
      drying: PhaseProfile(gasLevel: 80, drumSpeed: 60),
      mañana: PhaseProfile(gasLevel: 60, drumSpeed: 60),
      firstCrack: PhaseProfile(gasLevel: 40, drumSpeed: 65),
      development: PhaseProfile(gasLevel: 30, drumSpeed: 70),
      targetDropTemp: 200,
      developmentTime: 90,  // 1分30秒发展期
      targetRoastLevel: 2,
      targetColorL: 55,
    );
  }
  
  /// 预设曲线 - 中烘
  static AutoRoastProfile mediumRoast() {
    return AutoRoastProfile(
      name: '中烘',
      description: '酸甜平衡',
      drying: PhaseProfile(gasLevel: 85, drumSpeed: 55),
      mañana: PhaseProfile(gasLevel: 65, drumSpeed: 60),
      firstCrack: PhaseProfile(gasLevel: 50, drumSpeed: 65),
      development: PhaseProfile(gasLevel: 45, drumSpeed: 70),
      targetDropTemp: 212,
      developmentTime: 120,  // 2分钟发展期
      targetRoastLevel: 3,
      targetColorL: 45,
    );
  }
  
  /// 预设曲线 - 深烘
  static AutoRoastProfile darkRoast() {
    return AutoRoastProfile(
      name: '深烘',
      description: '醇厚苦甜',
      drying: PhaseProfile(gasLevel: 90, drumSpeed: 50),
      mañana: PhaseProfile(gasLevel: 70, drumSpeed: 55),
      firstCrack: PhaseProfile(gasLevel: 60, drumSpeed: 60),
      development: PhaseProfile(gasLevel: 55, drumSpeed: 65),
      targetDropTemp: 225,
      developmentTime: 150,  // 2分30秒发展期
      targetRoastLevel: 4,
      targetColorL: 35,
    );
  }
}

class PhaseProfile {
  final double gasLevel;     // 火力 0-100
  final double drumSpeed;    // 滚筒转速 0-100
  final double? airflow;     // 风量 0-100（可选）
  
  PhaseProfile({
    required this.gasLevel,
    required this.drumSpeed,
    this.airflow,
  });
}

/// 自动烘焙命令
abstract class AutoRoastCommand {
  const AutoRoastCommand();
  
  factory AutoRoastCommand.setGas(double level) = SetGasCommand;
  factory AutoRoastCommand.setDrumSpeed(double speed) = SetDrumSpeedCommand;
  factory AutoRoastCommand.setAirflow(double airflow) = SetAirflowCommand;
  factory AutoRoastCommand.dropBeans() = DropBeansCommand;
}

class SetGasCommand extends AutoRoastCommand {
  final double level;
  SetGasCommand(this.level);
}

class SetDrumSpeedCommand extends AutoRoastCommand {
  final double speed;
  SetDrumSpeedCommand(this.speed);
}

class SetAirflowCommand extends AutoRoastCommand {
  final double airflow;
  SetAirflowCommand(this.airflow);
}

class DropBeansCommand extends AutoRoastCommand {
  DropBeansCommand();
}
import 'dart:math';
import '../models/auto_roast.dart';
import '../models/roast_session.dart';

/// AI 烘焙预测引擎
class AIPredictionEngine {
  // 历史数据用于训练/参考
  final List<RoastSession> _historicalData = [];
  
  // 当前烘焙数据窗口
  final List<Map<String, dynamic>> _dataWindow = [];
  static const int WINDOW_SIZE = 30;  // 30秒数据窗口
  
  /// 预测完成时间
  PredictionResult predictCompletion({
    required List<RoastDataPoint> recentData,
    required double targetTemp,
    required AutoRoastProfile profile,
  }) {
    if (recentData.length < 5) {
      return PredictionResult(
        predictedTime: null,
        confidence: 0.0,
        message: '数据不足，无法预测',
      );
    }
    
    // 计算当前RoR趋势
    final rorTrend = _calculateRorTrend(recentData);
    final currentTemp = recentData.last.beanTemp;
    final tempDiff = targetTemp - currentTemp;
    
    if (rorTrend.averageRor <= 0) {
      return PredictionResult(
        predictedTime: null,
        confidence: 0.0,
        message: '升温异常，请检查火力',
      );
    }
    
    // 预测剩余时间
    final estimatedMinutes = tempDiff / rorTrend.averageRor;
    final predictedDuration = Duration(minutes: estimatedMinutes.ceil());
    
    // 计算置信度
    final confidence = _calculateConfidence(rorTrend, recentData.length);
    
    // 生成建议
    final advice = _generateAdvice(rorTrend, profile);
    
    return PredictionResult(
      predictedTime: predictedDuration,
      confidence: confidence,
      message: '预计还需 ${predictedDuration.inMinutes}分${predictedDuration.inSeconds % 60}秒',
      advice: advice,
    );
  }
  
  /// 预测一爆时间
  PredictionResult predictFirstCrack({
    required List<RoastDataPoint> recentData,
    required double currentTemp,
  }) {
    const fcTemp = 196.0;  // 典型一爆温度
    
    if (currentTemp >= fcTemp - 5) {
      return PredictionResult(
        predictedTime: Duration.zero,
        confidence: 0.9,
        message: '即将进入一爆区间',
        advice: '准备降低火力，注意听爆声',
      );
    }
    
    final rorTrend = _calculateRorTrend(recentData);
    if (rorTrend.averageRor <= 0) {
      return PredictionResult(
        predictedTime: null,
        confidence: 0.0,
        message: '无法预测',
      );
    }
    
    final tempDiff = fcTemp - currentTemp;
    final estimatedMinutes = tempDiff / rorTrend.averageRor;
    
    return PredictionResult(
      predictedTime: Duration(minutes: estimatedMinutes.ceil()),
      confidence: 0.75,
      message: '预计 ${estimatedMinutes.ceil()} 分钟后到达一爆',
      advice: '保持当前火力，准备进入梅纳反应后期',
    );
  }
  
  /// 基于色度预测最佳下豆时间
  PredictionResult predictOptimalDropTime({
    required List<ColorReading> colorHistory,
    required int targetRoastLevel,
    required List<RoastDataPoint> tempData,
  }) {
    if (colorHistory.isEmpty) {
      return PredictionResult(
        predictedTime: null,
        confidence: 0.0,
        message: '等待色度数据...',
      );
    }
    
    final currentLevel = colorHistory.last.roastLevel;
    final targetL = _roastLevelToL(targetRoastLevel);
    final currentL = colorHistory.last.lightness;
    
    if (currentLevel >= targetRoastLevel) {
      return PredictionResult(
        predictedTime: Duration.zero,
        confidence: 0.95,
        message: '已达到目标烘焙度！',
        advice: '建议立即下豆',
      );
    }
    
    // 计算色度变化速度
    final colorSpeed = _calculateColorChangeSpeed(colorHistory);
    if (colorSpeed <= 0) {
      return PredictionResult(
        predictedTime: null,
        confidence: 0.3,
        message: '色度变化缓慢',
        advice: '可适当提高火力',
      );
    }
    
    final lDiff = currentL - targetL;
    final estimatedMinutes = lDiff / colorSpeed;
    
    return PredictionResult(
      predictedTime: Duration(minutes: estimatedMinutes.ceil()),
      confidence: 0.7,
      message: '预计 ${estimatedMinutes.ceil()} 分钟后达到目标色度',
      advice: '监控色度变化，准备下豆',
    );
  }
  
  /// 多传感器融合分析
  FusionAnalysisResult fuseSensors({
    required RoastDataPoint tempData,
    required ColorReading? colorData,
    required List<AudioEvent> audioEvents,
    required Duration elapsedTime,
  }) {
    final results = <String>[];
    double confidence = 0.0;
    
    // 1. 温度分析
    if (tempData.beanTemp > 200) {
      results.add('豆子已进入深烘阶段');
      confidence += 0.3;
    } else if (tempData.beanTemp > 180) {
      results.add('豆子正在发展风味');
      confidence += 0.2;
    }
    
    // 2. 色度分析
    if (colorData != null) {
      final level = colorData.roastLevel;
      results.add('当前烘焙度: ${level}级');
      confidence += 0.3;
    }
    
    // 3. 音频分析
    for (var audio in audioEvents) {
      if (audio.confidence > 0.7) {
        switch (audio.type) {
          case AudioEventType.firstCrack:
            results.add('✓ 确认一爆');
            confidence += 0.4;
            break;
          case AudioEventType.secondCrack:
            results.add('✓ 确认二爆');
            confidence += 0.4;
            break;
          default:
            break;
        }
      }
    }
    
    // 4. RoR分析
    if (tempData.roor > 15) {
      results.add('⚠️ 升温过快');
    } else if (tempData.roor < 3) {
      results.add('⚠️ 升温过慢');
    } else {
      results.add('✓ 升温正常');
    }
    
    return FusionAnalysisResult(
      insights: results,
      overallConfidence: confidence.clamp(0.0, 1.0),
      recommendedAction: _generateRecommendation(results),
    );
  }
  
  /// 计算RoR趋势
  RorTrend _calculateRorTrend(List<RoastDataPoint> data) {
    if (data.length < 2) {
      return RorTrend(averageRor: 0, trend: 'flat');
    }
    
    final rors = data.map((d) => d.roor).toList();
    final average = rors.reduce((a, b) => a + b) / rors.length;
    
    // 判断趋势
    final firstHalf = rors.sublist(0, rors.length ~/ 2);
    final secondHalf = rors.sublist(rors.length ~/ 2);
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    String trend;
    if (secondAvg > firstAvg + 1) {
      trend = 'rising';
    } else if (secondAvg < firstAvg - 1) {
      trend = 'falling';
    } else {
      trend = 'stable';
    }
    
    return RorTrend(averageRor: average, trend: trend);
  }
  
  /// 计算置信度
  double _calculateConfidence(RorTrend trend, int dataPoints) {
    double confidence = 0.5;
    
    // 数据量影响
    if (dataPoints > 20) confidence += 0.2;
    else if (dataPoints > 10) confidence += 0.1;
    
    // RoR稳定性影响
    if (trend.trend == 'stable') confidence += 0.2;
    else if (trend.trend == 'falling') confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// 生成建议
  String? _generateAdvice(RorTrend trend, AutoRoastProfile profile) {
    if (trend.averageRor > 12) {
      return '建议降低火力，避免升温过快';
    } else if (trend.averageRor < 5) {
      return '可适当提高火力';
    } else if (trend.trend == 'falling') {
      return 'RoR正在下降，可能需要补火';
    }
    return null;
  }
  
  /// 计算色度变化速度
  double _calculateColorChangeSpeed(List<ColorReading> history) {
    if (history.length < 2) return 0;
    
    final first = history.first;
    final last = history.last;
    final timeDiff = last.timestamp.difference(first.timestamp).inMinutes;
    
    if (timeDiff == 0) return 0;
    
    final lDiff = first.lightness - last.lightness;
    return lDiff / timeDiff;  // L值每分钟变化
  }
  
  /// 烘焙度转L值
  double _roastLevelToL(int level) {
    switch (level) {
      case 1: return 65;
      case 2: return 55;
      case 3: return 45;
      case 4: return 35;
      case 5: return 25;
      default: return 45;
    }
  }
  
  String _generateRecommendation(List<String> insights) {
    if (insights.any((i) => i.contains('一爆'))) {
      return 'monitor';  // 监控模式
    }
    if (insights.any((i) => i.contains('深烘'))) {
      return 'ready';  // 准备下豆
    }
    return 'continue';  // 继续烘焙
  }
  
  /// 从历史数据学习
  void learnFromHistory(List<RoastSession> sessions) {
    _historicalData.addAll(sessions);
    // TODO: 使用机器学习模型训练
  }
}

/// 预测结果
class PredictionResult {
  final Duration? predictedTime;
  final double confidence;
  final String message;
  final String? advice;
  
  PredictionResult({
    this.predictedTime,
    required this.confidence,
    required this.message,
    this.advice,
  });
  
  bool get isReliable => confidence > 0.7;
}

/// RoR趋势
class RorTrend {
  final double averageRor;
  final String trend;  // 'rising', 'falling', 'stable'
  
  RorTrend({
    required this.averageRor,
    required this.trend,
  });
}

/// 融合分析结果
class FusionAnalysisResult {
  final List<String> insights;
  final double overallConfidence;
  final String recommendedAction;
  
  FusionAnalysisResult({
    required this.insights,
    required this.overallConfidence,
    required this.recommendedAction,
  });
}
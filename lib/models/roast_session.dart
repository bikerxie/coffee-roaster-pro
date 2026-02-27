/// 烘焙数据点
class RoastDataPoint {
  final DateTime timestamp;
  final double beanTemp;      // 豆温 (°C)
  final double airTemp;       // 风温 (°C)
  final double roor;          // 升温速率 (°C/min)
  final double? drumSpeed;    // 滚筒转速 (RPM)
  final double? airflow;      // 风量 (%)
  final double? gasLevel;     // 火力 (%)

  RoastDataPoint({
    required this.timestamp,
    required this.beanTemp,
    required this.airTemp,
    required this.roor,
    this.drumSpeed,
    this.airflow,
    this.gasLevel,
  });

  Map<String, dynamic> toJson() => {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'beanTemp': beanTemp,
      'airTemp': airTemp,
      'roor': roor,
      'drumSpeed': drumSpeed,
      'airflow': airflow,
      'gasLevel': gasLevel,
    };
  };

  factory RoastDataPoint.fromJson(Map<String, dynamic> json) {
    return RoastDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      beanTemp: json['beanTemp'].toDouble(),
      airTemp: json['airTemp'].toDouble(),
      roor: json['roor'].toDouble(),
      drumSpeed: json['drumSpeed']?.toDouble(),
      airflow: json['airflow']?.toDouble(),
      gasLevel: json['gasLevel']?.toDouble(),
    );
  }
}

/// 烘焙事件（FC、SC等）
class RoastEvent {
  final String id;
  final String type;          // 'fc', 'sc', 'drop', 'custom'
  final String? name;         // 自定义事件名称
  final DateTime timestamp;
  final double beanTemp;
  final double? airTemp;

  RoastEvent({
    required this.id,
    required this.type,
    this.name,
    required this.timestamp,
    required this.beanTemp,
    this.airTemp,
  });

  String get displayName {
    switch (type) {
      case 'fc':
        return '一爆 (FC)';
      case 'sc':
        return '二爆 (SC)';
      case 'drop':
        return '下豆 (Drop)';
      case 'charge':
        return '入豆 (Charge)';
      default:
        return name ?? '自定义';
    }
  }
}

/// 烘焙会话
class RoastSession {
  final String id;
  final String? beanName;         // 咖啡豆名称
  final String? beanOrigin;       // 产地
  final double? beanWeight;       // 生豆重量 (g)
  final DateTime startTime;
  DateTime? endTime;
  
  // 关键温度点
  double? chargeTemp;             // 入豆温度
  double? fcTemp;                 // 一爆温度
  DateTime? fcTime;
  double? scTemp;                 // 二爆温度
  DateTime? scTime;
  double? dropTemp;               // 下豆温度
  
  String? notes;
  int? roastLevel;                // 烘焙度 (1-10)
  
  List<RoastDataPoint> dataPoints = [];
  List<RoastEvent> events = [];

  RoastSession({
    required this.id,
    this.beanName,
    this.beanOrigin,
    this.beanWeight,
    required this.startTime,
  });

  Duration? get duration => 
    endTime != null ? endTime!.difference(startTime) : null;

  double? get totalWeightLoss => 
    beanWeight != null && dropWeight != null
      ? ((beanWeight! - dropWeight!) / beanWeight!) * 100
      : null;
  
  double? dropWeight;             // 熟豆重量 (g)

  Map<String, dynamic> toJson() => {
    return {
      'id': id,
      'beanName': beanName,
      'beanOrigin': beanOrigin,
      'beanWeight': beanWeight,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'chargeTemp': chargeTemp,
      'fcTemp': fcTemp,
      'fcTime': fcTime?.millisecondsSinceEpoch,
      'scTemp': scTemp,
      'scTime': scTime?.millisecondsSinceEpoch,
      'dropTemp': dropTemp,
      'dropWeight': dropWeight,
      'notes': notes,
      'roastLevel': roastLevel,
      'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
      'events': events.map((e) => {
        'id': e.id,
        'type': e.type,
        'name': e.name,
        'timestamp': e.timestamp.millisecondsSinceEpoch,
        'beanTemp': e.beanTemp,
        'airTemp': e.airTemp,
      }).toList(),
    };
  }
}

/// 烘焙曲线模板
class RoastProfile {
  final String id;
  final String name;
  final String? description;
  final List<RoastDataPoint> targetCurve;
  final double? targetFcTemp;
  final double? targetDropTemp;
  final int? targetRoastLevel;

  RoastProfile({
    required this.id,
    required this.name,
    this.description,
    required this.targetCurve,
    this.targetFcTemp,
    this.targetDropTemp,
    this.targetRoastLevel,
  });
}
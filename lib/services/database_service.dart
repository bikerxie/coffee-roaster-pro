import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';

/// 数据存储服务
/// 使用 sqflite 存储烘焙数据，支持历史记录查询和 Artisan 格式导出
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  // 数据库信息
  static const String _databaseName = 'coffee_roaster.db';
  static const int _databaseVersion = 1;

  // 表名
  static const String tableRoastSessions = 'roast_sessions';
  static const String tableTemperatureData = 'temperature_data';
  static const String tableRoastProfiles = 'roast_profiles';
  static const String tableBeans = 'beans';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw DatabaseException("数据库初始化失败: $e");
    }
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 烘焙会话表
    await db.execute('''
      CREATE TABLE $tableRoastSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bean_name TEXT NOT NULL,
        bean_origin TEXT,
        bean_weight REAL NOT NULL,
        roast_weight REAL,
        roast_level TEXT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        duration_seconds INTEGER,
        initial_temperature REAL,
        first_crack_time INTEGER,
        first_crack_temp REAL,
        second_crack_time INTEGER,
        second_crack_temp REAL,
        drop_temp REAL,
        notes TEXT,
        rating INTEGER,
        profile_id INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 温度数据表
    await db.execute('''
      CREATE TABLE $tableTemperatureData (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        elapsed_seconds INTEGER NOT NULL,
        bean_temperature REAL NOT NULL,
        environmental_temperature REAL,
        heater_power REAL,
        fan_speed REAL,
        drum_speed REAL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $tableRoastSessions(id) ON DELETE CASCADE
      )
    ''');

    // 烘焙曲线表
    await db.execute('''
      CREATE TABLE $tableRoastProfiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        bean_type TEXT,
        target_roast_level TEXT,
        target_temp_curve TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 咖啡豆表
    await db.execute('''
      CREATE TABLE $tableBeans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        origin TEXT,
        variety TEXT,
        altitude TEXT,
        process_method TEXT,
        purchase_date INTEGER,
        stock_weight REAL,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await db.execute(
      'CREATE INDEX idx_temp_session ON $tableTemperatureData(session_id)'
    );
    await db.execute(
      'CREATE INDEX idx_temp_timestamp ON $tableTemperatureData(timestamp)'
    );
    await db.execute(
      'CREATE INDEX idx_session_start_time ON $tableRoastSessions(start_time)'
    );
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级逻辑
  }

  // ==================== 烘焙会话操作 ====================

  /// 创建新烘焙会话
  Future<int> createRoastSession(RoastSession session) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final data = session.toMap();
      data['created_at'] = now;
      data['updated_at'] = now;

      return await db.insert(tableRoastSessions, data);
    } catch (e) {
      throw DatabaseException("创建烘焙会话失败: $e");
    }
  }

  /// 更新烘焙会话
  Future<int> updateRoastSession(RoastSession session) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final data = session.toMap();
      data['updated_at'] = now;

      return await db.update(
        tableRoastSessions,
        data,
        where: 'id = ?',
        whereArgs: [session.id],
      );
    } catch (e) {
      throw DatabaseException("更新烘焙会话失败: $e");
    }
  }

  /// 获取单个烘焙会话
  Future<RoastSession?> getRoastSession(int id) async {
    try {
      final db = await database;
      final results = await db.query(
        tableRoastSessions,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;
      return RoastSession.fromMap(results.first);
    } catch (e) {
      throw DatabaseException("获取烘焙会话失败: $e");
    }
  }

  /// 获取所有烘焙会话
  Future<List<RoastSession>> getAllRoastSessions({int? limit, int? offset}) async {
    try {
      final db = await database;
      final results = await db.query(
        tableRoastSessions,
        orderBy: 'start_time DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => RoastSession.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException("获取烘焙会话列表失败: $e");
    }
  }

  /// 搜索烘焙会话
  Future<List<RoastSession>> searchRoastSessions({
    String? beanName,
    String? roastLevel,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await database;
      final conditions = <String>[];
      final args = <dynamic>[];

      if (beanName != null && beanName.isNotEmpty) {
        conditions.add('bean_name LIKE ?');
        args.add('%$beanName%');
      }

      if (roastLevel != null && roastLevel.isNotEmpty) {
        conditions.add('roast_level = ?');
        args.add(roastLevel);
      }

      if (startDate != null) {
        conditions.add('start_time >= ?');
        args.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        conditions.add('start_time <= ?');
        args.add(endDate.millisecondsSinceEpoch);
      }

      final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

      final results = await db.query(
        tableRoastSessions,
        where: whereClause,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'start_time DESC',
      );

      return results.map((map) => RoastSession.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException("搜索烘焙会话失败: $e");
    }
  }

  /// 删除烘焙会话
  Future<int> deleteRoastSession(int id) async {
    try {
      final db = await database;
      return await db.delete(
        tableRoastSessions,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException("删除烘焙会话失败: $e");
    }
  }

  // ==================== 温度数据操作 ====================

  /// 保存温度数据点
  Future<int> saveTemperatureData(TemperatureDataPoint data) async {
    try {
      final db = await database;
      return await db.insert(tableTemperatureData, data.toMap());
    } catch (e) {
      throw DatabaseException("保存温度数据失败: $e");
    }
  }

  /// 批量保存温度数据
  Future<void> batchSaveTemperatureData(List<TemperatureDataPoint> dataList) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var data in dataList) {
          batch.insert(tableTemperatureData, data.toMap());
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw DatabaseException("批量保存温度数据失败: $e");
    }
  }

  /// 获取会话的温度数据
  Future<List<TemperatureDataPoint>> getTemperatureDataBySession(int sessionId) async {
    try {
      final db = await database;
      final results = await db.query(
        tableTemperatureData,
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'elapsed_seconds ASC',
      );

      return results.map((map) => TemperatureDataPoint.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException("获取温度数据失败: $e");
    }
  }

  /// 删除会话的温度数据
  Future<int> deleteTemperatureDataBySession(int sessionId) async {
    try {
      final db = await database;
      return await db.delete(
        tableTemperatureData,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    } catch (e) {
      throw DatabaseException("删除温度数据失败: $e");
    }
  }

  // ==================== Artisan 格式导出 ====================

  /// 导出为 Artisan CSV 格式
  Future<String> exportToArtisanFormat(int sessionId) async {
    try {
      final session = await getRoastSession(sessionId);
      if (session == null) {
        throw DatabaseException("烘焙会话不存在");
      }

      final tempData = await getTemperatureDataBySession(sessionId);

      // 构建 CSV 数据
      final csvData = <List<dynamic>>[];

      // Artisan 格式的头部
      csvData.add(['time', 'BT', 'ET', 'heater', 'fan', 'drum']);

      // 数据行
      for (var point in tempData) {
        csvData.add([
          point.elapsedSeconds,
          point.beanTemperature.toStringAsFixed(1),
          point.environmentalTemperature?.toStringAsFixed(1) ?? '',
          point.heaterPower?.toStringAsFixed(1) ?? '',
          point.fanSpeed?.toStringAsFixed(1) ?? '',
          point.drumSpeed?.toStringAsFixed(1) ?? '',
        ]);
      }

      // 添加元数据注释行
      csvData.add([]);
      csvData.add(['# Metadata']);
      csvData.add(['# Bean:', session.beanName]);
      csvData.add(['# Origin:', session.beanOrigin ?? '']);
      csvData.add(['# Weight In:', '${session.beanWeight}g']);
      csvData.add(['# Weight Out:', '${session.roastWeight ?? 0}g']);
      csvData.add(['# Roast Level:', session.roastLevel ?? '']);
      csvData.add(['# Date:', DateTime.fromMillisecondsSinceEpoch(session.startTime).toIso8601String()]);
      csvData.add(['# Duration:', '${session.durationSeconds ?? 0}s']);
      csvData.add(['# First Crack:', session.firstCrackTime != null ? '${session.firstCrackTime}s @ ${session.firstCrackTemp}°C' : 'N/A']);

      // 转换为 CSV 字符串
      final csv = const ListToCsvConverter().convert(csvData);

      return csv;
    } catch (e) {
      throw DatabaseException("导出 Artisan 格式失败: $e");
    }
  }

  /// 导出并保存到文件
  Future<File> exportToArtisanFile(int sessionId, {String? customPath}) async {
    try {
      final csv = await exportToArtisanFormat(sessionId);

      String filePath;
      if (customPath != null) {
        filePath = customPath;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final session = await getRoastSession(sessionId);
        final fileName = 'roast_${sessionId}_${session?.beanName.replaceAll(' ', '_') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.csv';
        filePath = join(directory.path, fileName);
      }

      final file = File(filePath);
      await file.writeAsString(csv);

      return file;
    } catch (e) {
      throw DatabaseException("导出文件失败: $e");
    }
  }

  /// 导出为 JSON 格式
  Future<Map<String, dynamic>> exportToJson(int sessionId) async {
    try {
      final session = await getRoastSession(sessionId);
      if (session == null) {
        throw DatabaseException("烘焙会话不存在");
      }

      final tempData = await getTemperatureDataBySession(sessionId);

      return {
        'session': session.toMap(),
        'temperatureData': tempData.map((d) => d.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw DatabaseException("导出 JSON 失败: $e");
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// 烘焙会话模型
class RoastSession {
  final int? id;
  final String beanName;
  final String? beanOrigin;
  final double beanWeight;
  final double? roastWeight;
  final String? roastLevel;
  final int startTime;
  final int? endTime;
  final int? durationSeconds;
  final double? initialTemperature;
  final int? firstCrackTime;
  final double? firstCrackTemp;
  final int? secondCrackTime;
  final double? secondCrackTemp;
  final double? dropTemp;
  final String? notes;
  final int? rating;
  final int? profileId;

  RoastSession({
    this.id,
    required this.beanName,
    this.beanOrigin,
    required this.beanWeight,
    this.roastWeight,
    this.roastLevel,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.initialTemperature,
    this.firstCrackTime,
    this.firstCrackTemp,
    this.secondCrackTime,
    this.secondCrackTemp,
    this.dropTemp,
    this.notes,
    this.rating,
    this.profileId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bean_name': beanName,
      'bean_origin': beanOrigin,
      'bean_weight': beanWeight,
      'roast_weight': roastWeight,
      'roast_level': roastLevel,
      'start_time': startTime,
      'end_time': endTime,
      'duration_seconds': durationSeconds,
      'initial_temperature': initialTemperature,
      'first_crack_time': firstCrackTime,
      'first_crack_temp': firstCrackTemp,
      'second_crack_time': secondCrackTime,
      'second_crack_temp': secondCrackTemp,
      'drop_temp': dropTemp,
      'notes': notes,
      'rating': rating,
      'profile_id': profileId,
    };
  }

  factory RoastSession.fromMap(Map<String, dynamic> map) {
    return RoastSession(
      id: map['id'] as int?,
      beanName: map['bean_name'] as String,
      beanOrigin: map['bean_origin'] as String?,
      beanWeight: map['bean_weight'] as double,
      roastWeight: map['roast_weight'] as double?,
      roastLevel: map['roast_level'] as String?,
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      initialTemperature: map['initial_temperature'] as double?,
      firstCrackTime: map['first_crack_time'] as int?,
      firstCrackTemp: map['first_crack_temp'] as double?,
      secondCrackTime: map['second_crack_time'] as int?,
      secondCrackTemp: map['second_crack_temp'] as double?,
      dropTemp: map['drop_temp'] as double?,
      notes: map['notes'] as String?,
      rating: map['rating'] as int?,
      profileId: map['profile_id'] as int?,
    );
  }

  RoastSession copyWith({
    int? id,
    String? beanName,
    String? beanOrigin,
    double? beanWeight,
    double? roastWeight,
    String? roastLevel,
    int? startTime,
    int? endTime,
    int? durationSeconds,
    double? initialTemperature,
    int? firstCrackTime,
    double? firstCrackTemp,
    int? secondCrackTime,
    double? secondCrackTemp,
    double? dropTemp,
    String? notes,
    int? rating,
    int? profileId,
  }) {
    return RoastSession(
      id: id ?? this.id,
      beanName: beanName ?? this.beanName,
      beanOrigin: beanOrigin ?? this.beanOrigin,
      beanWeight: beanWeight ?? this.beanWeight,
      roastWeight: roastWeight ?? this.roastWeight,
      roastLevel: roastLevel ?? this.roastLevel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      initialTemperature: initialTemperature ?? this.initialTemperature,
      firstCrackTime: firstCrackTime ?? this.firstCrackTime,
      firstCrackTemp: firstCrackTemp ?? this.firstCrackTemp,
      secondCrackTime: secondCrackTime ?? this.secondCrackTime,
      secondCrackTemp: secondCrackTemp ?? this.secondCrackTemp,
      dropTemp: dropTemp ?? this.dropTemp,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
      profileId: profileId ?? this.profileId,
    );
  }
}

/// 温度数据点模型
class TemperatureDataPoint {
  final int? id;
  final int sessionId;
  final int elapsedSeconds;
  final double beanTemperature;
  final double? environmentalTemperature;
  final double? heaterPower;
  final double? fanSpeed;
  final double? drumSpeed;
  final int timestamp;

  TemperatureDataPoint({
    this.id,
    required this.sessionId,
    required this.elapsedSeconds,
    required this.beanTemperature,
    this.environmentalTemperature,
    this.heaterPower,
    this.fanSpeed,
    this.drumSpeed,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'elapsed_seconds': elapsedSeconds,
      'bean_temperature': beanTemperature,
      'environmental_temperature': environmentalTemperature,
      'heater_power': heaterPower,
      'fan_speed': fanSpeed,
      'drum_speed': drumSpeed,
      'timestamp': timestamp,
    };
  }

  factory TemperatureDataPoint.fromMap(Map<String, dynamic> map) {
    return TemperatureDataPoint(
      id: map['id'] as int?,
      sessionId: map['session_id'] as int,
      elapsedSeconds: map['elapsed_seconds'] as int,
      beanTemperature: map['bean_temperature'] as double,
      environmentalTemperature: map['environmental_temperature'] as double?,
      heaterPower: map['heater_power'] as double?,
      fanSpeed: map['fan_speed'] as double?,
      drumSpeed: map['drum_speed'] as double?,
      timestamp: map['timestamp'] as int,
    );
  }
}

/// 数据库异常
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => "DatabaseException: $message";
}
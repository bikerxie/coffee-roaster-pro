import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod/riverpod.dart';

import '../services/bluetooth_service.dart';
import '../services/database_service.dart';

// ==================== 状态类定义 ====================

/// 应用整体状态
@immutable
class RoastAppState {
  final BluetoothAdapterState bluetoothState;
  final BluetoothConnectionState connectionState;
  final RoastSessionState? currentSession;
  final List<TemperatureData> temperatureHistory;
  final List<ScanResult> scanResults;
  final bool isScanning;
  final BluetoothDevice? connectedDevice;
  final DeviceState? deviceState;
  final String? errorMessage;

  const RoastAppState({
    this.bluetoothState = BluetoothAdapterState.unknown,
    this.connectionState = BluetoothConnectionState.disconnected,
    this.currentSession,
    this.temperatureHistory = const [],
    this.scanResults = const [],
    this.isScanning = false,
    this.connectedDevice,
    this.deviceState,
    this.errorMessage,
  });

  RoastAppState copyWith({
    BluetoothAdapterState? bluetoothState,
    BluetoothConnectionState? connectionState,
    RoastSessionState? currentSession,
    List<TemperatureData>? temperatureHistory,
    List<ScanResult>? scanResults,
    bool? isScanning,
    BluetoothDevice? connectedDevice,
    DeviceState? deviceState,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoastAppState(
      bluetoothState: bluetoothState ?? this.bluetoothState,
      connectionState: connectionState ?? this.connectionState,
      currentSession: currentSession ?? this.currentSession,
      temperatureHistory: temperatureHistory ?? this.temperatureHistory,
      scanResults: scanResults ?? this.scanResults,
      isScanning: isScanning ?? this.isScanning,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      deviceState: deviceState ?? this.deviceState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 烘焙会话状态
@immutable
class RoastSessionState {
  final int? sessionId;
  final String beanName;
  final double beanWeight;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;
  final bool isRoasting;
  final bool isPaused;
  final int? firstCrackTime;
  final double? firstCrackTemp;
  final int? secondCrackTime;
  final double? secondCrackTemp;
  final String? notes;
  final double? targetHeaterPower;
  final double? targetFanSpeed;
  final double? targetDrumSpeed;

  const RoastSessionState({
    this.sessionId,
    this.beanName = '',
    this.beanWeight = 0,
    this.startTime,
    this.endTime,
    this.duration,
    this.isRoasting = false,
    this.isPaused = false,
    this.firstCrackTime,
    this.firstCrackTemp,
    this.secondCrackTime,
    this.secondCrackTemp,
    this.notes,
    this.targetHeaterPower,
    this.targetFanSpeed,
    this.targetDrumSpeed,
  });

  RoastSessionState copyWith({
    int? sessionId,
    String? beanName,
    double? beanWeight,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    bool? isRoasting,
    bool? isPaused,
    int? firstCrackTime,
    double? firstCrackTemp,
    int? secondCrackTime,
    double? secondCrackTemp,
    String? notes,
    double? targetHeaterPower,
    double? targetFanSpeed,
    double? targetDrumSpeed,
  }) {
    return RoastSessionState(
      sessionId: sessionId ?? this.sessionId,
      beanName: beanName ?? this.beanName,
      beanWeight: beanWeight ?? this.beanWeight,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isRoasting: isRoasting ?? this.isRoasting,
      isPaused: isPaused ?? this.isPaused,
      firstCrackTime: firstCrackTime ?? this.firstCrackTime,
      firstCrackTemp: firstCrackTemp ?? this.firstCrackTemp,
      secondCrackTime: secondCrackTime ?? this.secondCrackTime,
      secondCrackTemp: secondCrackTemp ?? this.secondCrackTemp,
      notes: notes ?? this.notes,
      targetHeaterPower: targetHeaterPower ?? this.targetHeaterPower,
      targetFanSpeed: targetFanSpeed ?? this.targetFanSpeed,
      targetDrumSpeed: targetDrumSpeed ?? this.targetDrumSpeed,
    );
  }
}

// ==================== Provider 定义 ====================

/// 蓝牙服务 Provider
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 数据库服务 Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = DatabaseService();
  ref.onDispose(() => service.close());
  return service;
});

/// 应用状态 StateNotifier Provider
final roastAppStateProvider = StateNotifierProvider<RoastAppStateNotifier, RoastAppState>((ref) {
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  final databaseService = ref.watch(databaseServiceProvider);
  return RoastAppStateNotifier(bluetoothService, databaseService);
});

/// 温度数据 Stream Provider
final temperatureStreamProvider = StreamProvider<TemperatureData>((ref) {
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  return bluetoothService.temperatureStream;
});

/// 蓝牙扫描结果 Stream Provider
final bluetoothScanProvider = StreamProvider<List<ScanResult>>((ref) {
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  return bluetoothService.scanResults;
});

/// 蓝牙连接状态 Stream Provider
final bluetoothConnectionProvider = StreamProvider<BluetoothConnectionState>((ref) {
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  return bluetoothService.connectionState;
});

/// 设备状态 Stream Provider
final deviceStateProvider = StreamProvider<DeviceState>((ref) {
  final bluetoothService = ref.watch(bluetoothServiceProvider);
  return bluetoothService.deviceStateStream;
});

/// 历史会话列表 Future Provider
final roastHistoryProvider = FutureProvider.family<List<RoastSession>, int>((ref, limit) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllRoastSessions(limit: limit);
});

/// 单个会话详情 Future Provider
final roastSessionDetailProvider = FutureProvider.family<RoastSession?, int>((ref, sessionId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getRoastSession(sessionId);
});

/// 会话温度数据 Future Provider
final sessionTemperatureDataProvider = FutureProvider.family<List<TemperatureDataPoint>, int>((ref, sessionId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getTemperatureDataBySession(sessionId);
});

// ==================== StateNotifier 实现 ====================

/// 应用状态管理器
class RoastAppStateNotifier extends StateNotifier<RoastAppState> {
  final BluetoothService _bluetoothService;
  final DatabaseService _databaseService;

  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _temperatureSubscription;
  StreamSubscription? _deviceStateSubscription;

  // 批量保存温度数据的缓冲区
  final List<TemperatureDataPoint> _tempBuffer = [];
  static const int _bufferSize = 10;
  Timer? _flushTimer;

  RoastAppStateNotifier(this._bluetoothService, this._databaseService)
      : super(const RoastAppState()) {
    _init();
  }

  void _init() {
    // 监听蓝牙适配器状态
    _bluetoothStateSubscription = _bluetoothService.bluetoothState.listen((btState) {
      state = state.copyWith(bluetoothState: btState);
    });

    // 监听连接状态
    _connectionSubscription = _bluetoothService.connectionState.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });

    // 监听温度数据
    _temperatureSubscription = _bluetoothService.temperatureStream.listen(
      _onTemperatureData,
      onError: (error) {
        state = state.copyWith(errorMessage: "温度数据接收错误: $error");
      },
    );

    // 监听设备状态
    _deviceStateSubscription = _bluetoothService.deviceStateStream.listen((deviceState) {
      state = state.copyWith(deviceState: deviceState);
    });

    // 启动定时刷新缓冲区
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) => _flushTempBuffer());
  }

  /// 初始化蓝牙
  Future<void> initializeBluetooth() async {
    try {
      await _bluetoothService.initialize();
    } on BluetoothException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// 开始扫描设备
  Future<void> startScan({Duration? timeout}) async {
    try {
      state = state.copyWith(isScanning: true, scanResults: [], clearError: true);
      await _bluetoothService.startScan(timeout: timeout);
    } on BluetoothException catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.message,
      );
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
    state = state.copyWith(isScanning: false);
  }

  /// 连接设备
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      state = state.copyWith(clearError: true);
      await _bluetoothService.connectToDevice(device);
      state = state.copyWith(connectedDevice: device);
    } on BluetoothException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  /// 断开设备
  Future<void> disconnectDevice() async {
    await _bluetoothService.disconnect();
    state = state.copyWith(connectedDevice: null);
  }

  /// 处理温度数据
  void _onTemperatureData(TemperatureData data) {
    // 更新历史记录
    final updatedHistory = List<TemperatureData>.from(state.temperatureHistory);
    updatedHistory.add(data);

    // 限制历史记录长度
    if (updatedHistory.length > 1000) {
      updatedHistory.removeAt(0);
    }

    state = state.copyWith(temperatureHistory: updatedHistory);

    // 如果有活跃会话，缓存数据
    if (state.currentSession?.isRoasting == true &&
        state.currentSession?.isPaused == false) {
      _cacheTemperatureData(data);
    }
  }

  /// 缓存温度数据
  void _cacheTemperatureData(TemperatureData data) {
    if (state.currentSession?.sessionId == null) return;

    final session = state.currentSession!;
    final elapsed = DateTime.now().difference(session.startTime!).inSeconds;

    final dataPoint = TemperatureDataPoint(
      sessionId: session.sessionId!,
      elapsedSeconds: elapsed,
      beanTemperature: data.beanTemperature,
      environmentalTemperature: data.environmentalTemperature,
      heaterPower: state.deviceState?.heaterPower,
      fanSpeed: state.deviceState?.fanSpeed,
      drumSpeed: state.deviceState?.drumSpeed,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _tempBuffer.add(dataPoint);

    // 缓冲区满时刷新
    if (_tempBuffer.length >= _bufferSize) {
      _flushTempBuffer();
    }
  }

  /// 刷新温度数据缓冲区到数据库
  Future<void> _flushTempBuffer() async {
    if (_tempBuffer.isEmpty) return;

    try {
      final dataToSave = List<TemperatureDataPoint>.from(_tempBuffer);
      _tempBuffer.clear();
      await _databaseService.batchSaveTemperatureData(dataToSave);
    } catch (e) {
      // 保存失败，将数据放回缓冲区
      _tempBuffer.insertAll(0, _tempBuffer);
    }
  }

  /// 开始新烘焙会话
  Future<void> startRoasting({
    required String beanName,
    required double beanWeight,
    String? notes,
  }) async {
    try {
      // 发送开始命令到设备
      await _bluetoothService.sendCommand(ControlCommand.start());

      // 创建数据库会话记录
      final now = DateTime.now();
      final session = RoastSession(
        beanName: beanName,
        beanWeight: beanWeight,
        startTime: now.millisecondsSinceEpoch,
        notes: notes,
      );

      final sessionId = await _databaseService.createRoastSession(session);

      // 更新状态
      final sessionState = RoastSessionState(
        sessionId: sessionId,
        beanName: beanName,
        beanWeight: beanWeight,
        startTime: now,
        isRoasting: true,
        isPaused: false,
        notes: notes,
      );

      state = state.copyWith(
        currentSession: sessionState,
        temperatureHistory: [],
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "开始烘焙失败: $e");
    }
  }

  /// 停止烘焙会话
  Future<void> stopRoasting() async {
    try {
      if (state.currentSession == null) return;

      // 发送停止命令
      await _bluetoothService.sendCommand(ControlCommand.stop());

      // 刷新剩余数据
      await _flushTempBuffer();

      // 更新会话记录
      final now = DateTime.now();
      final session = state.currentSession!;
      final duration = now.difference(session.startTime!);

      final updatedSession = session.copyWith(
        endTime: now,
        duration: duration,
        isRoasting: false,
      );

      // 更新数据库
      await _databaseService.updateRoastSession(
        RoastSession(
          id: session.sessionId,
          beanName: session.beanName,
          beanWeight: session.beanWeight,
          startTime: session.startTime!.millisecondsSinceEpoch,
          endTime: now.millisecondsSinceEpoch,
          durationSeconds: duration.inSeconds,
          notes: session.notes,
        ),
      );

      state = state.copyWith(
        currentSession: updatedSession,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "停止烘焙失败: $e");
    }
  }

  /// 暂停烘焙
  Future<void> pauseRoasting() async {
    try {
      await _bluetoothService.sendCommand(ControlCommand.pause());
      state = state.copyWith(
        currentSession: state.currentSession?.copyWith(isPaused: true),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "暂停失败: $e");
    }
  }

  /// 继续烘焙
  Future<void> resumeRoasting() async {
    try {
      await _bluetoothService.sendCommand(ControlCommand.resume());
      state = state.copyWith(
        currentSession: state.currentSession?.copyWith(isPaused: false),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "继续失败: $e");
    }
  }

  /// 紧急停止
  Future<void> emergencyStop() async {
    try {
      await _bluetoothService.sendCommand(ControlCommand.emergency());
      await stopRoasting();
    } catch (e) {
      state = state.copyWith(errorMessage: "紧急停止失败: $e");
    }
  }

  /// 设置加热功率
  Future<void> setHeaterPower(double power) async {
    try {
      await _bluetoothService.sendCommand(ControlCommand.setHeater(power));
      state = state.copyWith(
        currentSession: state.currentSession?.copyWith(targetHeaterPower: power),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "设置加热功率失败: $e");
    }
  }

  /// 设置风扇速度
  Future<void> setFanSpeed(double speed) async {
    try {
      await _bluetoothService.sendCommand(ControlCommand.setFan(speed));
      state = state.copyWith(
        currentSession: state.currentSession?.copyWith(targetFanSpeed: speed),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "设置风扇速度失败: $e");
    }
  }

  /// 设置滚筒速度
  Future<void> setDrumSpeed(double speed) async {
    try {
      await _bluetoothService.sendCommand(ControlCommand.setDrum(speed));
      state = state.copyWith(
        currentSession: state.currentSession?.copyWith(targetDrumSpeed: speed),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "设置滚筒速度失败: $e");
    }
  }

  /// 标记一爆
  Future<void> markFirstCrack(double temperature) async {
    if (state.currentSession?.startTime == null) return;

    final elapsed = DateTime.now().difference(state.currentSession!.startTime!).inSeconds;
    state = state.copyWith(
      currentSession: state.currentSession?.copyWith(
        firstCrackTime: elapsed,
        firstCrackTemp: temperature,
      ),
    );
  }

  /// 标记二爆
  Future<void> markSecondCrack(double temperature) async {
    if (state.currentSession?.startTime == null) return;

    final elapsed = DateTime.now().difference(state.currentSession!.startTime!).inSeconds;
    state = state.copyWith(
      currentSession: state.currentSession?.copyWith(
        secondCrackTime: elapsed,
        secondCrackTemp: temperature,
      ),
    );
  }

  /// 清除错误消息
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// 导出当前会话为 Artisan 格式
  Future<String?> exportCurrentSession() async {
    try {
      if (state.currentSession?.sessionId == null) return null;
      return await _databaseService.exportToArtisanFormat(
        state.currentSession!.sessionId!,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: "导出失败: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _bluetoothStateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _temperatureSubscription?.cancel();
    _deviceStateSubscription?.cancel();
    super.dispose();
  }
}
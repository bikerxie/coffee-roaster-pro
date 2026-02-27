import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 蓝牙设备服务
/// 负责扫描、连接蓝牙 LE 设备，接收温度数据，发送控制命令
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // 蓝牙状态流
  final _bluetoothStateController = StreamController<BluetoothAdapterState>.broadcast();
  Stream<BluetoothAdapterState> get bluetoothState => _bluetoothStateController.stream;

  // 扫描到的设备流
  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  // 连接状态流
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  // 温度数据流 (摄氏度)
  final _temperatureController = StreamController<TemperatureData>.broadcast();
  Stream<TemperatureData> get temperatureStream => _temperatureController.stream;

  // 蓝牙设备状态回调
  final _deviceStateController = StreamController<DeviceState>.broadcast();
  Stream<DeviceState> get deviceStateStream => _deviceStateController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _temperatureCharacteristic;
  BluetoothCharacteristic? _controlCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _temperatureSubscription;

  // 服务 UUID (根据实际设备修改)
  static const String serviceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String temperatureCharUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";
  static const String controlCharUuid = "0000ffe2-0000-1000-8000-00805f9b34fb";

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// 初始化蓝牙
  Future<void> initialize() async {
    try {
      // 检查蓝牙是否可用
      if (await FlutterBluePlus.isSupported == false) {
        throw BluetoothException("设备不支持蓝牙");
      }

      // 监听蓝牙适配器状态
      FlutterBluePlus.adapterState.listen((state) {
        _bluetoothStateController.add(state);
      });

      // 尝试开启蓝牙
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      throw BluetoothException("蓝牙初始化失败: $e");
    }
  }

  /// 开始扫描蓝牙设备
  Future<void> startScan({Duration? timeout}) async {
    try {
      if (_isScanning) {
        await stopScan();
      }

      // 检查蓝牙权限和状态
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw BluetoothException("蓝牙未开启");
      }

      _isScanning = true;

      // 清空之前的扫描结果
      final List<ScanResult> results = [];

      _scanSubscription = FlutterBluePlus.scanResults.listen((scanResults) {
        for (var result in scanResults) {
          // 只显示有名称的设备，或 RSSI 较强的设备
          if (result.device.platformName.isNotEmpty || result.rssi > -70) {
            if (!results.any((r) => r.device.remoteId == result.device.remoteId)) {
              results.add(result);
            }
          }
        }
        _scanResultsController.add(List.from(results));
      });

      await FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      // 扫描结束后
      await Future.delayed(timeout ?? const Duration(seconds: 15));
      await stopScan();

    } catch (e) {
      _isScanning = false;
      throw BluetoothException("扫描失败: $e");
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    } catch (e) {
      // 忽略停止扫描时的错误
    }
  }

  /// 连接到设备
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // 断开之前的连接
      await disconnect();

      // 设置连接超时
      await device.connect(
        autoConnect: false,
        mtu: null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw BluetoothException("连接超时");
        },
      );

      _connectedDevice = device;

      // 监听连接状态
      _connectionSubscription = device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
      });

      // 发现服务
      await _discoverServices(device);

    } catch (e) {
      throw BluetoothException("连接失败: $e");
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      await _cleanupConnection();
    } catch (e) {
      throw BluetoothException("断开连接失败: $e");
    }
  }

  /// 清理连接资源
  Future<void> _cleanupConnection() async {
    await _temperatureSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _temperatureSubscription = null;
    _connectionSubscription = null;
    _temperatureCharacteristic = null;
    _controlCharacteristic = null;
    _connectedDevice = null;
  }

  /// 发现服务和特征
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            final uuid = characteristic.uuid.toString().toLowerCase();

            if (uuid == temperatureCharUuid.toLowerCase()) {
              _temperatureCharacteristic = characteristic;
              await _setupTemperatureNotifications(characteristic);
            } else if (uuid == controlCharUuid.toLowerCase()) {
              _controlCharacteristic = characteristic;
            }
          }
        }
      }

      if (_temperatureCharacteristic == null) {
        throw BluetoothException("未找到温度特征值");
      }

    } catch (e) {
      throw BluetoothException("发现服务失败: $e");
    }
  }

  /// 设置温度通知
  Future<void> _setupTemperatureNotifications(BluetoothCharacteristic characteristic) async {
    try {
      // 启用通知
      await characteristic.setNotifyValue(true);

      _temperatureSubscription = characteristic.onValueReceived.listen((data) {
        _parseTemperatureData(data);
      });
    } catch (e) {
      throw BluetoothException("设置温度通知失败: $e");
    }
  }

  /// 解析温度数据
  /// 数据格式: 假设设备发送 JSON 如 {"bt": 185.5, "et": 192.3, "status": "roasting"}
  /// 或二进制格式: [0x01, bt_high, bt_low, et_high, et_low, status]
  void _parseTemperatureData(List<int> data) {
    try {
      // 尝试解析 JSON
      final String jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr);

      final temperatureData = TemperatureData(
        beanTemperature: (json['bt'] ?? json['beanTemp'] ?? 0).toDouble(),
        environmentalTemperature: (json['et'] ?? json['envTemp'] ?? 0).toDouble(),
        status: json['status'] ?? 'unknown',
        timestamp: DateTime.now(),
      );

      _temperatureController.add(temperatureData);

      // 解析设备状态
      if (json['heater'] != null || json['fan'] != null || json['drum'] != null) {
        final deviceState = DeviceState(
          heaterPower: (json['heater'] ?? 0).toDouble(),
          fanSpeed: (json['fan'] ?? 0).toDouble(),
          drumSpeed: (json['drum'] ?? 0).toDouble(),
          isRoasting: json['status'] == 'roasting',
        );
        _deviceStateController.add(deviceState);
      }

    } catch (e) {
      // 尝试二进制解析
      if (data.length >= 5) {
        _parseBinaryTemperatureData(data);
      }
    }
  }

  /// 解析二进制温度数据
  void _parseBinaryTemperatureData(List<int> data) {
    try {
      final byteData = Uint8List.fromList(data).buffer.asByteData();

      // 假设格式: [cmd, bt_high, bt_low, et_high, et_low, ...]
      final beanTemp = byteData.getInt16(1, Endian.big) / 10.0;
      final envTemp = data.length >= 5 ? byteData.getInt16(3, Endian.big) / 10.0 : 0.0;

      final temperatureData = TemperatureData(
        beanTemperature: beanTemp,
        environmentalTemperature: envTemp,
        status: 'roasting',
        timestamp: DateTime.now(),
      );

      _temperatureController.add(temperatureData);
    } catch (e) {
      // 解析失败，忽略
    }
  }

  /// 发送控制命令
  Future<void> sendCommand(ControlCommand command) async {
    try {
      if (_controlCharacteristic == null) {
        throw BluetoothException("控制特征值未初始化");
      }

      if (_connectedDevice == null) {
        throw BluetoothException("设备未连接");
      }

      // 构建命令数据
      final data = _buildCommandData(command);

      // 写入特征值
      await _controlCharacteristic!.write(
        data,
        withoutResponse: false,
      );

    } catch (e) {
      throw BluetoothException("发送命令失败: $e");
    }
  }

  /// 构建命令数据
  List<int> _buildCommandData(ControlCommand command) {
    // JSON 格式
    final Map<String, dynamic> cmdMap = {
      'cmd': command.type.name,
      if (command.heaterPower != null) 'heater': command.heaterPower,
      if (command.fanSpeed != null) 'fan': command.fanSpeed,
      if (command.drumSpeed != null) 'drum': command.drumSpeed,
      if (command.targetTemp != null) 'target': command.targetTemp,
    };

    return utf8.encode(jsonEncode(cmdMap));
  }

  /// 获取已连接设备
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 释放资源
  void dispose() {
    stopScan();
    disconnect();
    _bluetoothStateController.close();
    _scanResultsController.close();
    _connectionStateController.close();
    _temperatureController.close();
    _deviceStateController.close();
  }
}

/// 温度数据结构
class TemperatureData {
  final double beanTemperature;      // 豆温 (°C)
  final double environmentalTemperature; // 环境温度/出风温度 (°C)
  final String status;               // 设备状态
  final DateTime timestamp;          // 时间戳

  TemperatureData({
    required this.beanTemperature,
    required this.environmentalTemperature,
    required this.status,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'TemperatureData(bt: $beanTemperature°C, et: $environmentalTemperature°C, status: $status)';
  }
}

/// 设备状态
class DeviceState {
  final double heaterPower;  // 加热功率 (0-100%)
  final double fanSpeed;     // 风扇速度 (0-100%)
  final double drumSpeed;    // 滚筒速度 (0-100%)
  final bool isRoasting;     // 是否正在烘焙

  DeviceState({
    required this.heaterPower,
    required this.fanSpeed,
    required this.drumSpeed,
    required this.isRoasting,
  });

  @override
  String toString() {
    return 'DeviceState(heater: $heaterPower%, fan: $fanSpeed%, drum: $drumSpeed%, roasting: $isRoasting)';
  }
}

/// 控制命令类型
enum CommandType {
  start,      // 开始烘焙
  stop,       // 停止烘焙
  pause,      // 暂停
  resume,     // 继续
  setHeater,  // 设置加热功率
  setFan,     // 设置风扇速度
  setDrum,    // 设置滚筒速度
  emergency,  // 紧急停止
}

/// 控制命令
class ControlCommand {
  final CommandType type;
  final double? heaterPower;
  final double? fanSpeed;
  final double? drumSpeed;
  final double? targetTemp;

  ControlCommand({
    required this.type,
    this.heaterPower,
    this.fanSpeed,
    this.drumSpeed,
    this.targetTemp,
  });

  // 便捷构造方法
  factory ControlCommand.start() => ControlCommand(type: CommandType.start);
  factory ControlCommand.stop() => ControlCommand(type: CommandType.stop);
  factory ControlCommand.pause() => ControlCommand(type: CommandType.pause);
  factory ControlCommand.resume() => ControlCommand(type: CommandType.resume);
  factory ControlCommand.emergency() => ControlCommand(type: CommandType.emergency);

  factory ControlCommand.setHeater(double power) => ControlCommand(
    type: CommandType.setHeater,
    heaterPower: power.clamp(0, 100),
  );

  factory ControlCommand.setFan(double speed) => ControlCommand(
    type: CommandType.setFan,
    fanSpeed: speed.clamp(0, 100),
  );

  factory ControlCommand.setDrum(double speed) => ControlCommand(
    type: CommandType.setDrum,
    drumSpeed: speed.clamp(0, 100),
  );
}

/// 蓝牙异常
class BluetoothException implements Exception {
  final String message;
  BluetoothException(this.message);

  @override
  String toString() => "BluetoothException: $message";
}